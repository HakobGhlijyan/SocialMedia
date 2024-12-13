//
//  RegisterViewModel.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/13/24.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

final class RegisterViewModel: ObservableObject {
    let appStorage = AppStorageConstants.shared
    @Published var emailID: String = ""
    @Published var password: String = ""
    @Published var userName: String = ""
    @Published var userBio: String = ""
    @Published var userBioLink: String = ""
    @Published var userProfilePicData: Data?
    @Published var showImagePicker: Bool = false
    @Published var photoItem: PhotosPickerItem?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    func isEmpty() -> Bool {
        userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil
    }
    
    func registerUser() {
        isLoading = true
        closeKeyBoard()
        Task {
            do {
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                guard let imageData = userProfilePicData else { return }
                
                let storageRef = FirestoreConstants.profileImagesRef.child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                
                let downloadURL = try await storageRef.downloadURL()
                
                let user = User(
                    username: userName,
                    userBio: userBio,
                    userBioLink: userBioLink,
                    userUID: userUID,
                    userEmail: emailID,
                    userProfileURL: downloadURL
                )
                
                let _ = try FirestoreConstants.userRef
                    .document(userUID)
                    .setData(from: user) { error in
                        if error == nil {
                            print("Saved Successfully")
                            self.appStorage.userNameStored = self.userName
                            self.appStorage.userUID = userUID
                            self.appStorage.profileURL = downloadURL
                            self.appStorage.logStatus = true
                        }
                    }
            } catch {
                await setError(error)
            }
        }
    }
    
    func setError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        }
    }
    
    func closeKeyBoard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
