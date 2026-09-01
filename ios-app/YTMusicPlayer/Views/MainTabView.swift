import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var isPlayerExpanded: Bool = false
    
    init() {
        // Dark Glassmorphism TabBar Styling
        #if canImport(UIKit)
        let appearance = UITabBarAppearance()
        appearance.configureWithDarkBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.95)
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        #endif
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DownloaderView()
                    .tabItem {
                        Image(systemName: "arrow.down.to.line.compact")
                        Text("Tải về")
                    }
                    .tag(0)
                
                LibraryView()
                    .tabItem {
                        Image(systemName: "music.note.house.fill")
                        Text("Thư viện")
                    }
                    .tag(1)
            }
            .accentColor(Color(red: 0.75, green: 0.35, blue: 0.98))
            
            // Floating Glass Mini Player Overlay
            VStack {
                Spacer()
                MiniPlayerView(isExpanded: $isPlayerExpanded)
                    .padding(.bottom, 58)
            }
        }
        .sheet(isPresented: $isPlayerExpanded) {
            AudioPlayerView()
        }
    }
}
