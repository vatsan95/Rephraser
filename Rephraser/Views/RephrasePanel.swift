import AppKit
import SwiftUI

// MARK: - Rephrase Panel

/// A floating panel that appears above all windows (including fullscreen).
/// When shown, it activates the app to receive keyboard events (Enter/Escape).
/// The source app is re-focused before pasting on Accept.
final class RephrasePanel: NSPanel {
    static let shared = RephrasePanel()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 280),
            styleMask: [.fullSizeContentView, .borderless],
            backing: .buffered,
            defer: true
        )

        level = .floating
        isFloatingPanel = true
        collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces, .transient]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // MARK: - Show / Dismiss

    func showPanel(with coordinator: RephraseCoordinator) {
        let content = RephrasePanelContent(coordinator: coordinator)
            .frame(width: 480)
            .frame(minHeight: 200, maxHeight: 400)

        let hostingView = NSHostingView(rootView: content)
        contentView = hostingView

        // Position on the screen where the mouse cursor is
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) })
            ?? NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - frame.width / 2
            let y = screenFrame.midY - frame.height / 2 + 100 // Slightly above center
            setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Show panel and activate our app so we receive keyboard events
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Fade in
        alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            animator().alphaValue = 1
        }
    }

    func dismissPanel() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            self.alphaValue = 1
        })
    }
}
