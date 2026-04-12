import SwiftUI
import ServiceManagement
import HotKey

// MARK: - App State

/// Central observable state for the app's persistent settings and configuration.
@Observable
@MainActor
final class AppState {
    // MARK: - Model Configuration

    var selectedModelID: String {
        didSet { UserDefaults.standard.set(selectedModelID, forKey: "selectedModelID") }
    }

    // MARK: - Rephrase Settings

    var defaultMode: RephraseMode {
        didSet {
            if let data = try? JSONEncoder().encode(defaultMode) {
                UserDefaults.standard.set(data, forKey: "defaultMode")
            }
        }
    }

    var customModes: [CustomMode] {
        didSet {
            if let data = try? JSONEncoder().encode(customModes) {
                UserDefaults.standard.set(data, forKey: "customModes")
            }
        }
    }

    var enabledPresetModes: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(enabledPresetModes), forKey: "enabledPresetModes")
        }
    }

    // MARK: - Behavior

    var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }

    var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silently fail — user can retry from Settings
            }
        }
    }

    // MARK: - Keyboard Shortcut

    /// Carbon key code for the global shortcut (default: R = 15)
    var shortcutKeyCode: UInt32 {
        didSet { UserDefaults.standard.set(Int(shortcutKeyCode), forKey: "shortcutKeyCode") }
    }

    /// Carbon modifier flags for the global shortcut (default: Option+Shift)
    var shortcutModifiers: UInt32 {
        didSet { UserDefaults.standard.set(Int(shortcutModifiers), forKey: "shortcutModifiers") }
    }

    /// Human-readable display of the current shortcut
    var shortcutDisplay: String {
        let combo = KeyCombo(carbonKeyCode: shortcutKeyCode, carbonModifiers: shortcutModifiers)
        return combo.description
    }

    // MARK: - Onboarding

    var isOnboardingComplete: Bool {
        didSet { UserDefaults.standard.set(isOnboardingComplete, forKey: "isOnboardingComplete") }
    }

    // MARK: - Computed

    var selectedModel: LocalModel? {
        ModelCatalog.all.first(where: { $0.id == selectedModelID })
    }

    var allAvailableModes: [RephraseMode] {
        var modes: [RephraseMode] = RephraseMode.allPresets.filter { enabledPresetModes.contains($0.id) }
        modes.append(contentsOf: customModes.map { .custom($0) })
        return modes
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard

        // Load selected model
        self.selectedModelID = defaults.string(forKey: "selectedModelID") ?? ModelCatalog.recommended.id

        // Load default mode
        if let data = defaults.data(forKey: "defaultMode"),
           let mode = try? JSONDecoder().decode(RephraseMode.self, from: data) {
            self.defaultMode = mode
        } else {
            self.defaultMode = .professional
        }

        // Load custom modes
        if let data = defaults.data(forKey: "customModes"),
           let modes = try? JSONDecoder().decode([CustomMode].self, from: data) {
            self.customModes = modes
        } else {
            self.customModes = []
        }

        // Load enabled presets (all enabled by default)
        if let arr = defaults.array(forKey: "enabledPresetModes") as? [String] {
            self.enabledPresetModes = Set(arr)
        } else {
            self.enabledPresetModes = Set(RephraseMode.allPresets.map { $0.id })
        }

        // Load keyboard shortcut (default: Option+Shift+R)
        let defaultKeyCode = Key.r.carbonKeyCode
        let defaultModifiers = NSEvent.ModifierFlags([.option, .shift]).carbonFlags
        let savedKeyCode = defaults.object(forKey: "shortcutKeyCode") as? Int
        let savedModifiers = defaults.object(forKey: "shortcutModifiers") as? Int
        self.shortcutKeyCode = UInt32(savedKeyCode ?? Int(defaultKeyCode))
        self.shortcutModifiers = UInt32(savedModifiers ?? Int(defaultModifiers))

        // Load behavior
        self.soundEnabled = defaults.bool(forKey: "soundEnabled")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.isOnboardingComplete = defaults.bool(forKey: "isOnboardingComplete")
    }
}
