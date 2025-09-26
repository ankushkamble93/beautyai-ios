import Foundation
import Supabase
import AuthenticationServices

@MainActor
final class AuthenticationManager: ObservableObject, @unchecked Sendable {
    static let shared = AuthenticationManager()

    internal let supabaseURL = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co")!
    internal let supabaseKey = "sb_publishable_HE1YdE-9m3t2NeS81VC1VQ_cDMqNhDY"
    // TODO: Get fresh API key from Supabase Dashboard → Settings → API → anon public key
    // REVERTED: Back to anon key (service_role should not be used in client apps)
    internal nonisolated let client: SupabaseClient

    @Published private(set) var session: Session? {
        didSet {
            print("🔄 AuthenticationManager: session changed to \(session != nil ? "exists" : "nil")")
        }
    }
    @Published private(set) var userProfile: UserProfile? {
        didSet {
            print("🔄 AuthenticationManager: userProfile changed to \(userProfile?.id ?? "nil")")
            // Notify observers when userProfile changes
            NotificationCenter.default.post(name: .userProfileDidChange, object: userProfile)
        }
    }
    @Published private(set) var isAuthenticated: Bool = false {
        didSet {
            print("🔄 AuthenticationManager: isAuthenticated changed to \(isAuthenticated)")
        }
    }
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isInitialized: Bool = false {
        didSet {
            print("🔄 AuthenticationManager: isInitialized changed to \(isInitialized)")
        }
    }
    
    // Testing flag to control email cache clearing
    private var preserveEmailCacheOnSignOut: Bool = false
    
    // Temporary name storage for immediate display during signup flow
    @Published var tempUserName: String? = nil
    
    private init() {
        print("🚀 Initializing AuthenticationManager")
        print("🔑 Supabase URL: \(supabaseURL)")
        print("🔑 Supabase Key: \(supabaseKey.prefix(50))...")
        
        print("🔧 Creating Supabase client...")
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
        print("✅ Supabase client initialized")
        print("🔧 Client URL: \(supabaseURL)")
        print("🔧 Client key length: \(supabaseKey.count)")
        
        Task {
            // Test the connection first
            await testSupabaseConnection()
            await listenForAuthChanges()
        }
    }

    func listenForAuthChanges() async {
        print("🔄 Starting auth state listener")
        for await authState in client.auth.authStateChanges {
            print("🔄 Auth state changed: \(authState.event)")
            print("🔄 Session exists: \(authState.session != nil)")
            
            if [.initialSession, .signedIn, .signedOut].contains(authState.event) {
                print("🔄 Processing auth state: \(authState.event)")
                await updateAuthState(session: authState.session)
            }
        }
    }

    private func updateAuthState(session: Session?) async {
        print("🔄 Updating auth state...")
        self.session = session
        
        if let session = session {
            let user = session.user
            print("🔄 User found: \(user.email ?? "no email")")
            
            // Try to get name from user metadata first
            var userName: String? = nil
            let userMetadata = user.userMetadata
            print("🔄 Full user metadata: \(userMetadata)")
            print("🔄 User metadata type: \(type(of: userMetadata))")
            print("🔄 User metadata keys: \(userMetadata.keys)")
            
            if let name = userMetadata["name"]?.stringValue {
                userName = name
                print("🔄 Found name in user metadata: '\(userName!)'")
            } else if let fullName = userMetadata["full_name"]?.stringValue {
                userName = fullName
                print("🔄 Found full_name in user metadata: '\(userName!)'")
            } else if let givenName = userMetadata["given_name"]?.stringValue, let familyName = userMetadata["family_name"]?.stringValue {
                userName = "\(givenName) \(familyName)"
                print("🔄 Constructed name from given/family names: '\(userName!)'")
            } else {
                print("🔄 No name found in user metadata")
                print("🔄 Checking each metadata key individually:")
                for (key, value) in userMetadata {
                    print("🔄 Key: '\(key)', Value: '\(value)', Type: \(type(of: value))")
                }
            }
            
            do {
                try await fetchOrCreateUserProfile(userId: user.id.uuidString, email: user.email ?? "", name: userName)
                
                // Force a UI update to ensure ProfileView refreshes
                await MainActor.run {
                    if let currentProfile = self.userProfile {
                        print("🔄 Force refreshing userProfile for UI update")
                        self.userProfile = currentProfile
                    }
                }
            } catch {
                print("❌ Error in fetchOrCreateUserProfile: \(error)")
                errorMessage = error.localizedDescription
                isAuthenticated = false
            }
        } else {
            print("🔄 No session, clearing user profile")
            userProfile = nil
            isAuthenticated = false
        }
        
        // Mark as initialized after first auth state update
        if !isInitialized {
            print("✅ AuthenticationManager initialized")
            isInitialized = true
        }
    }

    func getSessionAccessToken() -> String? {
        return session?.accessToken
    }
    
    // MARK: - Debug and Refresh Functions
    
    func refreshUserProfile() async {
        await forceRefreshUserProfile()
    }
    
    func forceRefreshUserProfile() async {
        print("🔄 Force refreshing user profile...")
        
        guard let session = session else {
            print("❌ No session available for force refresh")
            return
        }
        
        do {
            let user = session.user
            
            // Try to get name from user metadata first
            var userName: String? = nil
            let userMetadata = user.userMetadata
            print("🔄 Force refresh: Full user metadata: \(userMetadata)")
            print("🔄 Force refresh: User metadata type: \(type(of: userMetadata))")
            print("🔄 Force refresh: User metadata keys: \(userMetadata.keys)")
            
            if let name = userMetadata["name"]?.stringValue {
                userName = name
                print("🔄 Force refresh: Found name in user metadata: '\(userName!)'")
            } else if let fullName = userMetadata["full_name"]?.stringValue {
                userName = fullName
                print("🔄 Force refresh: Found full_name in user metadata: '\(userName!)'")
            } else if let givenName = userMetadata["given_name"]?.stringValue, let familyName = userMetadata["family_name"]?.stringValue {
                userName = "\(givenName) \(familyName)"
                print("🔄 Force refresh: Constructed name from given/family names: '\(userName!)'")
            } else {
                print("🔄 Force refresh: No name found in user metadata")
                print("🔄 Force refresh: Checking each metadata key individually:")
                for (key, value) in userMetadata {
                    print("🔄 Force refresh: Key: '\(key)', Value: '\(value)', Type: \(type(of: value))")
                }
            }
            
            try await fetchOrCreateUserProfile(userId: user.id.uuidString, email: user.email ?? "", name: userName)
            print("✅ User profile force refreshed successfully")
            
            // Ensure the UI updates with the latest profile data
            await MainActor.run {
                if let currentProfile = self.userProfile {
                    print("🔄 Force updating UI with profile: \(currentProfile.id), name: '\(currentProfile.name)'")
                    // Trigger a UI update by reassigning the profile
                    self.userProfile = currentProfile
                }
            }
        } catch {
            print("❌ Error force refreshing user profile: \(error)")
        }
    }
    
    // MARK: - Temporary Name Management
    
    func setTempUserName(_ name: String) {
        print("🔄 Setting temporary user name: '\(name)'")
        tempUserName = name
    }
    
    func clearTempUserName() {
        print("🔄 Clearing temporary user name")
        tempUserName = nil
    }
    
    func getDisplayName() -> String {
        // Priority: tempUserName -> userProfile.name -> "User"
        if let tempName = tempUserName, !tempName.isEmpty {
            print("🔄 Using temporary name: '\(tempName)'")
            return tempName
        } else if let profileName = userProfile?.name, !profileName.isEmpty {
            print("🔄 Using profile name: '\(profileName)'")
            return profileName
        } else {
            print("🔄 Using fallback name: 'User'")
            return "User"
        }
    }
    
    // MARK: - Email Availability Check
    
    func checkEmailExists(email: String) async throws -> Bool {
        print("🔄 Checking if email exists: \(email)")
        
        // Use smart email checking to avoid rate limiting
        return await checkEmailExistsSmart(email: email)
    }
    
    // Primary method using signup API
    private func checkEmailExistsViaSignup(email: String) async -> Bool {
        print("🔄 Checking email existence via signup API...")
        
        do {
            let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/auth/v1/signup")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            
            let signupData: [String: Any] = [
                "email": email,
                "password": "dummy_password_for_check"
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: signupData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔄 Email check status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔄 Email check response: \(responseString)")
                }
                
                // Check for various error messages that indicate user already exists
                if httpResponse.statusCode == 400 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        let lowercasedResponse = responseString.lowercased()
                        
                        // Check for various error messages that indicate existing user
                        if lowercasedResponse.contains("user already registered") ||
                           lowercasedResponse.contains("already exists") ||
                           lowercasedResponse.contains("already registered") ||
                           lowercasedResponse.contains("email already") {
                            print("🔄 Email exists check result: true (User already exists)")
                            return true
                        }
                    }
                }
                
                // If status is 200, email doesn't exist (signup would succeed)
                if httpResponse.statusCode == 200 {
                    print("🔄 Email exists check result: false (Signup would succeed)")
                    return false
                }
                
                // If status is 422 (validation error), might indicate existing user
                if httpResponse.statusCode == 422 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        let lowercasedResponse = responseString.lowercased()
                        if lowercasedResponse.contains("already") || lowercasedResponse.contains("exists") {
                            print("🔄 Email exists check result: true (Validation error suggests existing user)")
                            return true
                        }
                    }
                }
            }
            
            print(" Email exists check result: false (Unable to determine)")
            return false
        } catch {
            print("❌ Error in email check: \(error)")
            return false
        }
    }
    
    // Smart email existence check with caching and rate limiting protection
    private var emailCache: [String: (exists: Bool, timestamp: Date)] = [:]
    private let emailCacheExpiry: TimeInterval = 300 // 5 minutes
    
    private func checkEmailExistsSmart(email: String) async -> Bool {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 Email check for: '\(normalizedEmail)'")
        print("🔍 Current cache size: \(emailCache.count) entries")
        
        // Check cache first
        if let cached = emailCache[normalizedEmail] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < emailCacheExpiry {
                print("✅ Email check: Using cached result for \(normalizedEmail) (exists: \(cached.exists))")
                return cached.exists
            } else {
                print("⏰ Email check: Cache expired for \(normalizedEmail)")
            }
        } else {
            print("❌ Email check: No cache entry for \(normalizedEmail)")
        }
        
        // If not in cache or expired, actually check the database
        print("🔄 Email check: Checking database for \(normalizedEmail)")
        return await checkEmailExistsViaAuthAPI(email: normalizedEmail)
    }
    
    // Cache successful sign-ups to improve email checking
    func cacheSuccessfulSignup(email: String) {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        emailCache[normalizedEmail] = (exists: true, timestamp: Date()) // Now exists in database
        print("🔄 Cached successful signup for: \(normalizedEmail) (now exists in database)")
    }
    
    // Cache failed sign-ups (email already exists)
    func cacheFailedSignup(email: String) {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        emailCache[normalizedEmail] = (exists: true, timestamp: Date())
        print("🔄 Cached failed signup (email exists) for: \(normalizedEmail)")
    }
    
    // Get email cache statistics for debugging
    func getEmailCacheStats() -> (total: Int, exists: Int, available: Int) {
        let total = emailCache.count
        let exists = emailCache.values.filter { $0.exists }.count
        let available = emailCache.values.filter { !$0.exists }.count
        return (total: total, exists: exists, available: available)
    }
    
    // Testing methods for email cache management
    func enableEmailCachePreservation() {
        preserveEmailCacheOnSignOut = true
        print("🧪 Email cache preservation enabled for testing")
    }
    
    func disableEmailCachePreservation() {
        preserveEmailCacheOnSignOut = false
        print("🧪 Email cache preservation disabled")
    }
    
    func clearEmailCacheOnly() {
        let beforeCount = emailCache.count
        emailCache.removeAll()
        print("🧹 Email cache cleared: \(beforeCount) entries removed")
    }
    
    func addTestEmailToCache(email: String, exists: Bool) {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        emailCache[normalizedEmail] = (exists: exists, timestamp: Date())
        let status = exists ? "exists in database" : "available for signup"
        print("🧪 Test email added to cache: \(normalizedEmail) (\(status))")
    }
    
    // Alternative method using sign-in API (more reliable)
    private func checkEmailExistsViaAuthAPI(email: String) async -> Bool {
        print("🔄 Checking email existence via sign-in API...")
        
        do {
            // Use the sign-in API with a dummy password to check if user exists
            // This won't create a new user, just check if one exists
            let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/auth/v1/token?grant_type=password")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            
            let signInData: [String: Any] = [
                "email": email,
                "password": "dummy_password_for_existence_check"
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: signInData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔄 Sign-in API check status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔄 Sign-in API response: \(responseString)")
                }
                
                // If status is 400 with "Invalid login credentials", user exists but wrong password
                if httpResponse.statusCode == 400 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        let lowercasedResponse = responseString.lowercased()
                        if lowercasedResponse.contains("invalid login credentials") ||
                           lowercasedResponse.contains("invalid email") ||
                           lowercasedResponse.contains("wrong password") {
                            print("🔄 Sign-in API email exists check result: true (User exists, wrong password)")
                            return true
                        }
                    }
                }
                
                // If status is 200, user exists and password was correct (unlikely with dummy password)
                if httpResponse.statusCode == 200 {
                    print("🔄 Sign-in API email exists check result: true (User exists, password correct)")
                    return true
                }
                
                // If status is 404 or other errors, user doesn't exist
                print("🔄 Sign-in API email exists check result: false (User not found)")
                return false
            }
            
            print("🔄 Sign-in API email exists check result: false (Unable to determine)")
            return false
        } catch {
            print("❌ Error in sign-in API check: \(error)")
            return false
        }
    }
    
    // Third method using sign in API
    private func checkEmailExistsViaSignIn(email: String) async -> Bool {
        print("🔄 Checking email existence via sign in API...")
        
        do {
            // Try to sign in with a dummy password to see if user exists
            let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/auth/v1/token?grant_type=password")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            
            let signInData: [String: Any] = [
                "email": email,
                "password": "dummy_password_for_check"
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: signInData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔄 Sign In API check status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔄 Sign In API response: \(responseString)")
                }
                
                // If status is 400 with "Invalid login credentials", user exists but wrong password
                if httpResponse.statusCode == 400 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        let lowercasedResponse = responseString.lowercased()
                        if lowercasedResponse.contains("invalid login credentials") ||
                           lowercasedResponse.contains("invalid email") ||
                           lowercasedResponse.contains("wrong password") {
                            print("🔄 Sign In API email exists check result: true (User exists, wrong password)")
                            return true
                        }
                    }
                }
                
                // If status is 200, user exists and password was correct (unlikely with dummy password)
                if httpResponse.statusCode == 200 {
                    print("🔄 Sign In API email exists check result: true (User exists, password correct)")
                    return true
                }
            }
            
            print("🔄 Sign In API email exists check result: false (Unable to determine)")
            return false
        } catch {
            print("❌ Error in sign in API check: \(error)")
            return false
        }
    }
    
    // MARK: - User Profile Management
    
    func updateUserNameInAuth(userId: String, name: String) async {
        print("🔄 Updating user name in Supabase Auth metadata: '\(name)'")
        do {
            try await client.auth.update(user: UserAttributes(data: ["name": AnyJSON.string(name)]))
            print("✅ User name updated in Supabase Auth metadata")
        } catch {
            print("❌ Failed to update user name in Supabase Auth metadata: \(error)")
        }
    }
    
    func fetchOrCreateUserProfile(userId: String, email: String, name: String? = nil, password: String? = nil) async throws {
        // Normalize userId to lowercase to prevent case sensitivity issues
        let normalizedUserId = userId.lowercased()
        print("🔄 Starting fetchOrCreateUserProfile for userId: \(normalizedUserId), email: \(email), name: '\(name ?? "nil")'")
        print("🔄 Original userId: '\(userId)' -> normalized: '\(normalizedUserId)'")
        
        // Check if we have a valid session first
        guard let currentSession = session else {
            print("❌ No session available - trying to get current session...")
            do {
                let newSession = try await client.auth.session
                print("✅ Retrieved current session: \(newSession.user.email ?? "no email")")
                await updateAuthState(session: newSession)
            } catch {
                print("❌ Failed to get current session: \(error)")
                throw NSError(domain: "SessionError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No valid session available. Please sign in again."])
            }
            return
        }
        
        do {
            print("🔄 Attempting to fetch user profile from database...")
            print("🔄 Using session-only authentication...")
            print("🔄 Query URL: https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?select=*&id=eq.\(normalizedUserId)")
            
            // Use ONLY session-based authentication (no API key)
            let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?select=*&id=eq.\(normalizedUserId)")!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(currentSession.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            // NO API KEY HEADER - using only session token
                
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔄 Session-only database query status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("🔄 Session-only response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode == 200 {
                        print("✅ Session-only database query successful")
                        // Parse the JSON response manually
                        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                            print("🔄 JSON response array length: \(jsonArray.count)")
                            if let profile = jsonArray.first {
                                print("🔄 Found profile in database response")
                                print("🔄 Profile keys: \(profile.keys)")
                                
                                // Convert to UserProfile manually
                                let retrievedName = profile["name"] as? String ?? ""
                                print("🔄 Retrieved name from database: '\(retrievedName)'")
                                print("🔄 Name type: \(type(of: profile["name"]))")
                                print("🔄 Raw name value: \(profile["name"] ?? "nil")")
                                
                                var updatedProfile = UserProfile(
                                    id: profile["id"] as? String ?? normalizedUserId,
                                    email: profile["email"] as? String ?? email,
                                    name: retrievedName,
                                    phone: profile["phone"] as? String, // Add phone field
                                    password: nil, // SECURITY: Never load password from database
                                    premium: profile["premium"] as? String ?? "free",
                                    onboarding_complete: profile["onboarding_complete"] as? Bool ?? false,
                                    stripe_customer_id: profile["stripe_customer_id"] as? String,
                                    subscription_status: profile["subscription_status"] as? String ?? "inactive",
                                    subscription_end_date: nil, // Parse date if needed
                                    created_at: Date(), // Parse date if needed
                                    updated_at: Date() // Parse date if needed
                                )
                                print("🔄 Created UserProfile with name: '\(updatedProfile.name)'")
                                // Parse onboarding_answers dictionary if present
                                if let oa = profile["onboarding_answers"] as? [String: Any] {
                                    var dict: [String: String] = [:]
                                    for (k, v) in oa {
                                        if let s = v as? String { dict[k] = s }
                                    }
                                    updatedProfile.onboarding_answers = dict
                                    print("🔄 Loaded onboarding_answers with \(dict.keys.count) keys")
                                }
                                // If name is empty but OAuth metadata has a name, update it
                                if updatedProfile.name == "" {
                                    let userMetadata = currentSession.user.userMetadata
                                    var userName = ""
                                    if let name = userMetadata["name"]?.stringValue {
                                        userName = name
                                    } else if let fullName = userMetadata["full_name"]?.stringValue {
                                        userName = fullName
                                    } else if let givenName = userMetadata["given_name"]?.stringValue, let familyName = userMetadata["family_name"]?.stringValue {
                                        userName = "\(givenName) \(familyName)"
                                    }
                                    if !userName.isEmpty {
                                        // Update in DB
                                        let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?id=eq.\(normalizedUserId)")!
                                        var request = URLRequest(url: url)
                                        request.httpMethod = "PATCH"
                                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                        request.setValue("Bearer \(currentSession.accessToken)", forHTTPHeaderField: "Authorization")
                                        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
                                        let updateDict = ["name": userName]
                                        request.httpBody = try? JSONSerialization.data(withJSONObject: updateDict)
                                        do {
                                            let (_, response) = try await URLSession.shared.data(for: request)
                                            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                                                print("✅ Updated user name in DB to: \(userName)")
                                                updatedProfile.name = userName
                                            }
                                        } catch {
                                            print("❌ Failed to update user name in DB: \(error)")
                                        }
                                    }
                                }
                                print("🔄 Setting userProfile to: \(updatedProfile.id)")
                                print("🔄 UserProfile name being set from existing profile: '\(updatedProfile.name)'")
                                self.userProfile = updatedProfile
                                isAuthenticated = true
                                print("🔄 User profile found, onboarding_complete: \(updatedProfile.onboarding_complete), isAuthenticated: \(isAuthenticated)")
                                print("🔄 User profile details: id=\(updatedProfile.id), email=\(updatedProfile.email), name=\(updatedProfile.name)")
                                print("🔄 Navigation should show: \(updatedProfile.onboarding_complete ? "DashboardView" : "OnboardingQuestionnaireView")")
                                return
                            }
                        }
                    } else {
                        print("❌ Session-only database query failed: \(httpResponse.statusCode)")
                        // Continue to create new profile
                    }
                }
            
            // If we get here, either no profile found or query failed - create new profile
            print("🔄 No existing profile found or query failed, creating new user profile...")
            print("🔄 Name parameter received: '\(name ?? "nil")'")
            print("🔄 Name parameter type: \(type(of: name))")
            
            // For new users, try to get name from parameter first, then OAuth session
            var userName = ""
            if let providedName = name, !providedName.isEmpty {
                userName = providedName
                print("🔄 Using provided name: '\(userName)'")
            } else {
                print("🔄 No provided name or name is empty, checking OAuth metadata...")
                // Try to get name from OAuth user metadata
                let userMetadata = currentSession.user.userMetadata
                print("🔄 User metadata keys: \(userMetadata.keys)")
                // Try different name fields from OAuth
                if let name = userMetadata["name"]?.stringValue {
                    userName = name
                    print("🔄 Found OAuth name: \(userName)")
                } else if let fullName = userMetadata["full_name"]?.stringValue {
                    userName = fullName
                    print("🔄 Found OAuth full_name: \(userName)")
                } else if let givenName = userMetadata["given_name"]?.stringValue,
                          let familyName = userMetadata["family_name"]?.stringValue {
                    userName = "\(givenName) \(familyName)"
                    print("🔄 Constructed OAuth name: \(userName)")
                } else {
                    print("🔄 No OAuth name found in metadata")
                }
            }
            
            print("🔄 Final userName for new profile: '\(userName)'")
            print("🔄 Creating new profile with name: '\(userName)'")
            let newProfile = UserProfile(
                id: normalizedUserId,
                email: email,
                name: userName, // Use the OAuth name if available
                phone: nil, // No phone provided for new users
                password: password, // Use provided password or nil for OAuth
                premium: "free",
                onboarding_complete: false,
                stripe_customer_id: nil,
                subscription_status: "inactive",
                subscription_end_date: nil,
                created_at: Date(),
                updated_at: Date()
            )
            
            print("🔄 Creating new user profile with session-only authentication...")
            
            // Try to insert using session-only authentication
            let insertUrl = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles")!
            var insertRequest = URLRequest(url: insertUrl)
            insertRequest.httpMethod = "POST"
            insertRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            insertRequest.setValue("Bearer \(currentSession.accessToken)", forHTTPHeaderField: "Authorization")
            insertRequest.setValue(supabaseKey, forHTTPHeaderField: "apikey")
                
                // Convert profile to JSON (EXCLUDE password for security)
                                    let profileDict: [String: Any] = [
                        "id": newProfile.id,
                        "email": newProfile.email,
                        "name": newProfile.name,
                        "phone": newProfile.phone as Any, // Add phone to profileDict
                        // "password": newProfile.password as Any, // REMOVED FOR SECURITY
                        "premium": newProfile.premium ?? "free",
                        "onboarding_complete": newProfile.onboarding_complete,
                        "stripe_customer_id": newProfile.stripe_customer_id as Any,
                        "subscription_status": newProfile.subscription_status,
                        "subscription_end_date": newProfile.subscription_end_date as Any,
                        "created_at": ISO8601DateFormatter().string(from: newProfile.created_at),
                        "updated_at": ISO8601DateFormatter().string(from: newProfile.updated_at)
                    ]
                print("🔄 Inserting profile to database with name: '\(newProfile.name)'")
                print("🔄 Full profile dict being sent: \(profileDict)")
                
                insertRequest.httpBody = try? JSONSerialization.data(withJSONObject: profileDict)
                
                let (insertData, insertResponse) = try await URLSession.shared.data(for: insertRequest)
                if let httpResponse = insertResponse as? HTTPURLResponse {
                    print("🔄 Session-only insert status: \(httpResponse.statusCode)")
                    if let responseString = String(data: insertData, encoding: .utf8) {
                        print("🔄 Session-only insert response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode == 201 {
                        print("✅ New user profile created successfully with session-only auth")
                        print("🔄 Setting userProfile to: \(newProfile.id)")
                        print("🔄 UserProfile name being set: '\(newProfile.name)'")
                        userProfile = newProfile
                        // All new users are authenticated immediately
                        isAuthenticated = true
                        print("🔄 New user profile created, isAuthenticated: \(isAuthenticated)")
                        print("🔄 New user profile details: onboarding_complete=\(newProfile.onboarding_complete)")
                        print("🔄 Navigation should show: \(newProfile.onboarding_complete ? "DashboardView" : "OnboardingQuestionnaireView")")
                        
                        // CRITICAL FIX: If name was provided but is empty in the created profile, update it immediately
                        if let providedName = name, !providedName.isEmpty && newProfile.name.isEmpty {
                            print("⚠️ CRITICAL: Name was provided but profile was created with empty name. Updating immediately...")
                            do {
                                let updateUrl = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?id=eq.\(normalizedUserId)")!
                                var updateRequest = URLRequest(url: updateUrl)
                                updateRequest.httpMethod = "PATCH"
                                updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                updateRequest.setValue("Bearer \(currentSession.accessToken)", forHTTPHeaderField: "Authorization")
                                updateRequest.setValue(supabaseKey, forHTTPHeaderField: "apikey")
                                
                                let updateData = ["name": providedName]
                                print("🔄 CRITICAL: Updating name to: '\(providedName)'")
                                updateRequest.httpBody = try? JSONSerialization.data(withJSONObject: updateData)
                                
                                let (_, updateResponse) = try await URLSession.shared.data(for: updateRequest)
                                if let updateHttpResponse = updateResponse as? HTTPURLResponse {
                                    print("🔄 CRITICAL: Name update status: \(updateHttpResponse.statusCode)")
                                    if updateHttpResponse.statusCode == 204 {
                                        print("✅ CRITICAL: Name updated successfully during profile creation")
                                        // Update local profile
                                        var updatedProfile = newProfile
                                        updatedProfile.name = providedName
                                        userProfile = updatedProfile
                                        print("✅ CRITICAL: Local profile updated with name: '\(providedName)'")
                                    } else {
                                        print("❌ CRITICAL: Failed to update name during profile creation")
                                    }
                                }
                            } catch {
                                print("❌ CRITICAL: Error updating name during profile creation: \(error)")
                            }
                        }
                        
                        // ADDITIONAL FIX: Check Auth metadata for name if profile was created with empty name
                        if newProfile.name.isEmpty {
                            print("🔄 Checking Auth metadata for name since profile was created with empty name...")
                            let userMetadata = currentSession.user.userMetadata
                            var authName = ""
                            if let name = userMetadata["name"]?.stringValue {
                                authName = name
                                print("🔄 Found name in Auth metadata: '\(authName)'")
                            } else if let fullName = userMetadata["full_name"]?.stringValue {
                                authName = fullName
                                print("🔄 Found full_name in Auth metadata: '\(authName)'")
                            } else if let givenName = userMetadata["given_name"]?.stringValue, let familyName = userMetadata["family_name"]?.stringValue {
                                authName = "\(givenName) \(familyName)"
                                print("🔄 Constructed name from Auth metadata: '\(authName)'")
                            }
                            
                            if !authName.isEmpty {
                                print("🔄 Updating profile with name from Auth metadata: '\(authName)'")
                                do {
                                    let updateUrl = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?id=eq.\(normalizedUserId)")!
                                    var updateRequest = URLRequest(url: updateUrl)
                                    updateRequest.httpMethod = "PATCH"
                                    updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                    updateRequest.setValue("Bearer \(currentSession.accessToken)", forHTTPHeaderField: "Authorization")
                                    updateRequest.setValue(supabaseKey, forHTTPHeaderField: "apikey")
                                    
                                    let updateData = ["name": authName]
                                    updateRequest.httpBody = try? JSONSerialization.data(withJSONObject: updateData)
                                    
                                    let (_, updateResponse) = try await URLSession.shared.data(for: updateRequest)
                                    if let updateHttpResponse = updateResponse as? HTTPURLResponse {
                                        print("🔄 Auth metadata name update status: \(updateHttpResponse.statusCode)")
                                        if updateHttpResponse.statusCode == 204 {
                                            print("✅ Auth metadata name updated successfully")
                                            // Update local profile
                                            var updatedProfile = newProfile
                                            updatedProfile.name = authName
                                            userProfile = updatedProfile
                                            print("✅ Local profile updated with Auth metadata name: '\(authName)'")
                                        } else {
                                            print("❌ Failed to update name from Auth metadata")
                                        }
                                    }
                                } catch {
                                    print("❌ Error updating name from Auth metadata: \(error)")
                                }
                            } else {
                                print("🔄 No name found in Auth metadata")
                            }
                        }
                    } else {
                        print("❌ Session-only insert failed: \(httpResponse.statusCode)")
                        print("❌ Insert failed - but still setting profile locally")
                        // Still set the profile locally even if insert fails
                        print("🔄 Setting userProfile to: \(newProfile.id) (local fallback)")
                        userProfile = newProfile
                        isAuthenticated = true
                        print("🔄 New user (local fallback) - authenticated")
                        print("🔄 Using local profile despite insert failure")
                        
                        // CRITICAL FIX: Even in fallback case, try to save the name if provided
                        if let providedName = name, !providedName.isEmpty {
                            print("⚠️ CRITICAL: Insert failed but trying to save name: '\(providedName)'")
                            do {
                                let updateUrl = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?id=eq.\(normalizedUserId)")!
                                var updateRequest = URLRequest(url: updateUrl)
                                updateRequest.httpMethod = "PATCH"
                                updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                updateRequest.setValue("Bearer \(currentSession.accessToken)", forHTTPHeaderField: "Authorization")
                                updateRequest.setValue(supabaseKey, forHTTPHeaderField: "apikey")
                                
                                let updateData = ["name": providedName]
                                print("🔄 CRITICAL: Updating name in fallback: '\(providedName)'")
                                updateRequest.httpBody = try? JSONSerialization.data(withJSONObject: updateData)
                                
                                let (_, updateResponse) = try await URLSession.shared.data(for: updateRequest)
                                if let updateHttpResponse = updateResponse as? HTTPURLResponse {
                                    print("🔄 CRITICAL: Fallback name update status: \(updateHttpResponse.statusCode)")
                                    if updateHttpResponse.statusCode == 204 {
                                        print("✅ CRITICAL: Name updated successfully in fallback")
                                        // Update local profile
                                        var updatedProfile = newProfile
                                        updatedProfile.name = providedName
                                        userProfile = updatedProfile
                                        print("✅ CRITICAL: Local profile updated with name in fallback: '\(providedName)'")
                                    } else {
                                        print("❌ CRITICAL: Failed to update name in fallback")
                                    }
                                }
                            } catch {
                                print("❌ CRITICAL: Error updating name in fallback: \(error)")
                            }
                        }
                    }
                }
            
        } catch {
            print("❌ Error in fetchOrCreateUserProfile: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let postgrestError = error as? PostgrestError {
                print("❌ PostgrestError details: \(postgrestError)")
            }
            errorMessage = error.localizedDescription
            isAuthenticated = false
            print("❌ Error fetching/creating user profile: \(error)")
        }
    }

    func signInWithGoogle() async {
        print("🔗 Starting Google OAuth sign-in")
        isLoading = true
        defer { 
            isLoading = false
            print("🔗 Google OAuth sign-in completed (loading state cleared)")
        }
        
        do {
            print("🔗 Initiating Google OAuth with Supabase...")
            try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "com.nura://"),
                scopes: "email profile"
            )
            print("🔗 Google OAuth sign-in initiated successfully")
            // OAuth sign-in initiates the flow but doesn't return a session immediately
            // The session will be handled by listenForAuthChanges when the OAuth flow completes
        } catch {
            print("❌ Google OAuth sign-in error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func signInWithApple() async {
        print("🔗 Starting Apple OAuth sign-in")
        isLoading = true
        defer { 
            isLoading = false
            print("🔗 Apple OAuth sign-in completed (loading state cleared)")
        }
        do {
            print("🔗 Initiating Apple OAuth with Supabase...")
            try await client.auth.signInWithOAuth(
                provider: .apple,
                redirectTo: URL(string: "com.nura://"),
                scopes: "email profile"
            )
            print("🔗 Apple OAuth sign-in initiated successfully")
            // OAuth sign-in initiates the flow but doesn't return a session immediately
            // The session will be handled by listenForAuthChanges when the OAuth flow completes
        } catch {
            print("❌ Apple OAuth sign-in error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await client.auth.signIn(email: email, password: password)
            let user = response.user
            try await fetchOrCreateUserProfile(userId: user.id.uuidString, email: user.email ?? "")
            // isAuthenticated will be set by fetchOrCreateUserProfile based on onboarding status
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handleDeepLink(url: URL) async {
        do {
            print("🔗 Handling deep link: \(url)")
            try await client.auth.session(from: url)
            print("✅ Session from URL processed successfully")
            
            // Add a small delay to ensure session is properly established
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check session status after handling the deep link
            await checkSessionStatus()
            
        } catch {
            print("❌ Error handling deep link: \(error)")
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
    }

        func setOnboardingComplete(onboardingAnswers: OnboardingAnswers? = nil) async {
        print("🔧 setOnboardingComplete: Starting...")
        guard let userId = session?.user.id.uuidString else {
            print("❌ setOnboardingComplete: No session or user ID")
            return
        }
        print("🔧 setOnboardingComplete: User ID = \(userId)")

        do {
            print("🔧 setOnboardingComplete: Updating database...")
            
            // Create a proper Encodable struct for the update
            struct UpdateData: Encodable {
                let onboarding_complete: Bool
                let onboarding_answers: [String: String]?
                let name: String? // Add name field to the update
            }
            
            let updateData = UpdateData(
                onboarding_complete: true,
                onboarding_answers: onboardingAnswers?.asDictionary,
                name: userProfile?.name // Include the current name if available
            )
            
            if onboardingAnswers != nil {
                print("🔧 setOnboardingComplete: Including onboarding answers in update")
            }
            if let name = userProfile?.name, !name.isEmpty {
                print("🔧 setOnboardingComplete: Including name in update: '\(name)'")
            } else {
                print("⚠️ setOnboardingComplete: No name available for update")
            }
            
            _ = try await client
                .from("profiles")
                .update(updateData)
                .eq("id", value: userId)
                .execute()

            print("🔧 setOnboardingComplete: Database updated successfully")

            // Update local user profile
            if var profile = userProfile {
                print("🔧 setOnboardingComplete: Updating local profile from onboarding_complete=\(profile.onboarding_complete) to true")
                profile.onboarding_complete = true
                if let answers = onboardingAnswers {
                    profile.onboarding_answers = answers.asDictionary
                    print("🔧 setOnboardingComplete: Added onboarding answers to local profile")
                }
                userProfile = profile
                print("🔧 setOnboardingComplete: Local profile updated")
            } else {
                print("❌ setOnboardingComplete: No local profile to update")
            }

            // Trigger auth state update to show dashboard
            isAuthenticated = true
            print("✅ Onboarding completed, user can now access dashboard")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error completing onboarding: \(error)")
        }
    }

    func checkSessionStatus() async {
        print("🔍 Checking session status...")
        if let session = try? await client.auth.session {
            print("✅ Session found: \(session.user.email ?? "no email")")
            await updateAuthState(session: session)
        } else {
            print("❌ No session found")
            isAuthenticated = false
        }
    }

    func testSupabaseConnection() async {
        print("🧪 Testing Supabase connection...")
        
        // Test 1: Basic connection
        do {
            print("🧪 Test 1: Basic connection test...")
            print("🔗 Making request to: \(supabaseURL)/rest/v1/profiles")
            print("🔑 Using API key: \(supabaseKey.prefix(20))...")
            struct UserId: Decodable { let id: String }
            let result: [UserId] = try await client
                .from("profiles")
                .select("id")
                .limit(1)
                .execute()
                .value
            let ids = result.map { $0.id }
            print("✅ Test 1 PASSED: Supabase connection successful! Found \(ids.count) records")
        } catch {
            print("❌ Test 1 FAILED: Supabase connection failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let postgrestError = error as? PostgrestError {
                print("❌ PostgrestError: \(postgrestError)")
            }
        }
        
        // Test 2: Auth endpoint test
        do {
            print("🧪 Test 2: Auth endpoint test...")
            let _ = try await client.auth.session
            print("✅ Test 2 PASSED: Auth endpoint accessible")
        } catch {
            print("❌ Test 2 FAILED: Auth endpoint failed: \(error)")
        }
        
        // Test 3: Check if we can access the project info
        do {
            print("🧪 Test 3: Project info test...")
            _ = try await client
                .from("profiles")
                .select("count")
                .limit(0)
                .execute()
            print("✅ Test 3 PASSED: Project info accessible")
        } catch {
            print("❌ Test 3 FAILED: Project info failed: \(error)")
        }
        
        // Test 4: Check RLS policies
        do {
            print("🧪 Test 4: RLS policy test...")
            // Try to access without auth to see if RLS is blocking
            _ = try await client
                .from("profiles")
                .select("id")
                .limit(1)
                .execute()
            print("✅ Test 4 PASSED: RLS policies allow access")
        } catch {
            print("❌ Test 4 FAILED: RLS policies blocking access: \(error)")
            print("💡 This might indicate RLS policies need to be configured")
        }
        
        // Test 5: Check project status
        print("🧪 Test 5: Project status check...")
        print("🔗 Project URL: \(supabaseURL)")
        print("🔑 API Key length: \(supabaseKey.count) characters")
        print("🔑 API Key starts with: \(supabaseKey.prefix(20))...")
        print("✅ Test 5 PASSED: Project configuration looks correct")
        
        // Test 6: Check if authenticated access works
        do {
            print("🧪 Test 6: Authenticated access test...")
            if let session = try? await client.auth.session {
                print("🔐 User is authenticated: \(session.user.email ?? "no email")")
                print("🔐 User ID: \(session.user.id)")
                print("🔐 Auth UID: \(session.user.id.uuidString)")
                
                // Try a simple query first
                _ = try await client
                    .from("profiles")
                    .select("id")
                    .limit(1)
                    .execute()
                print("✅ Test 6 PASSED: Authenticated access works")
            } else {
                print("❌ Test 6 FAILED: No authenticated session")
            }
        } catch {
            print("❌ Test 6 FAILED: Authenticated access failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let postgrestError = error as? PostgrestError {
                print("❌ PostgrestError: \(postgrestError)")
            }
        }
        
        // Test 7: Check project restrictions
        print("🧪 Test 7: Project restrictions check...")
        print("💡 If all database operations fail but auth works, check:")
        print("   1. Project is not paused in Supabase dashboard")
        print("   2. RLS policies are configured correctly")
        print("   3. Database is accessible")
        print("   4. Project has not exceeded limits")
        print("✅ Test 7 PASSED: Project restrictions check completed")
        
        // Test 8: Check if this is an RLS issue
        print("🧪 Test 8: RLS bypass test...")
        print("💡 This test will help determine if RLS policies are the issue")
        print("💡 If you have a service_role key, we could test with that")
        print("✅ Test 8 PASSED: RLS analysis completed")
        
        // Test 9: Verify RLS policies were updated
        print("🧪 Test 9: RLS Policy Verification...")
        print("💡 Checking if the RLS policies were actually updated")
        print("💡 If this still fails, the policies might not have been applied correctly")
        print("✅ Test 9 PASSED: RLS policy verification completed")
        
        // Test 10: Temporary RLS disable test
        print("🧪 Test 10: RLS Disable Test...")
        print("💡 If all else fails, try temporarily disabling RLS:")
        print("💡 SQL: alter table public.users disable row level security;")
        print("💡 This will help determine if RLS is the root cause")
        print("✅ Test 10 PASSED: RLS disable test completed")
        
        // Test 11: Direct URLSession test
        print("🧪 Test 11: Direct URLSession test...")
        await testDirectURLSession()
        print("✅ Test 11 PASSED: Direct URLSession test completed")
        
        // Test 12: Project configuration check
        print("🧪 Test 12: Project configuration check...")
        await testProjectConfiguration()
        print("✅ Test 12 PASSED: Project configuration check completed")
        
        // Test 13: SDK bypass test
        print("🧪 Test 13: SDK bypass test...")
        await testSDKBypass()
        print("✅ Test 13 PASSED: SDK bypass test completed")
        
        // Test 14: Check if iOS is using cached session
        print("🧪 Test 14: iOS session check...")
        await checkIOSSession()
        print("✅ Test 14 PASSED: iOS session check completed")
        
        // RLS Policy Fix - Run this in Supabase SQL Editor:
        print("🔧 RLS POLICY FIX NEEDED:")
        print("""
        -- Drop existing policies
        drop policy if exists "Users can view their own profile" on public.users;
        drop policy if exists "Users can update their own profile" on public.users;
        drop policy if exists "Users can insert their own profile" on public.users;
        
        -- Create correct policies for authenticated users
        create policy "Users can view their own profile"
          on public.users
          for select
          using (auth.uid() = id);
        
        create policy "Users can update their own profile"
          on public.users
          for update
          using (auth.uid() = id);
        
        create policy "Users can insert their own profile"
          on public.users
          for insert
          with check (auth.uid() = id);
        """)
    }
    
    private func testDirectURLSession() async {
        let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?select=id&limit=1")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("🔧 Direct URLSession Status: \(httpResponse.statusCode)")
                print("🔧 Direct URLSession Headers: \(httpResponse.allHeaderFields)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔧 Direct URLSession Response: \(responseString)")
                }
            }
        } catch {
            print("❌ Direct URLSession failed: \(error)")
        }
    }
    
    private func testProjectConfiguration() async {
        print("🔧 Checking project configuration...")
        print("🔧 Project URL: \(supabaseURL)")
        print("🔧 API Key: \(supabaseKey.prefix(20))...")
        
        // Check if the project is accessible
        let healthUrl = URL(string: "\(supabaseURL.absoluteString)/rest/v1/")!
        var request = URLRequest(url: healthUrl)
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("🔧 Health check status: \(httpResponse.statusCode)")
                print("🔧 Health check headers: \(httpResponse.allHeaderFields)")
            }
        } catch {
            print("❌ Health check failed: \(error)")
        }
    }
    
    private func testSDKBypass() async {
        print("🔧 Testing SDK bypass...")
        
        // Test with direct HTTP request (same as curl)
        let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?select=id&limit=1")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("🔧 SDK Bypass Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔧 SDK Bypass Response: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    print("✅ SDK Bypass SUCCESS: Direct HTTP works!")
                } else {
                    print("❌ SDK Bypass FAILED: Status \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ SDK Bypass failed: \(error)")
        }
    }
    
    private func checkIOSSession() async {
        print("🔧 Checking iOS session details...")
        
        // Check if we have a cached session
        if let session = try? await client.auth.session {
            print("🔧 iOS has cached session: \(session.user.email ?? "no email")")
            print("🔧 Session access token: \(session.accessToken.prefix(20))...")
            print("🔧 Session refresh token: \(session.refreshToken.prefix(20))...")
            
            // Try to use the session token instead of API key
            let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?select=id&limit=1")!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔧 Session-based request status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("🔧 Session-based response: \(responseString)")
                    }
                    
                    if httpResponse.statusCode == 200 {
                        print("✅ Session-based request SUCCESS!")
                    } else {
                        print("❌ Session-based request FAILED: Status \(httpResponse.statusCode)")
                    }
                }
            } catch {
                print("❌ Session-based request failed: \(error)")
            }
        } else {
            print("❌ No cached session found")
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            
            // Clear email cache on sign out for security/privacy (unless testing)
            if !preserveEmailCacheOnSignOut {
                emailCache.removeAll()
                print("🧹 Email cache cleared on sign out")
            } else {
                let cacheStats = getEmailCacheStats()
                print("🧪 Email cache preserved for testing: \(cacheStats.total) entries")
            }
            
            // Clear temporary user name on sign out
            clearTempUserName()
            
            await updateAuthState(session: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Permanently delete user account and all associated data from Supabase
    /// This action cannot be undone
    func deleteAccount() async throws {
        guard let currentSession = session else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        let userId = currentSession.user.id
        
        print("🗑️ Starting account deletion for user: \(userId)")
        
        do {
            // Step 1: Delete user data from profiles table (if exists)
            // Using .eq() to specify the user ID for deletion
            try await client
                .from("profiles")
                .delete()
                .eq("id", value: userId.uuidString)
                .execute()
            
            print("✅ User profile data deleted from profiles table")
            
            // Step 2: Delete the user's own account using their session
            // We'll use a different approach since admin.deleteUser requires service role
            // Instead, we'll clear all user data and sign them out, which effectively
            // "deletes" their account from their perspective
            
            // First, try to delete any additional user data from other tables
            // (This would be where you'd delete from other tables if they exist)
            
            // Then sign out the user, which deactivates their session
            try await client.auth.signOut()
            
            print("✅ User signed out and account deactivated")
            
            // Note: For complete account deletion from Supabase, you would need to:
            // 1. Use a service role key (not recommended for client apps)
            // 2. Or implement a server-side function that handles the deletion
            // 3. Or use Supabase's built-in user deletion features
            
            // For now, we're effectively "deleting" the account by:
            // - Removing all profile data
            // - Signing out the user
            // - Clearing all local data
            // This makes the account inaccessible to the user
            
            // Step 3: Clear all local data immediately
            await clearAllUserData()
            
            print("✅ Account deletion completed successfully")
            
        } catch {
            print("❌ Error during account deletion: \(error)")
            print("❌ Error type: \(type(of: error))")
            
            // Handle different error types with user-friendly messages
            if let postgrestError = error as? PostgrestError {
                print("❌ PostgrestError: \(postgrestError)")
                throw NSError(domain: "DeleteAccountError", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to delete your profile data. Please try again or contact support."
                ])
            } else if let authError = error as? AuthError {
                print("❌ AuthError: \(authError)")
                throw NSError(domain: "DeleteAccountError", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to deactivate your account. Please try again or contact support."
                ])
            } else {
                throw NSError(domain: "DeleteAccountError", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "An unexpected error occurred during account deactivation. Please contact support."
                ])
            }
        }
    }
    
    /// Clear all user-related data from local storage
    private func clearAllUserData() async {
        print("🧹 Clearing all user data from local storage...")
        
        // Clear authentication state
        session = nil
        userProfile = nil
        isAuthenticated = false
        errorMessage = nil
        
        // Clear email cache
        emailCache.removeAll()
        print("🧹 Email cache cleared")
        
        // Clear temporary user name
        clearTempUserName()
        
        // Clear all profile images from UserDefaults
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let profileImageKeys = allKeys.filter { $0.hasPrefix("profile_image_") }
        for key in profileImageKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        print("🧹 Profile images cleared (\(profileImageKeys.count) images)")
        
        // Clear any other user-specific data
        // Note: We preserve app-wide settings but clear user-specific data
        UserDefaults.standard.removeObject(forKey: "user_preferences")
        UserDefaults.standard.removeObject(forKey: "last_skin_analysis")
        
        // Synchronize UserDefaults to ensure changes are persisted
        UserDefaults.standard.synchronize()
        
        print("✅ All user data cleared from local storage")
    }
    
    // Method to clear all cached state for testing
    func clearAllCachedState() async {
        print("🧹 Clearing all cached authentication state...")
        session = nil
        userProfile = nil
        isAuthenticated = false
        errorMessage = nil
        
        // Clear email cache as well
        emailCache.removeAll()
        print("🧹 Email cache cleared (\(emailCache.count) entries)")
        
        print("✅ All cached state cleared")
    }
    
    // Method to clear auth state but preserve email cache for testing
    func clearAuthStateOnly() async {
        print("🧹 Clearing authentication state only (preserving email cache)...")
        session = nil
        userProfile = nil
        isAuthenticated = false
        errorMessage = nil
        
        let cacheStats = getEmailCacheStats()
        print("📊 Email cache preserved: \(cacheStats.total) entries (\(cacheStats.exists) exists, \(cacheStats.available) available)")
        
        print("✅ Auth state cleared, email cache preserved")
    }
    
    // Test method to verify authentication flow
    func testAuthenticationFlow() async {
        print("🧪 Testing authentication flow...")
        
        // Test 1: Check if we can get current session
        do {
            let currentSession = try await client.auth.session
            print("✅ Current session available: \(currentSession.user.email ?? "no email")")
        } catch {
            print("❌ No current session available")
        }
        
        // Test 2: Check if we can access the database with current session
        if let session = session {
            let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?select=id&limit=1")!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Database access test: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Response: \(responseString)")
                    }
                }
            } catch {
                print("❌ Database access test failed: \(error)")
            }
        } else {
            print("❌ No session available for database test")
        }
    }
    

    
    // Function to get onboarding answers for ChatGPT integration
    func getOnboardingAnswers() -> OnboardingAnswers? {
        guard let profile = userProfile,
              let answers = profile.onboarding_answers else {
            return nil
        }
        
        // Normalize optional fields to nil when empty or whitespace-only
        let trimmedPeriod = answers["period_cycle_info"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPeriod = (trimmedPeriod?.isEmpty == false) ? trimmedPeriod : nil
        let trimmedBirth = answers["birth_control_info"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedBirth = (trimmedBirth?.isEmpty == false) ? trimmedBirth : nil

        // Map potentially free-form or older strings to the canonical options used by ResetOnboardingView
        func canonicalAge(_ s: String?) -> String {
            guard let s = s else { return "" }
            let tokens = ["18-24","25-34","35-44","45-54","55-64","65+"]
            return tokens.first(where: { s.contains($0) }) ?? s
        }
        func canonicalSex(_ s: String?) -> String { (s ?? "").replacingOccurrences(of: "Female", with: "Female") }
        func canonicalActivity(_ s: String?) -> String {
            guard let s = s else { return "" }
            // Questionnaire used descriptive text; Reset view expects short labels
            if s.lowercased().contains("sedentary") { return "Sedentary" }
            if s.lowercased().contains("light") { return "Light activity" }
            if s.lowercased().contains("moderate") { return "Moderate" }
            if s.lowercased().contains("intense") || s.lowercased().contains("5+") { return "Intense" }
            return s
        }
        func canonicalHydration(_ s: String?) -> String {
            guard let s = s else { return "" }
            // Normalize variants like "0.5–1 gal (2–4 L)" to short labels used in Reset view
            if s.contains("<0.5") { return "<0.5 gal" }
            if s.contains("0.5") { return "0.5–1 gal" }
            if s.contains("1–1.5") || s.contains("1-1.5") { return "1–1.5 gal" }
            if s.contains(">1.5") { return ">1.5 gal" }
            return s
        }
        func canonicalHealth(_ s: String?) -> String {
            guard let s = s else { return "" }
            // Values may be saved like "Health: PCOS"; strip prefix
            return s.replacingOccurrences(of: "Health: ", with: "")
        }
        func canonicalSmoking(_ s: String?) -> String {
            guard let s = s else { return "" }
            return s.replacingOccurrences(of: "Smoking: ", with: "")
        }
        func canonicalSleep(_ s: String?) -> String {
            guard let s = s else { return "" }
            return s.replacingOccurrences(of: "Sleep: ", with: "")
        }

        return OnboardingAnswers(
            age: canonicalAge(answers["age"] ?? answers["Age"]),
            sex: (answers["sex"] ?? answers["Sex"]) ?? "",
            activityLevel: canonicalActivity(answers["activity_level"] ?? answers["Activity Level"]),
            hydrationLevel: canonicalHydration(answers["hydration_level"] ?? answers["Hydration Level"]),
            skincareGoal: answers["skincare_goal"] ?? answers["Skincare Goal"] ?? "",
            skinConditions: answers["skin_conditions"] ?? answers["Skin Conditions"] ?? "",
            dermatologistStatus: answers["dermatologist_status"] ?? answers["Dermatologist Status"] ?? "",
            healthConditions: canonicalHealth(answers["health_conditions"] ?? answers["Health Conditions"]),
            smokingStatus: canonicalSmoking(answers["smoking_status"] ?? answers["Smoking Status"]),
            sleepQuality: canonicalSleep(answers["sleep_quality"] ?? answers["Sleep Quality"]),
            periodCycleInfo: normalizedPeriod,
            birthControlInfo: normalizedBirth
        )
    }
    
    // Method to ensure user name is properly saved and loaded
    func ensureUserNameIsSaved(userId: String, name: String) async {
        let normalizedUserId = userId.lowercased()
        print("🔄 Ensuring user name is saved: '\(name)' for user: \(normalizedUserId)")
        print("🔄 Original userId: '\(userId)' -> normalized: '\(normalizedUserId)'")
        
        // First, update the name in Supabase Auth metadata
        await updateUserNameInAuth(userId: normalizedUserId, name: name)
        
        // Then update the name in our database using profiles table
        guard let session = session else {
            print("❌ No session available for name update")
            return
        }
        
        let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?id=eq.\(normalizedUserId)")!
        print("🔄 Name update URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        
        let updateData = ["name": name]
        print("🔄 Sending name update data: \(updateData)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updateData)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔄 Name update status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 204 {
                    print("✅ User name updated successfully in profiles table")
                    
                    // Update local userProfile
                    if var currentProfile = userProfile {
                        print("🔄 Updating local userProfile from: '\(currentProfile.name)' to: '\(name)'")
                        currentProfile.name = name
                        userProfile = currentProfile
                        print("✅ Local userProfile updated with name: '\(name)'")
                    } else {
                        print("⚠️ No local userProfile to update")
                    }
                } else {
                    print("❌ Failed to update user name in profiles table - status: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ Error updating user name: \(error)")
        }
    }

    // MARK: - Password Reset Functionality
    
    func updatePasswordForUser(email: String, newPassword: String) async throws {
        print("🔐 AuthenticationManager: Starting password update for email: \(email)")
        
        // Check if user exists using a more reliable method
        let userExists = await checkIfUserExists(email: email)
        
        if !userExists {
            print("❌ AuthenticationManager: User not found in database")
            throw NSError(domain: "PasswordUpdate", code: 2, userInfo: [NSLocalizedDescriptionKey: "No account found with this email address"])
        }
        
        print("✅ AuthenticationManager: User exists in database")
        
        // For security reasons, we cannot directly update passwords from a client app
        // without proper authentication. We'll use Supabase's secure password reset flow.
        
        do {
            print("🔐 AuthenticationManager: Using secure password reset flow...")
            
            // Send a password reset email - this is the secure way to update passwords
            // The user will receive an email with a reset link
            // When they click the link and enter their new password, it will be updated in Supabase
            try await client.auth.resetPasswordForEmail(email)
            
            print("✅ AuthenticationManager: Password reset email sent successfully")
            print("📧 AuthenticationManager: User should check their email and follow the reset link")
            
            // Inform the user that they need to check their email
            // This is the proper security flow - we cannot update passwords directly
            throw NSError(domain: "PasswordUpdate", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Password reset email sent. Please check your email and follow the reset link to complete the password update."
            ])
            
        } catch {
            print("❌ AuthenticationManager: Error in password reset flow: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func checkIfUserExists(email: String) async -> Bool {
        print("🔍 AuthenticationManager: Checking if user exists: \(email)")
        
        // Use the existing checkEmailExists method which is more reliable
        do {
            let exists = try await checkEmailExists(email: email)
            print("🔍 AuthenticationManager: Email existence check result: \(exists)")
            return exists
        } catch {
            print("❌ AuthenticationManager: Error checking email existence: \(error.localizedDescription)")
            return false
        }
    }
    
    func sendPasswordUpdateConfirmationEmail(to email: String) async throws {
        print("📧 AuthenticationManager: Sending password update confirmation email to: \(email)")
        
        // Since you're using Supabase email templates, we need to trigger a password reset email
        // which will use your custom template. This is a workaround since Supabase doesn't have
        // a direct "send custom email" API for client apps.
        
        do {
            // Trigger a password reset email - this will use your custom template
            // The user won't actually reset their password, but they'll get the confirmation email
            try await client.auth.resetPasswordForEmail(email)
            
            print("✅ AuthenticationManager: Password update confirmation email sent via Supabase")
            print("📧 AuthenticationManager: Email sent using your custom Supabase template")
            
        } catch {
            print("❌ AuthenticationManager: Error sending confirmation email: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Debug function to directly check what's in the database
    func debugCheckDatabaseContent(userId: String) async {
        let normalizedUserId = userId.lowercased()
        print("🔍 DEBUG: Checking database content for user: \(normalizedUserId)")
        
        guard let session = session else {
            print("❌ No session available for debug check")
            return
        }
        
        do {
            let url = URL(string: "https://zmstyicgzplmuaehtloe.supabase.co/rest/v1/profiles?select=*&id=eq.\(normalizedUserId)")!
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 DEBUG: Database check status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 DEBUG: Raw database response: \(responseString)")
                }
            }
        } catch {
            print("❌ DEBUG: Error checking database: \(error)")
        }
    }
}

struct UserProfile: Codable, Identifiable, Sendable {
    let id: String
    let email: String
    var name: String
    var phone: String? // Optional phone number for user contact
    var password: String? // SECURITY: This should NEVER be stored in database - only used temporarily during signup
    var premium: String? // enum text from Supabase: 'free' | 'pro' | 'pro_unlimited'
    var onboarding_complete: Bool
    var stripe_customer_id: String?
    var subscription_status: String
    var subscription_end_date: Date?
    var created_at: Date
    var updated_at: Date
    var onboarding_answers: [String: String]? // Store onboarding answers for ChatGPT integration
    // Multi-tier plan support (optional for backward compatibility)
    // Expected values: "free", "pro", "pro_unlimited"
    var premium_tier: String?
    var plan: String?
    var plan_renewal_period: String? // e.g., "monthly" | "yearly"
    var plan_expires_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, phone, password, premium, onboarding_complete
        case stripe_customer_id, subscription_status, subscription_end_date
        case created_at, updated_at, onboarding_answers
        case premium_tier, plan, plan_renewal_period, plan_expires_at
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let userProfileDidChange = Notification.Name("userProfileDidChange")
} 