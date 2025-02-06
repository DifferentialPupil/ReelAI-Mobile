import Foundation
import FirebaseAuth
import Combine

enum AuthenticationError: LocalizedError {
    case signInError(String)
    case signOutError(String)
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .signInError(let message):
            return "Failed to sign in: \(message)"
        case .signOutError(let message):
            return "Failed to sign out: \(message)"
        case .userNotFound:
            return "No user is currently signed in"
        }
    }
}

@MainActor
class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateHandler()
    }
    
    private func setupAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
        } catch {
            throw AuthenticationError.signInError(error.localizedDescription)
        }
    }
    
    func signUp(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
        } catch {
            throw AuthenticationError.signInError(error.localizedDescription)
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            throw AuthenticationError.signOutError(error.localizedDescription)
        }
    }
    
    func getCurrentUser() throws -> User {
        guard let user = Auth.auth().currentUser else {
            throw AuthenticationError.userNotFound
        }
        return user
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
} 