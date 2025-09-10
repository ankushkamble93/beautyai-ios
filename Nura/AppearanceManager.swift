import SwiftUI

@MainActor
class AppearanceManager: ObservableObject {
    @Published var colorSchemePreference: String {
        didSet {
            UserDefaults.standard.set(colorSchemePreference, forKey: "colorSchemePreference")
        }
    }
    
    /// Computed property to determine if the app should use dark mode
    /// This helps avoid complex boolean expressions in SwiftUI views that cause compiler type-checking issues
    var isDarkMode: Bool {
        return colorSchemePreference == "dark" || 
               (colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark)
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