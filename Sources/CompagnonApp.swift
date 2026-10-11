import SwiftUI
import UIKit

@main
struct CompagnonApp: App {
    @StateObject private var app = AppState()
    @Environment(\.scenePhase) private var phase

    init() {
        let a = UITabBarAppearance()
        a.configureWithTransparentBackground()
        a.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)
        UITabBar.appearance().standardAppearance = a
        if #available(iOS 15.0, *) { UITabBar.appearance().scrollEdgeAppearance = a }
        UITableView.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .preferredColorScheme(.dark)
                .accentColor(Theme.amber)
                .onChange(of: phase) { p in
                    if p == .background { app.background() }
                    if p == .active { app.welcome() }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                HomeView().tabItem { Label("Accueil", systemImage: "house.fill") }
                WardrobeView().tabItem { Label("Garde-robe", systemImage: "bag.fill") }
                ShopView(embedded: true).tabItem { Label("Boutique", systemImage: "cart.fill") }
                ToolsHubView().tabItem { Label("Outils", systemImage: "square.grid.2x2.fill") }
                MoreView().tabItem { Label("Plus", systemImage: "slider.horizontal.3") }
            }
            if let t = app.toast {
                Text(t)
                    .font(Theme.rounded(14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .glass(20)
                    .padding(.top, 58)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
    }
}
