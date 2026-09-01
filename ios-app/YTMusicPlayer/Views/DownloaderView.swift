import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct DownloaderView: View {
    @State private var youtubeURL: String = ""
    @State private var selectedMediaType: MediaType = .audio
    @State private var selectedQuality: String = "720p"
    @State private var showServerSettings: Bool = false
    @State private var isGlowing: Bool = false
    
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var apiClient = APIClient.shared
    
    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.68, green: 0.22, blue: 0.98), Color(red: 0.98, green: 0.18, blue: 0.52)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        ZStack {
            // Full Screen Obsidian Background
            Color(red: 0.05, green: 0.04, blue: 0.09).ignoresSafeArea()
            
            // Ambient Neon Blur Glows
            VStack {
                HStack {
                    Circle()
                        .fill(Color(red: 0.68, green: 0.22, blue: 0.98).opacity(0.22))
                        .frame(width: 280, height: 280)
                        .blur(radius: 80)
                        .offset(x: -80, y: -60)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color(red: 0.98, green: 0.18, blue: 0.52).opacity(0.22))
                        .frame(width: 300, height: 300)
                        .blur(radius: 90)
                        .offset(x: 80, y: 80)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header Bar
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(primaryGradient)
                                .frame(width: 38, height: 38)
                                .shadow(color: Color.purple.opacity(0.5), radius: 8, x: 0, y: 3)
                            Image(systemName: "music.note")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("YT MUSIC PRO")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(1.0)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Online 24/7 Cloud")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.green.opacity(0.9))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { showServerSettings = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 40, height: 40)
                                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Hero Text
                        VStack(spacing: 6) {
                            Text("Tải Nhạc & Video Tốc Độ Cao")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Tự động bóc tách MP3 320kbps & MP4 Full HD")
                                .font(.system(size: 13))
                                .foregroundColor(Color.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                        
                        // URL Input Glass Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LIÊN KẾT YOUTUBE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.purple.opacity(0.9))
                                .tracking(1.2)
                                .padding(.leading, 4)
                            
                            HStack(spacing: 10) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.98))
                                
                                #if os(iOS)
                                TextField("Dán đường dẫn YouTube tại đây...", text: $youtubeURL)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)
                                    .accentColor(.purple)
                                #else
                                TextField("Dán đường dẫn YouTube tại đây...", text: $youtubeURL)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)
                                    .accentColor(.purple)
                                #endif
                                
                                if !youtubeURL.isEmpty {
                                    Button(action: { youtubeURL = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Button(action: pasteFromClipboard) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.clipboard.fill")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("Dán")
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(primaryGradient)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.purple.opacity(0.4), radius: 6, x: 0, y: 3)
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Media Format Pills Selection
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ĐỊNH DẠNG XUẤT FILE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.purple.opacity(0.9))
                                .tracking(1.2)
                                .padding(.leading, 4)
                            
                            HStack(spacing: 12) {
                                // MP3 Audio Pill
                                Button(action: { selectedMediaType = .audio }) {
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedMediaType == .audio ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "music.note")
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("MP3 Âm thanh")
                                                .font(.system(size: 14, weight: .bold))
                                            Text("HQ 320kbps")
                                                .font(.system(size: 10))
                                                .opacity(0.8)
                                        }
                                        Spacer()
                                    }
                                    .padding(.leading, 8)
                                    .padding(.trailing, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedMediaType == .audio
                                        ? AnyView(primaryGradient)
                                        : AnyView(Color.white.opacity(0.05))
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(selectedMediaType == .audio ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                
                                // MP4 Video Pill
                                Button(action: { selectedMediaType = .video }) {
                                    HStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedMediaType == .video ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "film.fill")
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("MP4 Video")
                                                .font(.system(size: 14, weight: .bold))
                                            Text("Hình ảnh HD")
                                                .font(.system(size: 10))
                                                .opacity(0.8)
                                        }
                                        Spacer()
                                    }
                                    .padding(.leading, 8)
                                    .padding(.trailing, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedMediaType == .video
                                        ? AnyView(primaryGradient)
                                        : AnyView(Color.white.opacity(0.05))
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(selectedMediaType == .video ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                            
                            if selectedMediaType == .video {
                                HStack {
                                    Text("Chất lượng Video HD:")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.7))
                                    Spacer()
                                    Picker("Chất lượng", selection: $selectedQuality) {
                                        Text("360p Tiết kiệm").tag("360p")
                                        Text("720p HD Chuẩn").tag("720p")
                                        Text("1080p Full HD").tag("1080p")
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(.purple)
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Download Action Button
                        Button(action: startDownload) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 22))
                                Text("Bắt đầu Tải về Tức thì")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                youtubeURL.isEmpty
                                ? LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                                : primaryGradient
                            )
                            .foregroundColor(youtubeURL.isEmpty ? Color.white.opacity(0.4) : .white)
                            .cornerRadius(20)
                            .shadow(color: youtubeURL.isEmpty ? Color.clear : Color.purple.opacity(0.5), radius: 12, x: 0, y: 6)
                        }
                        .disabled(youtubeURL.isEmpty)
                        .padding(.horizontal, 20)
                        
                        // Live Progress State Cards
                        if case .downloading(let progress) = downloadManager.state {
                            VStack(spacing: 14) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.title3)
                                        .foregroundColor(.purple)
                                    Text("Đang tải dữ liệu...")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(progress * 100))%")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.98))
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 8)
                                        
                                        Capsule()
                                            .fill(primaryGradient)
                                            .frame(width: max(geometry.size.width * CGFloat(progress), 12), height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding(18)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.purple.opacity(0.4), lineWidth: 1))
                            .padding(.horizontal, 20)
                        } else if case .failed(let error) = downloadManager.state {
                            VStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.red)
                                Text("Lỗi Tải Xuống")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(18)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            .padding(.horizontal, 20)
                        } else if case .completed(let item) = downloadManager.state {
                            VStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.green)
                                Text("Tải về Thành công!")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.green)
                                Text(item.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .padding(18)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green.opacity(0.3), lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 160)
                }
            }
            .sheet(isPresented: $showServerSettings) {
                ServerSettingsView()
            }
        }
    }
    
    private func pasteFromClipboard() {
        #if canImport(UIKit)
        if let clipboardString = UIPasteboard.general.string {
            youtubeURL = clipboardString
        }
        #elseif canImport(AppKit)
        if let clipboardString = NSPasteboard.general.string(forType: .string) {
            youtubeURL = clipboardString
        }
        #endif
    }
    
    private func startDownload() {
        guard !youtubeURL.isEmpty else { return }
        downloadManager.startDownload(youtubeURL: youtubeURL, mediaType: selectedMediaType, quality: selectedQuality)
    }
}
