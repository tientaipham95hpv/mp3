import Foundation
import AVFoundation
import MediaPlayer
import Combine

public enum EQPreset: String, CaseIterable, Identifiable {
    case off = "Tắt EQ"
    case bassBoost = "Tăng Bass"
    case vocalBoost = "Tăng Giọng Hát"
    case pop = "Nhạc Pop"
    case rock = "Nhạc Rock"
    case chill = "Nhạc Chill / Đêm"
    
    public var id: String { rawValue }
}

public class AudioPlayerManager: ObservableObject {
    public static let shared = AudioPlayerManager()
    
    @Published public var currentTrack: MediaItem?
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: Double = 0.0
    @Published public var duration: Double = 0.0
    @Published public var playlist: [MediaItem] = []
    
    @Published public var isShuffleEnabled: Bool = false
    @Published public var isRepeatEnabled: Bool = false
    @Published public var selectedEQPreset: EQPreset = .off
    
    @Published public var sleepTimerMinutes: Int = 0
    @Published public var sleepTimerRemainingFormatted: String = ""
    private var sleepTimer: Timer?
    private var sleepTimerTargetDate: Date?
    
    public var progress: Double {
        guard duration > 0 else { return 0.0 }
        return min(max(currentTime / duration, 0.0), 1.0)
    }
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    
    public init() {
        setupAudioSession()
        setupRemoteCommandCenter()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up AVAudioSession for background audio: \(error)")
        }
        #endif
    }
    
    public func playTrack(_ item: MediaItem, inPlaylist: [MediaItem] = []) {
        guard let url = item.localURL else { return }
        
        self.currentTrack = item
        if !inPlaylist.isEmpty {
            self.playlist = inPlaylist
        } else if !playlist.contains(where: { $0.id == item.id }) {
            self.playlist.append(item)
        }
        
        removeTimeObserver()
        let playerItem = AVPlayerItem(url: url)
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        player?.play()
        self.isPlaying = true
        self.duration = item.duration
        
        addTimeObserver()
        updateNowPlayingInfo()
    }
    
    public func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updateNowPlayingInfo()
    }
    
    public func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        self.currentTime = time
        updateNowPlayingInfo()
    }
    
    public func playNext() {
        guard let current = currentTrack, !playlist.isEmpty else { return }
        
        if isRepeatEnabled {
            seek(to: 0)
            player?.play()
            isPlaying = true
            return
        }
        
        if isShuffleEnabled {
            let randomIndex = Int.random(in: 0..<playlist.count)
            playTrack(playlist[randomIndex])
            return
        }
        
        if let currentIndex = playlist.firstIndex(where: { $0.id == current.id }),
           currentIndex + 1 < playlist.count {
            playTrack(playlist[currentIndex + 1])
        } else {
            // Loop back to start
            if let first = playlist.first {
                playTrack(first)
            }
        }
    }
    
    public func playPrevious() {
        guard let current = currentTrack, !playlist.isEmpty else { return }
        if let currentIndex = playlist.firstIndex(where: { $0.id == current.id }),
           currentIndex - 1 >= 0 {
            playTrack(playlist[currentIndex - 1])
        }
    }
    
    // MARK: - Sleep Timer Feature
    public func setSleepTimer(minutes: Int) {
        self.sleepTimerMinutes = minutes
        sleepTimer?.invalidate()
        
        if minutes == 0 {
            sleepTimerRemainingFormatted = ""
            sleepTimerTargetDate = nil
            return
        }
        
        let target = Date().addingTimeInterval(TimeInterval(minutes * 60))
        self.sleepTimerTargetDate = target
        
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let targetDate = self.sleepTimerTargetDate else { return }
            let remaining = targetDate.timeIntervalSinceNow
            
            if remaining <= 0 {
                self.player?.pause()
                self.isPlaying = false
                self.setSleepTimer(minutes: 0)
            } else {
                let mins = Int(remaining) / 60
                let secs = Int(remaining) % 60
                self.sleepTimerRemainingFormatted = String(format: "%02d:%02d", mins, secs)
            }
        }
    }
    
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            
            // Auto play next if track ended
            if let duration = self.player?.currentItem?.duration.seconds,
               time.seconds >= duration - 0.5 && duration > 0 {
                self.playNext()
            }
        }
    }
    
    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    // MARK: - Lock Screen & Control Center Integration
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: event.positionTime)
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
