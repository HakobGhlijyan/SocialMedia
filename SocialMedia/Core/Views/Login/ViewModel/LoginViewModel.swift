//
//  LoginViewModel.swift
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

final class LoginViewModel: ObservableObject {
    let appStorage = AppStorageConstants.shared
    @Published var emailID: String = ""
    @Published var password: String = ""
    @Published var createAccount: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
 
    func loginUser() {
        isLoading = true
        closeKeyBoard()
        Task {
            do {
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User Found")
                try await fetchUser()
            } catch {
                await setError(error)
            }
        }
    }
    
    func fetchUser() async throws {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let user = try await FirestoreConstants.userRef.document(userID).getDocument(as: User.self)
        
        await MainActor.run {
            appStorage.userUID = userID
            appStorage.userNameStored = user.username
            appStorage.profileURL = user.userProfileURL
            appStorage.logStatus = true
        }
    }
    
    func setError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        }
    }
    
    func resetPassword() {
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("Password Reset , LINK Sent Email")
            } catch {
                await setError(error)
            }
        }
    }
    
    func closeKeyBoard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
