import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColor.surface)
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
