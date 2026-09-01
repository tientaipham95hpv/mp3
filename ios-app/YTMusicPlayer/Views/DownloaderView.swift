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
    
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var apiClient = APIClient.shared
    
    private var cardBackgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color.gray.opacity(0.15)
        #endif
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Banner
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                        Text("Tải Nhạc & Video YouTube")
                            .font(.title2.bold())
                        Text("Nhập link YouTube để tải MP3 âm thanh hoặc MP4 video xem offline")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 12)
                    
                    // URL Input Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Liên kết YouTube")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.gray)
                            
                            #if os(iOS)
                            TextField("Dán đường dẫn YouTube tại đây...", text: $youtubeURL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            #else
                            TextField("Dán đường dẫn YouTube tại đây...", text: $youtubeURL)
                                .disableAutocorrection(true)
                            #endif
                            
                            if !youtubeURL.isEmpty {
                                Button(action: { youtubeURL = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: pasteFromClipboard) {
                                Text("Dán")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.15))
                                    .foregroundColor(.purple)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(12)
                        .background(cardBackgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Options Selection Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Định dạng & Chất lượng")
                            .font(.headline)
                        
                        // Media Type Picker (MP3 vs MP4)
                        Picker("Định dạng", selection: $selectedMediaType) {
                            Text("🎵 MP3 (Chỉ âm thanh)").tag(MediaType.audio)
                            Text("🎬 MP4 (Video)").tag(MediaType.video)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if selectedMediaType == .video {
                            HStack {
                                Text("Chất lượng Video:")
                                    .font(.subheadline)
                                Spacer()
                                Picker("Chất lượng", selection: $selectedQuality) {
                                    Text("720p (HD)").tag("720p")
                                    Text("1080p (Full HD)").tag("1080p")
                                    Text("360p (Tiết kiệm)").tag("360p")
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Download Button
                    Button(action: startDownload) {
                        HStack {
                            Image(systemName: selectedMediaType == .audio ? "music.note" : "video.fill")
                            Text(downloadButtonTitle)
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(youtubeURL.isEmpty ? Color.gray.opacity(0.4) : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: youtubeURL.isEmpty ? .clear : Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(youtubeURL.isEmpty)
                    .padding(.horizontal)
                    
                    // Download Progress / Status Card
                    statusCardView
                        .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Tải về")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showServerSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showServerSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            #endif
            .sheet(isPresented: $showServerSettings) {
                ServerSettingsView()
            }
        }
    }
    
    private var downloadButtonTitle: String {
        switch downloadManager.state {
        case .fetchingInfo, .downloading:
            return "Đang xử lý..."
        default:
            return selectedMediaType == .audio ? "Tải File MP3" : "Tải Video MP4"
        }
    }
    
    @ViewBuilder
    private var statusCardView: some View {
        switch downloadManager.state {
        case .idle:
            EmptyView()
        case .fetchingInfo:
            HStack(spacing: 12) {
                ProgressView()
                Text("Đang kết nối & phân tích link YouTube...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(cardBackgroundColor)
            .cornerRadius(12)
            
        case .downloading(let progress):
            VStack(spacing: 10) {
                HStack {
                    Text("Đang tải file...")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundColor(.purple)
                }
                ProgressView(value: progress)
                    .accentColor(.purple)
            }
            .padding()
            .background(cardBackgroundColor)
            .cornerRadius(12)
            
        case .completed(let item):
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tải thành công!")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text(item.title)
                        .font(.caption)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
        case .failed(let message):
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lỗi tải xuống")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
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

struct ServerSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var apiClient = APIClient.shared
    @State private var serverAddress: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Địa chỉ Backend Server"), footer: Text("Dùng localhost nếu chạy iOS Simulator. Nếu test trên iPhone thật, nhập IP máy tính của bạn (VD: http://192.168.1.10:8000)")) {
                    #if os(iOS)
                    TextField("http://localhost:8000", text: $serverAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    #else
                    TextField("http://localhost:8000", text: $serverAddress)
                        .disableAutocorrection(true)
                    #endif
                }
            }
            .navigationTitle("Cấu hình Backend")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        if !serverAddress.isEmpty {
                            apiClient.baseURL = serverAddress
                        }
                        dismiss()
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        if !serverAddress.isEmpty {
                            apiClient.baseURL = serverAddress
                        }
                        dismiss()
                    }
                }
            }
            #endif
            .onAppear {
                serverAddress = apiClient.baseURL
            }
        }
    }
}
