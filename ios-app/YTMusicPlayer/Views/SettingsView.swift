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

                        // 🎛️ Feature Card 2: Bộ Chỉnh Âm Equalizer
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

                        // 🌐 Feature Card 3: Backend Server Configuration
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
                                    Text("Máy Chủ Backend Server")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Cấu hình kết nối 24/7 Cloud hoặc IP cá nhân")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "globe")
                                    .foregroundColor(Color.purple)
                                
                                #if os(iOS)
                                TextField("https://...", text: $serverAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)
                                #else
                                TextField("https://...", text: $serverAddress)
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
                                serverAddress = "https://males-enhancement-revenue-teens.trycloudflare.com"
                                apiClient.baseURL = serverAddress
                                showSavedAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "bolt.horizontal.circle.fill")
                                        .foregroundColor(.green)
                                    Text("🌐 Khôi phục Server Cloud 24/7 Mặc định")
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
                            Text("YT Music Pro v2.0 - Premium Edition")
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
    }
}
