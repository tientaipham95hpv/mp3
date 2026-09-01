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
    @State private var isAnimatingIcon: Bool = false
    
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var apiClient = APIClient.shared
    
    private var darkBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.05, blue: 0.12),
                Color(red: 0.02, green: 0.02, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.65, green: 0.25, blue: 0.98), Color(red: 0.95, green: 0.20, blue: 0.55)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                darkBackgroundGradient.ignoresSafeArea()
                
                // Ambient Glow Orbs
                VStack {
                    HStack {
                        Circle()
                            .fill(Color.purple.opacity(0.25))
                            .frame(width: 250, height: 250)
                            .blur(radius: 70)
                            .offset(x: -80, y: -60)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.indigo.opacity(0.25))
                            .frame(width: 280, height: 280)
                            .blur(radius: 80)
                            .offset(x: 80, y: 80)
                    }
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Hero Header Banner
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(primaryGradient)
                                    .frame(width: 84, height: 84)
                                    .shadow(color: Color(red: 0.65, green: 0.25, blue: 0.98).opacity(0.5), radius: 20, x: 0, y: 10)
                                    .scaleEffect(isAnimatingIcon ? 1.05 : 0.95)
                                    .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimatingIcon)
                                
                                Image(systemName: "arrow.down.to.line.circle.fill")
                                    .font(.system(size: 44, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 16)
                            .onAppear { isAnimatingIcon = true }
                            
                            VStack(spacing: 6) {
                                Text("Tải Nhạc & Video YouTube")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Máy chủ 24/7 Cloud Sẵn sàng")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color.green.opacity(0.9))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(20)
                            }
                        }
                        
                        // Input Card Container
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Dán liên kết YouTube")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.8))
                                .padding(.leading, 4)
                            
                            HStack(spacing: 10) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(red: 0.75, green: 0.35, blue: 0.98))
                                
                                #if os(iOS)
                                TextField("Dán link YouTube tại đây...", text: $youtubeURL)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)
                                    .accentColor(.purple)
                                #else
                                TextField("Dán link YouTube tại đây...", text: $youtubeURL)
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
                                            .font(.caption)
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
                            .padding(14)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Media Type & Quality Selector
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Định dạng xuất file")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.8))
                                .padding(.leading, 4)
                            
                            HStack(spacing: 12) {
                                // MP3 Pill
                                Button(action: { selectedMediaType = .audio }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 18, weight: .semibold))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("MP3 Âm thanh")
                                                .font(.system(size: 14, weight: .bold))
                                            Text("Chất lượng cao 320kbps")
                                                .font(.system(size: 10))
                                                .opacity(0.8)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        selectedMediaType == .audio
                                        ? AnyView(primaryGradient)
                                        : AnyView(Color.white.opacity(0.06))
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedMediaType == .audio ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                
                                // MP4 Pill
                                Button(action: { selectedMediaType = .video }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "film.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("MP4 Video")
                                                .font(.system(size: 14, weight: .bold))
                                            Text("Hình ảnh HD Offline")
                                                .font(.system(size: 10))
                                                .opacity(0.8)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        selectedMediaType == .video
                                        ? AnyView(primaryGradient)
                                        : AnyView(Color.white.opacity(0.06))
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
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
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
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
                                ? LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                                : primaryGradient
                            )
                            .foregroundColor(.white)
                            .cornerRadius(18)
                            .shadow(color: youtubeURL.isEmpty ? Color.clear : Color.purple.opacity(0.5), radius: 12, x: 0, y: 6)
                        }
                        .disabled(youtubeURL.isEmpty)
                        .padding(.horizontal)
                        
                        // Downloading Progress Card
                        if case .downloading(let progress) = downloadManager.state {
                            VStack(spacing: 14) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.title3)
                                        .foregroundColor(.purple)
                                    Text("Đang bóc tách & tải dữ liệu...")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(progress * 100))%")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(red: 0.75, green: 0.35, blue: 0.98))
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
                            .padding(.horizontal)
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
                            .padding(.horizontal)
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
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Khám Phá & Tải Nhạc")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showServerSettings = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showServerSettings = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
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
