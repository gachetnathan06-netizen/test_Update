import SwiftUI
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let app = AppState()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let a = UITabBarAppearance()
        a.configureWithTransparentBackground()
        a.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)
        UITabBar.appearance().standardAppearance = a
        if #available(iOS 15.0, *) { UITabBar.appearance().scrollEdgeAppearance = a }
        UITableView.appearance().backgroundColor = .clear
        UISwitch.appearance().onTintColor = UIColor(red: 1, green: 0.71, blue: 0.28, alpha: 1)

        let host = UIHostingController(rootView: RootView().environmentObject(app).accentColor(Theme.amber))
        host.overrideUserInterfaceStyle = .dark
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.overrideUserInterfaceStyle = .dark
        w.rootViewController = host
        w.makeKeyAndVisible()
        window = w

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.app.background()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.app.welcome()
        }
        return true
    }
}

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                HomeView().tabItem { Image(systemName: "house.fill"); Text("Accueil") }
                WardrobeView().tabItem { Image(systemName: "bag.fill"); Text("Garde-robe") }
                FocusView().tabItem { Image(systemName: "timer"); Text("Focus") }
                HoopView().tabItem { Image(systemName: "gamecontroller.fill"); Text("Panier") }
                MoreView().tabItem { Image(systemName: "slider.horizontal.3"); Text("Plus") }
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
