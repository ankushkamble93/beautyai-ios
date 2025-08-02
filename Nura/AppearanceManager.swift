import SwiftUI

@MainActor
class AppearanceManager: ObservableObject {
    @Published var colorSchemePreference: String {
        didSet {
            UserDefaults.standard.set(colorSchemePreference, forKey: "colorSchemePreference")
        }
    }
    init() {
        // For new users, default to light mode
        // For existing users who haven't set a preference, also default to light mode
        let savedPreference = UserDefaults.standard.string(forKey: "colorSchemePreference")
        if savedPreference == nil || savedPreference == "system" {
            // If no preference is saved or it's set to "system", default to "light"
            self.colorSchemePreference = "light"
            UserDefaults.standard.set("light", forKey: "colorSchemePreference")
        } else {
            self.colorSchemePreference = savedPreference!
        }
    }
} 