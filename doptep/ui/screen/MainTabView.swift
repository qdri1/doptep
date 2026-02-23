import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    init() {
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = [
            .font: UIFont(name: "Montserrat-Medium", size: 12) ?? UIFont.systemFont(ofSize: 12)
        ]
        itemAppearance.selected.titleTextAttributes = [
            .font: UIFont(name: "Montserrat-SemiBold", size: 12) ?? UIFont.boldSystemFont(ofSize: 12)
        ]

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColor.surface)
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            HomeScreen(viewModel: HomeViewModel(repository: GameRepository(context: modelContext)))
                .tabItem {
                    Label(NSLocalizedString("tab_home", comment: ""), systemImage: "house")
                }

            NavigationStack {
                SettingsScreen()
            }
            .tabItem {
                Label(NSLocalizedString("tab_settings", comment: ""), systemImage: "gearshape")
            }
        }
        .tint(AppColor.primary)
    }
}
