//
//  ProfileView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/8/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

struct ProfileView: View {
    @State private var myProfile: User?
    @AppStorage("log_status") var logStatus: Bool = false
    
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let myProfile {
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            self.myProfile = nil
                            await fetchUserProfile()
                        }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Log Out", action: logOutUser)
                        Button("Delete Acount", role: .destructive, action: deleteAccount)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
            .overlay {
                LoadingView(show: $isLoading)
            }
            .alert(errorMessage, isPresented: $showError) {}
            .task {
                if myProfile != nil { return }
                await fetchUserProfile()
            }
        }
    }
    
    func logOutUser() {
        do {
            try Auth.auth().signOut()
            logStatus = false
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteAccount() {
        Task {
            isLoading = true
            do {
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                let storageRef = Storage.storage().reference().child("SocialMedia_Profile_Images").child(userUID)
                try await storageRef.delete()
                try await Firestore.firestore().collection("SocialMedia_Users").document(userUID).delete()
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            } catch {
                await setError(error)
            }
        }
    }
    
    func setError(_ error: Error) async {
        await MainActor.run {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        }
    }
    
    func fetchUserProfile() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        guard let user = try? await Firestore.firestore().collection("SocialMedia_Users").document(userUID).getDocument(as: User.self) else { return }
        await MainActor.run {
            myProfile = user
        }
    }
}

#Preview {
    ProfileView()
}
