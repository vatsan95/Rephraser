import AppKit
import HotKey

// MARK: - Hotkey Service

/// Manages the global keyboard shortcut registration
@MainActor
final class HotkeyService {
    private var hotKey: HotKey?
    private var handler: (() -> Void)?

    /// The currently registered shortcut description (for display in UI)
    private(set) var currentShortcutDisplay: String = "⌥⇧R"

    /// Register the global hotkey with the given handler
    func register(handler: @escaping () -> Void) {
        self.handler = handler
        registerDefault()
    }

    /// Register the default shortcut: Option + Shift + R
    func registerDefault() {
        register(key: .r, modifiers: [.option, .shift])
        currentShortcutDisplay = "⌥⇧R"
    }

    /// Register a custom shortcut
    func register(key: Key, modifiers: NSEvent.ModifierFlags) {
        // Unregister any existing hotkey
        hotKey = nil

        hotKey = HotKey(key: key, modifiers: modifiers)
        hotKey?.keyDownHandler = { [weak self] in
            self?.handler?()
        }
    }

    /// Unregister the current hotkey
    func unregister() {
        hotKey = nil
    }
}
