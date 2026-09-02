import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var isPlayerExpanded: Bool = false
    @ObservedObject var playerManager = AudioPlayerManager.shared
    
    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.68, green: 0.22, blue: 0.98), Color(red: 0.98, green: 0.18, blue: 0.52)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.05, green: 0.04, blue: 0.09).ignoresSafeArea()
            
            // Tab Views
            Group {
                if selectedTab == 0 {
                    DownloaderView()
                } else if selectedTab == 1 {
                    LibraryView()
                } else {
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating Overlay (MiniPlayer + Custom Glass Navigation Bar)
            VStack(spacing: 8) {
                // Mini Player Floating Card
                if playerManager.currentTrack != nil {
                    MiniPlayerView(isExpanded: $isPlayerExpanded)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Custom Modern Floating Glass TabBar (3 Tabs)
                HStack(spacing: 0) {
                    // Tab 1: Downloader
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 0
                        }
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                if selectedTab == 0 {
                                    Capsule()
                                        .fill(primaryGradient)
                                        .frame(width: 42, height: 26)
                                        .shadow(color: Color.purple.opacity(0.5), radius: 8, x: 0, y: 3)
                                }
                                Image(systemName: selectedTab == 0 ? "arrow.down.to.line.circle.fill" : "arrow.down.circle")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(selectedTab == 0 ? .white : Color.white.opacity(0.5))
                            }
                            Text("Tải Nhạc")
                                .font(.system(size: 10, weight: selectedTab == 0 ? .bold : .medium))
                                .foregroundColor(selectedTab == 0 ? .white : Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Tab 2: Library
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 1
                        }
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                if selectedTab == 1 {
                                    Capsule()
                                        .fill(primaryGradient)
                                        .frame(width: 42, height: 26)
                                        .shadow(color: Color.purple.opacity(0.5), radius: 8, x: 0, y: 3)
                                }
                                Image(systemName: selectedTab == 1 ? "music.note.house.fill" : "music.note.house")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(selectedTab == 1 ? .white : Color.white.opacity(0.5))
                            }
                            Text("Thư Viện")
                                .font(.system(size: 10, weight: selectedTab == 1 ? .bold : .medium))
                                .foregroundColor(selectedTab == 1 ? .white : Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Tab 3: Settings & Features
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = 2
                        }
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                if selectedTab == 2 {
                                    Capsule()
                                        .fill(primaryGradient)
                                        .frame(width: 42, height: 26)
                                        .shadow(color: Color.purple.opacity(0.5), radius: 8, x: 0, y: 3)
                                }
                                Image(systemName: selectedTab == 2 ? "slider.horizontal.3" : "gearshape")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(selectedTab == 2 ? .white : Color.white.opacity(0.5))
                            }
                            Text("Cài Đặt")
                                .font(.system(size: 10, weight: selectedTab == 2 ? .bold : .medium))
                                .foregroundColor(selectedTab == 2 ? .white : Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 10)
                .background(
                    Color(red: 0.10, green: 0.08, blue: 0.16)
                        .opacity(0.95)
                )
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $isPlayerExpanded) {
            AudioPlayerView()
        }
    }
}
