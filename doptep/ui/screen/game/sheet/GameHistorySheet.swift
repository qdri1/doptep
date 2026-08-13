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
    @State private var pdfShareURL: URL?
    @State private var showShareSheet = false
    @State private var showShareError = false
    @State private var isPreparingPDF = false

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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await shareAsPDF() }
                    } label: {
                        if isPreparingPDF {
                            ProgressView()
                                .tint(AppColor.onSurface)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(AppColor.onSurface)
                        }
                    }
                    .disabled(gameHistory.isEmpty || isPreparingPDF)
                    .accessibilityLabel(NSLocalizedString(isPreparingPDF ? "share_pdf_preparing" : "share", comment: ""))
                }
            }
        }
        .onDisappear { stopAutoScroll() }
        .sheet(isPresented: $showShareSheet) {
            if let pdfShareURL {
                ShareSheet(items: [pdfShareURL])
            }
        }
        .alert(NSLocalizedString("share_pdf_error", comment: ""), isPresented: $showShareError) {
            Button("OK", role: .cancel) {}
        }
    }

    /// Renders the history list to a single-page PDF and hands it to the
    /// system share sheet, retrying internally if the first attempt fails.
    ///
    /// `ImageRenderer` needs SwiftUI to have actually completed a
    /// layout/draw pass for its content before its reported size is
    /// reliable. The very first `ImageRenderer` use in an app session can
    /// still report a `size` of `.zero` to `render(...)` even after an
    /// eager `.uiImage` warm-up (the underlying render pipeline itself is
    /// what's cold, not just this one view) — that produces an empty PDF
    /// page and shows up as a blank share sheet. Rather than surface that
    /// as a failure the user has to work around by tapping again, this
    /// retries a couple of times with a short delay in between, which is
    /// enough for the pipeline to finish warming up. The share sheet only
    /// opens once a real, non-empty PDF exists.
    @MainActor
    private func shareAsPDF() async {
        isPreparingPDF = true
        defer { isPreparingPDF = false }

        if let url = await renderPDF(attempts: 3) {
            pdfShareURL = url
            showShareSheet = true
        } else {
            showShareError = true
        }
    }

    @MainActor
    private func renderPDF(attempts: Int) async -> URL? {
        for attempt in 0..<attempts {
            let content = GameHistoryPDFContent(gameHistory: gameHistory)
            let renderer = ImageRenderer(content: content)
            renderer.scale = UIScreen.main.scale
            _ = renderer.uiImage

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("game_history_\(Int(Date().timeIntervalSince1970))_\(attempt)")
                .appendingPathExtension("pdf")

            var didRenderPDF = false
            renderer.render { size, renderContext in
                guard size.width > 0, size.height > 0 else { return }
                var mediaBox = CGRect(origin: .zero, size: size)
                guard let pdfContext = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else { return }
                pdfContext.beginPDFPage(nil)
                renderContext(pdfContext)
                pdfContext.endPDFPage()
                pdfContext.closePDF()
                didRenderPDF = true
            }

            if didRenderPDF {
                return url
            }

            try? await Task.sleep(for: .milliseconds(150))
        }
        return nil
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

// MARK: - PDF export content

/// Off-screen layout used only for PDF rendering (via `ImageRenderer`). Fixed
/// width so the renderer can measure a definite ideal height for the whole
/// list — unlike `historyContent`, this isn't hosted in a `ScrollView`, since
/// the PDF page just grows to fit everything on one long page.
private struct GameHistoryPDFContent: View {
    let gameHistory: [GameHistoryEntryUiModel]

    var body: some View {
        VStack(spacing: 0) {
            Text(NSLocalizedString("function_history", comment: ""))
                .font(.titleLarge)
                .foregroundColor(AppColor.onSurface)
                .padding(.vertical, 16)

            ForEach(Array(gameHistory.enumerated()), id: \.offset) { _, entry in
                GameHistoryEntryItemView(entry: entry)
                Divider()
                    .background(AppColor.surfaceVariant)
            }
        }
        .frame(width: 600)
        .background(AppColor.surface)
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
