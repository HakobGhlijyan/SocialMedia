//
//  ProfileViewModel.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/13/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

final class ProfileViewModel: ObservableObject {
    let appStorage = AppStorageConstants.shared
    @Published var myProfile: User?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    @Published var fetchedPosts: [Post] = []

    func logOutUser() {
        do {
            try Auth.auth().signOut()
            appStorage.logStatus = false
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteAccount() {
        Task {
            isLoading = true
            do {
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                let storageRef = FirestoreConstants.profileImagesRef.child(userUID)
                try await storageRef.delete()
                try await FirestoreConstants.userRef.document(userUID).delete()
                try await Auth.auth().currentUser?.delete()
                appStorage.logStatus = false
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
        guard let user = try? await FirestoreConstants.userRef.document(userUID).getDocument(as: User.self) else { return }
        await MainActor.run {
            myProfile = user
        }
    }

}

