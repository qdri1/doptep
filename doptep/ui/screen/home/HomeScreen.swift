import SwiftUI
import SwiftData

struct HomeScreen: View {

    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: HomeViewModel
    @State private var navigationPath = NavigationPath()

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {

                // BACKGROUND
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                // CONTENT
                if viewModel.uiState.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)

                } else if !viewModel.uiState.games.isEmpty {
                    gamesList

                } else {
                    emptyState
                }

                // FAB
                addGameButton
            }
            .navigationDestination(for: HomeEffect.self) { effect in
                switch effect {
                case .openAddGameScreen:
                    AddGameScreen(viewModel: AddGameViewModel(
                        gameRepository: GameRepository(context: modelContext),
                        liveGameRepository: LiveGameRepository(context: modelContext),
                        teamRepository: TeamRepository(context: modelContext),
                        teamHistoryRepository: TeamHistoryRepository(context: modelContext),
                        playerRepository: PlayerRepository(context: modelContext),
                        playerHistoryRepository: PlayerHistoryRepository(context: modelContext)
                    ))

                case .openGameScreen(let id):
                    GameScreen(viewModel: GameViewModel(
                        gameId: id,
                        gameRepository: GameRepository(context: modelContext),
                        liveGameRepository: LiveGameRepository(context: modelContext),
                        teamRepository: TeamRepository(context: modelContext),
                        teamHistoryRepository: TeamHistoryRepository(context: modelContext),
                        playerRepository: PlayerRepository(context: modelContext),
                        playerHistoryRepository: PlayerHistoryRepository(context: modelContext),
                        audioManager: AudioManager()
                    ))
                }
            }
            .onChange(of: viewModel.uiState.effect) { oldValue, newValue in
                guard let effect = newValue else { return }
                navigationPath.append(effect)
                viewModel.uiState.effect = nil
            }
            .onChange(of: navigationPath.count) { _, newCount in
                if newCount == 0 {
                    viewModel.send(.onInterceptionNavigationResult)
                }
            }
        }
    }
}

private extension HomeScreen {

    var gamesList: some View {
        List {
            ForEach(viewModel.uiState.games) { item in
                VStack(alignment: .leading, spacing: 6) {

                    row(
                        title: NSLocalizedString("home_game_name", comment: ""),
                        value: item.name
                    )

                    row(
                        title: NSLocalizedString("home_game_format", comment: ""),
                        value: item.gameFormat.rawValue
                    )

                    row(
                        title: NSLocalizedString("home_game_team_quantity", comment: ""),
                        value: "\(item.teamQuantity.rawValue)"
                    )

                    row(
                        title: NSLocalizedString("home_game_time", comment: ""),
                        value: "\(item.timeInMinutes) минут"
                    )

                    row(
                        title: NSLocalizedString("home_game_rule", comment: ""),
                        value: NSLocalizedString(item.gameRule.localizationKey, comment: "")
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onTapGesture {
                    viewModel.send(.onGameCardClicked(item.id))
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.send(.onRefreshed)
        }
        .padding(.bottom, 96)
    }
}

private extension HomeScreen {

    var emptyState: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("game_empty", comment: ""))
                .foregroundColor(.secondary)
                .font(.footnote)

            Button {
                viewModel.send(.onRefreshIconClicked)
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
            }
        }
    }
}

private extension HomeScreen {

    var addGameButton: some View {
        VStack {
            Spacer()
            Button {
                viewModel.send(.onAddGameButtonClicked)
            } label: {
                Text(NSLocalizedString("add_game", comment: ""))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 16)
        }
    }
}


private extension HomeScreen {

    func row(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)

            Text(value)
                .font(.caption2)
                .foregroundColor(.primary)
        }
    }
}
