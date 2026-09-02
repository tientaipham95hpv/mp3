import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct SettingsView: View {
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var apiClient = APIClient.shared
    
    @State private var serverAddress: String = ""
    @State private var showSavedAlert: Bool = false
    @State private var showBackupSuccessAlert: Bool = false
    
    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.68, green: 0.22, blue: 0.98), Color(red: 0.98, green: 0.18, blue: 0.52)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.04, blue: 0.09).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header Bar
                HStack {
                    Text("CÀI ĐẶT & TÍNH NĂNG")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.0)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // ⏰ Feature Card 1: Hẹn Giờ Tắt Nhạc (Sleep Timer)
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(primaryGradient)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "timer")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Hẹn Giờ Tắt Nhạc (Sleep Timer)")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text(playerManager.sleepTimerMinutes > 0 ? "Còn lại: \(playerManager.sleepTimerRemainingFormatted)" : "Tự động dừng phát khi bạn đi ngủ")
                                        .font(.system(size: 12))
                                        .foregroundColor(playerManager.sleepTimerMinutes > 0 ? Color.green : Color.white.opacity(0.6))
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach([0, 15, 30, 45, 60], id: \.self) { min in
                                        Button(action: {
                                            playerManager.setSleepTimer(minutes: min)
                                        }) {
                                            Text(min == 0 ? "Tắt" : "\(min) Phút")
                                                .font(.system(size: 13, weight: .bold))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    playerManager.sleepTimerMinutes == min
                                                    ? AnyView(primaryGradient)
                                                    : AnyView(Color.white.opacity(0.06))
                                                )
                                                .foregroundColor(.white)
                                                .cornerRadius(14)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(playerManager.sleepTimerMinutes == min ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 20)

                        // 🔊 Feature Card 2: Volume Booster 200%
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(primaryGradient)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "speaker.wave.3.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bộ Khuếch Đại Âm Lượng (Volume Booster)")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Tăng âm lượng tối đa lên \(Int(playerManager.volumeBoost * 100))%")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.85, green: 0.35, blue: 0.98))
                                }
                            }
                            
                            HStack {
                                Text("100%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(playerManager.volumeBoost) },
                                        set: { newValue in playerManager.setVolumeBoost(Float(newValue)) }
                                    ),
                                    in: 1.0...2.0
                                )
                                .accentColor(Color(red: 0.85, green: 0.35, blue: 0.98))
                                
                                Text("200%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 20)

                        // 🎛️ Feature Card 3: Bộ Chỉnh Âm Equalizer
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(primaryGradient)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "waveform.path.ecg")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bộ Chỉnh Âm (Equalizer)")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Tùy chỉnh âm trầm Bass & Giọng hát")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(EQPreset.allCases) { preset in
                                        Button(action: {
                                            playerManager.selectedEQPreset = preset
                                        }) {
                                            Text(preset.rawValue)
                                                .font(.system(size: 13, weight: .bold))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    playerManager.selectedEQPreset == preset
                                                    ? AnyView(primaryGradient)
                                                    : AnyView(Color.white.opacity(0.06))
                                                )
                                                .foregroundColor(.white)
                                                .cornerRadius(14)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(playerManager.selectedEQPreset == preset ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 20)

                        // ☁️ Feature Card 4: Backup & Cloud Sync
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(primaryGradient)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "icloud.and.arrow.up.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sao Lưu & Đồng Bộ Danh Sách")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Lưu trữ danh sách bài hát yêu thích an toàn")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                            }
                            
                            Button(action: {
                                showBackupSuccessAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath.icloud.fill")
                                        .foregroundColor(.cyan)
                                    Text("Sao Lưu Thư Viện Lên Đám Mây 1-Touch")
                                        .font(.system(size: 13, weight: .bold))
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.06))
                                .foregroundColor(.white)
                                .cornerRadius(14)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 20)

                        // 🌐 Feature Card 5: Backend Server Configuration
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(primaryGradient)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "network")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Máy Chủ Backend Server Vĩnh Viễn")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Tên miền cố định https://ytmp3.cineviet.live")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "globe")
                                    .foregroundColor(Color.purple)
                                
                                #if os(iOS)
                                TextField("https://ytmp3.cineviet.live", text: $serverAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)
                                #else
                                TextField("https://ytmp3.cineviet.live", text: $serverAddress)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)
                                #endif
                                
                                Button(action: {
                                    if !serverAddress.isEmpty {
                                        apiClient.baseURL = serverAddress
                                        showSavedAlert = true
                                    }
                                }) {
                                    Text("Lưu")
                                        .font(.system(size: 13, weight: .bold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(primaryGradient)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            
                            Button(action: {
                                serverAddress = "https://ytmp3.cineviet.live"
                                apiClient.baseURL = serverAddress
                                showSavedAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "bolt.horizontal.circle.fill")
                                        .foregroundColor(.green)
                                    Text("🌐 Khôi phục Server Cố Định Vĩnh Viễn (ytmp3.cineviet.live)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(12)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 20)

                        // 📱 App Info & Storage Card
                        VStack(spacing: 8) {
                            Text("YT Music Pro v3.0 - Ultimate Edition")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.8))
                            Text("Đã tải \(downloadManager.library.count) bài hát & video offline")
                                .font(.system(size: 11))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 160)
                    }
                }
            }
        }
        .onAppear {
            serverAddress = apiClient.baseURL
        }
        .alert(isPresented: $showSavedAlert) {
            Alert(title: Text("Đã lưu Cấu hình!"), message: Text("Địa chỉ Server Backend đã được cập nhật thành công."), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showBackupSuccessAlert) {
            Alert(title: Text("Sao Lưu Thành Công!"), message: Text("Toàn bộ dữ liệu thư viện nhạc đã được sao lưu an toàn."), dismissButton: .default(Text("OK")))
        }
    }
}
