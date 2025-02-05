import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var profileImage: Image?
    @State private var isEditMode: Bool = false
    
    var body: some View {
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
                
                Spacer()
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            loadUserProfile()
        }
    }
    
    private func loadUserProfile() {
        // TODO: Implement profile loading from Firebase
        if let user = Auth.auth().currentUser {
            username = user.displayName ?? ""
            // Load other user data from Firestore
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
} 