import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var isPlayerExpanded: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DownloaderView()
                    .tabItem {
                        Image(systemName: "arrow.down.circle")
                        Text("Tải về")
                    }
                    .tag(0)
                
                LibraryView()
                    .tabItem {
                        Image(systemName: "folder")
                        Text("Thư viện")
                    }
                    .tag(1)
            }
            .accentColor(.purple)
            
            // Mini Player Floating Overlay
            VStack {
                Spacer()
                MiniPlayerView(isExpanded: $isPlayerExpanded)
                    .padding(.bottom, 54) // Align above TabBar
            }
        }
        .sheet(isPresented: $isPlayerExpanded) {
            AudioPlayerView()
        }
    }
}
