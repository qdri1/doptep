import SwiftUI

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    var onSwipeBackBegan: (() -> Void)?

    final class Coordinator: NSObject {
        let onSwipeBackBegan: (() -> Void)?
        weak var attachedRecognizer: UIGestureRecognizer?

        init(onSwipeBackBegan: (() -> Void)?) {
            self.onSwipeBackBegan = onSwipeBackBegan
        }

        @objc func handleGesture(_ recognizer: UIGestureRecognizer) {
            if recognizer.state == .began {
                onSwipeBackBegan?()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipeBackBegan: onSwipeBackBegan)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            guard let recognizer = uiViewController.navigationController?.interactivePopGestureRecognizer else { return }
            recognizer.isEnabled = true
            recognizer.delegate = nil
            if context.coordinator.attachedRecognizer !== recognizer {
                recognizer.addTarget(context.coordinator, action: #selector(Coordinator.handleGesture(_:)))
                context.coordinator.attachedRecognizer = recognizer
            }
        }
    }
}

extension View {
    func enableSwipeBack(onSwipeBackBegan: (() -> Void)? = nil) -> some View {
        background(SwipeBackEnabler(onSwipeBackBegan: onSwipeBackBegan))
    }
}
