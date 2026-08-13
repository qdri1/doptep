import SwiftUI
import UIKit

// MARK: - Auto-scroll state

private enum AutoScrollDirection { case none, up, down }

private enum ScrollSpeed {
    case x1, x2, x3

    var delta: CGFloat {
        switch self {
        case .x1: return 3
        case .x2: return 6
        case .x3: return 12
        }
    }

    var label: String {
        switch self {
        case .x1: return "1x"
        case .x2: return "2x"
        case .x3: return "3x"
        }
    }

    var next: ScrollSpeed {
        switch self {
        case .x1: return .x2
        case .x2: return .x3
        case .x3: return .x1
        }
    }
}

// MARK: - Smooth scroll controller

final class SmoothScrollController: ObservableObject {
    weak var scrollView: UIScrollView?

    /// Scrolls by `delta` points. Returns true when the boundary is reached.
    @discardableResult
    func scrollBy(_ delta: CGFloat) -> Bool {
        guard let sv = scrollView else { return true }
        let maxOffset = max(0, sv.contentSize.height - sv.bounds.height)
        guard maxOffset > 0 else { return true }
        let newY = min(max(0, sv.contentOffset.y + delta), maxOffset)
        sv.contentOffset = CGPoint(x: 0, y: newY)
        return delta > 0 ? newY >= maxOffset : newY <= 0
    }
}

// MARK: - UIKit scroll host

final class SmoothScrollViewController: UIViewController, UIScrollViewDelegate {
    let scrollView = UIScrollView()
    var onUserScroll: (() -> Void)?
    private var hostingController: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(AppColor.surface)
        scrollView.backgroundColor = UIColor(AppColor.surface)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func setContent(_ content: AnyView) {
        if let host = hostingController {
            host.rootView = content
        } else {
            let host = UIHostingController(rootView: content)
            host.view.backgroundColor = UIColor(AppColor.surface)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            addChild(host)
            scrollView.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                host.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                host.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                host.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            ])
            host.didMove(toParent: self)
            hostingController = host
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.setContentOffset(.zero, animated: false)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        onUserScroll?()
    }
}

struct SmoothScrollView: UIViewControllerRepresentable {
    let controller: SmoothScrollController
    let onUserScroll: () -> Void
    let content: AnyView

    func makeUIViewController(context: Context) -> SmoothScrollViewController {
        let vc = SmoothScrollViewController()
        vc.onUserScroll = onUserScroll
        controller.scrollView = vc.scrollView
        vc.setContent(content)
        return vc
    }

    func updateUIViewController(_ uiViewController: SmoothScrollViewController, context: Context) {
        controller.scrollView = uiViewController.scrollView
        uiViewController.setContent(content)
    }
}

// MARK: - Scroll control button

private struct ScrollControlButton<Content: View>: View {
    let isActive: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isActive ? AppColor.primary : AppColor.secondaryContainer)
                    .frame(width: 44, height: 44)
                content()
            }
        }
    }
}

// MARK: - Main sheet

struct GameHistorySheet: View {
    let gameHistory: [GameHistoryEntryUiModel]

    @State private var autoScrollDirection: AutoScrollDirection = .none
    @State private var scrollSpeed: ScrollSpeed = .x1
    @StateObject private var scrollController = SmoothScrollController()
    @State private var autoScrollTask: Task<Void, Never>?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if gameHistory.isEmpty {
                    Text(NSLocalizedString("game_history_empty", comment: ""))
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.outline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    Spacer()
                } else {
                    SmoothScrollView(
                        controller: scrollController,
                        onUserScroll: { stopAutoScroll() },
                        content: AnyView(historyContent)
                    )
                    Divider()
                    scrollControls
                }
            }
            .background(AppColor.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("function_history", comment: ""))
                        .font(.bodyMedium)
                        .foregroundColor(AppColor.onSurface)
                }
            }
        }
        .onDisappear { stopAutoScroll() }
    }

    private var historyContent: some View {
        VStack(spacing: 0) {
            ForEach(Array(gameHistory.enumerated()), id: \.offset) { _, entry in
                GameHistoryEntryItemView(entry: entry)
                Divider()
                    .background(AppColor.surfaceVariant)
            }
        }
    }

    private var scrollControls: some View {
        HStack(spacing: 16) {
            ScrollControlButton(isActive: autoScrollDirection == .up, action: {
                if autoScrollDirection == .up { stopAutoScroll() } else { startAutoScroll(.up) }
            }) {
                Image(systemName: "chevron.up")
                    .foregroundColor(autoScrollDirection == .up ? AppColor.onPrimary : AppColor.onSecondaryContainer)
            }

            ScrollControlButton(isActive: false, action: {
                scrollSpeed = scrollSpeed.next
                // Restart auto-scroll with updated speed if active
                if autoScrollDirection != .none {
                    let dir = autoScrollDirection
                    startAutoScroll(dir)
                }
            }) {
                Text(scrollSpeed.label)
                    .font(.labelMedium)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.onSecondaryContainer)
            }

            ScrollControlButton(isActive: autoScrollDirection == .down, action: {
                if autoScrollDirection == .down { stopAutoScroll() } else { startAutoScroll(.down) }
            }) {
                Image(systemName: "chevron.down")
                    .foregroundColor(autoScrollDirection == .down ? AppColor.onPrimary : AppColor.onSecondaryContainer)
            }
        }
        .padding(.vertical, 12)
    }

    private func startAutoScroll(_ direction: AutoScrollDirection) {
        stopAutoScroll()
        autoScrollDirection = direction
        autoScrollTask = Task { @MainActor in
            while !Task.isCancelled {
                let delta = direction == .down ? scrollSpeed.delta : -scrollSpeed.delta
                let atEnd = scrollController.scrollBy(delta)
                if atEnd {
                    autoScrollDirection = .none
                    break
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollDirection = .none
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }
}

// MARK: - Entry item

private struct GameHistoryEntryItemView: View {
    let entry: GameHistoryEntryUiModel

    private var backgroundGradient: LinearGradient? {
        if entry.winnerTeamName.isEmpty { return nil }
        if entry.winnerTeamName == entry.leftTeamName {
            return LinearGradient(
                colors: [
                    entry.leftTeamColor.color == .white ? AppColor.surfaceVariant.opacity(0.5) : entry.leftTeamColor.color.opacity(0.25),
                    AppColor.surface
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [
                    AppColor.surface,
                    entry.rightTeamColor.color == .white ? AppColor.surfaceVariant.opacity(0.5) : entry.rightTeamColor.color.opacity(0.25)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Game number + duration
            HStack {
                Text(String(format: NSLocalizedString("game_history_game_number", comment: ""), entry.gameNumber))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.outline)
                Spacer()
                if let duration = entry.durationFormatted {
                    Text("⏱ \(duration)")
                        .font(.labelSmall)
                        .foregroundColor(AppColor.outline)
                }
            }

            Spacer().frame(height: 4)

            // Score row
            HStack(spacing: 8) {
                Text(entry.leftTeamName)
                    .font(.labelSmall)
                    .foregroundColor(AppColor.onSurface)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                TeamColorDotView(teamColor: entry.leftTeamColor)

                Text("\(entry.leftTeamGoals) - \(entry.rightTeamGoals)")
                    .font(.displayLarge)
                    .foregroundColor(AppColor.onSurface)
                    .padding(.horizontal, 4)

                TeamColorDotView(teamColor: entry.rightTeamColor)

                Text(entry.rightTeamName)
                    .font(.labelSmall)
                    .foregroundColor(AppColor.onSurface)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Winner / draw row
            if entry.winnerTeamName.isEmpty {
                Text(NSLocalizedString("game_history_draw", comment: ""))
                    .font(.labelSmall)
                    .foregroundColor(AppColor.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 0) {
                    let leftIsWinner = entry.winnerTeamName == entry.leftTeamName
                    Text(leftIsWinner
                         ? NSLocalizedString("game_history_winner", comment: "")
                         : NSLocalizedString("game_history_loser", comment: ""))
                        .font(leftIsWinner ? .labelLarge : .labelMedium)
                        .foregroundColor(leftIsWinner ? AppColor.primary : AppColor.error)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    let rightIsWinner = entry.winnerTeamName == entry.rightTeamName
                    Text(rightIsWinner
                         ? NSLocalizedString("game_history_winner", comment: "")
                         : NSLocalizedString("game_history_loser", comment: ""))
                        .font(rightIsWinner ? .labelLarge : .labelMedium)
                        .foregroundColor(rightIsWinner ? AppColor.primary : AppColor.error)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }

            // Action events
            if !entry.actionEvents.isEmpty {
                Spacer().frame(height: 4)
                ForEach(entry.actionEvents) { event in
                    ActionEventRowView(event: event)
                }
            }
        }
        .padding(16)
        .background {
            if let gradient = backgroundGradient {
                gradient
            } else {
                AppColor.surface
            }
        }
    }
}

// MARK: - Action event row

private struct ActionEventRowView: View {
    let event: GameHistoryActionEventUiModel

    var body: some View {
        HStack(spacing: 6) {
            Text(event.elapsedFormatted)
                .font(.labelSmall)
                .foregroundColor(AppColor.outline)

            PlayerTeamBadge(teamColor: event.teamColor, number: event.playerNumber)

            Text(event.playerName)
                .font(.labelSmall)
                .foregroundColor(AppColor.onSurface)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(actionTypeLabel(event.actionType))
                .font(.labelSmall)
                .foregroundColor(AppColor.outline)
        }
    }

    private func actionTypeLabel(_ actionType: String) -> String {
        switch actionType {
        case "goal": return NSLocalizedString("text_goal", comment: "") + " ⚽️"
        case "assist": return NSLocalizedString("text_assist", comment: "")
        case "save": return NSLocalizedString("text_save", comment: "")
        case "tackle": return NSLocalizedString("text_tackle", comment: "")
        case "dribble": return NSLocalizedString("text_dribble", comment: "")
        case "pass": return NSLocalizedString("text_pass", comment: "")
        case "shot": return NSLocalizedString("text_shot", comment: "")
        case "yellowCard": return NSLocalizedString("text_yellow_card", comment: "")
        case "redCard": return NSLocalizedString("text_red_card", comment: "")
        default: return actionType
        }
    }
}

// MARK: - Color dots

private struct TeamColorDotView: View {
    let teamColor: TeamColor

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(teamColor.color)
            .frame(width: 16, height: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(teamColor == .white ? AppColor.surfaceVariant : Color.clear, lineWidth: 1)
            )
    }
}
