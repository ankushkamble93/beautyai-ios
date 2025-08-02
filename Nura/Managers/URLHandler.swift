import Foundation
import SwiftUI

class URLHandler: ObservableObject {
    static let shared = URLHandler()
    
    @Published var pendingPasswordReset: PasswordResetData?
    
    private init() {}
    
    func handleURL(_ url: URL) {
        print("🔗 URLHandler: Received URL: \(url)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("❌ URLHandler: Failed to parse URL components")
            return
        }
        
        // Handle password reset deep links
        if url.scheme == "nura" && url.host == "reset-password" {
            handlePasswordResetURL(components)
        }
    }
    
    private func handlePasswordResetURL(_ components: URLComponents) {
        print("🔐 URLHandler: Processing password reset URL")
        
        // Extract token and email from URL
        let token = components.queryItems?.first(where: { $0.name == "token" })?.value
        let email = components.queryItems?.first(where: { $0.name == "email" })?.value
        
        print("🔐 URLHandler: Token: \(token?.prefix(10) ?? "nil")...")
        print("🔐 URLHandler: Email: \(email ?? "nil")")
        
        guard let token = token, let email = email else {
            print("❌ URLHandler: Missing token or email in URL")
            return
        }
        
        // Store the reset data for the app to handle
        let resetData = PasswordResetData(token: token, email: email)
        DispatchQueue.main.async {
            self.pendingPasswordReset = resetData
        }
        
        print("✅ URLHandler: Password reset data stored successfully")
    }
}

struct PasswordResetData: Equatable {
    let token: String
    let email: String
} 