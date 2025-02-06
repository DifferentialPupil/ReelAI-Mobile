import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var profileImage: Image?
    @State private var isEditMode: Bool = false
    
    // Authentication form states
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                authenticatedView
            } else {
                authenticationView
            }
        }
        .onChange(of: authService.isAuthenticated) { newValue in
            if newValue {
                loadUserProfile()
            } else {
                // Reset form states when logged out
                email = ""
                password = ""
                username = ""
                bio = ""
                isEditMode = false
            }
        }
    }
    
    private var authenticatedView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    if let profileImage = profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)
                
                // Username
                if isEditMode {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                } else {
                    Text(username.isEmpty ? "Username" : username)
                        .font(.title2)
                        .bold()
                }
                
                // Bio
                if isEditMode {
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                } else {
                    Text(bio.isEmpty ? "No bio yet" : bio)
                        .foregroundColor(bio.isEmpty ? .gray : .primary)
                        .padding(.horizontal)
                }
                
                // Edit Button
                Button(action: {
                    withAnimation {
                        isEditMode.toggle()
                    }
                }) {
                    Text(isEditMode ? "Save" : "Edit Profile")
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                // Sign Out Button
                Button(action: {
                    do {
                        try authService.signOut()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }) {
                    Text("Sign Out")
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Profile")
    }
    
    private var authenticationView: some View {
        VStack(spacing: 20) {
            Text(isSignUp ? "Create Account" : "Sign In")
                .font(.title)
                .bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                Task {
                    do {
                        if isSignUp {
                            try await authService.signUp(withEmail: email, password: password)
                        } else {
                            try await authService.signIn(withEmail: email, password: password)
                        }
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: {
                isSignUp.toggle()
                errorMessage = ""
            }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadUserProfile() {
        do {
            let user = try authService.getCurrentUser()
            username = user.email ?? ""
            bio = "Gauntlet AI Challenger"
            // Load other user data from Firestore
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
} 
