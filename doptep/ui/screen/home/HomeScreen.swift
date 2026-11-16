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
                AppColor.background
                    .ignoresSafeArea()

                // CONTENT
                if viewModel.uiState.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)

                } else if !viewModel.uiState.games.isEmpty {
                    gamesList

                    // FAB
                    addGameButton

                } else {
                    emptyState
                }
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
                    .toolbar(.hidden, for: .tabBar)

                case .openGameScreen(let id):
                    GameScreen(viewModel: GameViewModel(
                        gameId: id,
                        gameRepository: GameRepository(context: modelContext),
                        liveGameRepository: LiveGameRepository(context: modelContext),
                        teamRepository: TeamRepository(context: modelContext),
                        teamHistoryRepository: TeamHistoryRepository(context: modelContext),
                        playerRepository: PlayerRepository(context: modelContext),
                        playerHistoryRepository: PlayerHistoryRepository(context: modelContext),
                        gameHistoryRepository: GameHistoryRepository(context: modelContext),
                        audioManager: AudioManager.shared
                    ))
                    .toolbar(.hidden, for: .tabBar)
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
            Text(NSLocalizedString("tab_home", comment: ""))
                .font(.custom("Montserrat-Bold", size: 28))
                .foregroundColor(AppColor.onBackground)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 4, trailing: 20))

            ForEach(viewModel.uiState.games) { item in
                Button {
                    viewModel.send(.onGameCardClicked(item.id))
                } label: {
                    GameCard(game: item)
                }
                .buttonStyle(PressableCardStyle())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .scrollIndicators(.hidden)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8)
        .contentMargins(.bottom, 104)
        .refreshable {
            viewModel.send(.onRefreshed)
        }
    }
}

private extension HomeScreen {

    var emptyState: some View {
        VStack(spacing: 16) {
            LottieView(name: "soccer-ball")
                .frame(width: 140, height: 140)

            VStack(spacing: 8) {
                Text(NSLocalizedString("game_empty", comment: ""))
                    .font(.titleLarge)
                    .foregroundColor(AppColor.onBackground)
                    .multilineTextAlignment(.center)

                Text(NSLocalizedString("game_empty_subtitle", comment: ""))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            addGameLabelButton
                .padding(.top, 8)
        }
        .padding(.bottom, 40)
    }
}

private extension HomeScreen {

    var addGameButton: some View {
        VStack {
            Spacer()
            addGameLabelButton
                .shadow(color: AppColor.primary.opacity(0.35), radius: 12, x: 0, y: 6)
                .padding(.bottom, 16)
        }
    }

    var addGameLabelButton: some View {
        Button {
            viewModel.send(.onAddGameButtonClicked)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text(NSLocalizedString("add_game", comment: ""))
                    .font(.bodyLarge)
            }
            .foregroundColor(AppColor.onPrimary)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(AppColor.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(PressableCardStyle())
    }
}

// MARK: - Game card

private struct GameCard: View {
    let game: GameUiModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            details
        }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(game.name)
                    .font(.headlineLarge)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(updatedText)
                    .font(.custom("Montserrat-Medium", size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer(minLength: 8)

            Text(game.gameFormat.rawValue)
                .font(.custom("Montserrat-Bold", size: 20))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ScoreboardBackground(surface: game.pitchSurface))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chips wrap to the next line when they don't fit (e.g. "100 минут").
            ChipsFlowLayout(spacing: 8) {
                InfoChip(
                    icon: "person.3.fill",
                    text: String(format: NSLocalizedString("home_teams_count", comment: ""), game.teamQuantity.rawValue)
                )
                InfoChip(
                    icon: "stopwatch",
                    text: String(format: NSLocalizedString("time_in_minutes", comment: ""), game.timeInMinutes)
                )
                InfoChip(
                    icon: "sportscourt.fill",
                    text: NSLocalizedString(game.pitchSurface.localizationKey, comment: "")
                )
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.labelSmall)
                    .foregroundColor(AppColor.primary)
                    .padding(.top, 1)
                Text(NSLocalizedString(game.gameRule.localizationKey, comment: ""))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.onSurfaceVariant)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.labelMedium)
                    .foregroundColor(AppColor.outline)
            }
        }
        .padding(16)
    }

    private var updatedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named // "вчера", "сейчас" instead of "1 день назад", "через 0 секунд"
        let language = UserDefaults.standard.string(forKey: "app_language") ?? "kk-KZ"
        formatter.locale = Locale(identifier: language)
        let relative = formatter.localizedString(for: game.modifiedTime, relativeTo: max(Date(), game.modifiedTime))
        return String(format: NSLocalizedString("home_updated", comment: ""), relative)
    }
}

private struct InfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColor.primary)
            Text(text)
                .font(.custom("Montserrat-SemiBold", size: 12))
                .foregroundColor(AppColor.onSurface)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColor.background)
        .clipShape(Capsule())
    }
}

/// Lays children out left to right and wraps to a new line when the row is full.
private struct ChipsFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
