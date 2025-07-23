import SwiftUI

@MainActor
class AppearanceManager: ObservableObject {
    @Published var colorSchemePreference: String {
        didSet {
            UserDefaults.standard.set(colorSchemePreference, forKey: "colorSchemePreference")
        }
    }
    init() {
        self.colorSchemePreference = UserDefaults.standard.string(forKey: "colorSchemePreference") ?? "system"
    }
} 