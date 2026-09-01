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
                                    .foregroundColor(.gray)
                                Spacer()
                                Picker("Chất lượng", selection: $selectedQuality) {
                                    Text("360p").tag("360p")
                                    Text("720p HD").tag("720p")
                                    Text("1080p Full HD").tag("1080p")
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .background(cardBackgroundColor)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Download Action Button
                    Button(action: startDownload) {
                        HStack {
                            Image(systemName: "arrow.down.to.line.compact")
                            Text("Bắt đầu Tải về")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(youtubeURL.isEmpty ? Color.gray.opacity(0.5) : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(youtubeURL.isEmpty)
                    .padding(.horizontal)
                    
                    // Status & Progress Card
                    if case .downloading(let progress) = downloadManager.state {
                        VStack(spacing: 12) {
                            Text("Đang tải dữ liệu...")
                                .font(.headline)
                            ProgressView(value: progress)
                                .accentColor(.purple)
                            Text("\(Int(progress * 100))%")
                                .font(.caption.bold())
                                .foregroundColor(.purple)
                        }
                        .padding(16)
                        .background(cardBackgroundColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else if case .failed(let error) = downloadManager.state {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Lỗi Tải Xuống")
                                .font(.headline).foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else if case .completed(let item) = downloadManager.state {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Tải về Thành công!")
                                .font(.headline).foregroundColor(.green)
                            Text(item.title)
                                .font(.caption.bold())
                                .lineLimit(1)
                        }
                        .padding(16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Tải Nhạc")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showServerSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.purple)
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showServerSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.purple)
                    }
                }
            }
            #endif
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

struct ServerSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var apiClient = APIClient.shared
    @State private var serverAddress: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Địa chỉ Backend Server hiện tại")) {
                    #if os(iOS)
                    TextField("https://upgrade-patches-spiritual-editing.trycloudflare.com", text: $serverAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    #else
                    TextField("https://upgrade-patches-spiritual-editing.trycloudflare.com", text: $serverAddress)
                        .disableAutocorrection(true)
                    #endif
                }
                
                Section(header: Text("Chọn nhanh Server 24/7 Cloud (Bấm 1-Click)")) {
                    Button(action: {
                        serverAddress = "https://upgrade-patches-spiritual-editing.trycloudflare.com"
                    }) {
                        HStack {
                            Image(systemName: "bolt.horizontal.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("🌐 Server 24/7 Cloud (Khuyên dùng)")
                                    .font(.subheadline.bold())
                                Text("https://upgrade-patches-spiritual-editing.trycloudflare.com")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
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
