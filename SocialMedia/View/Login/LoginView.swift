//
//  LoginView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 15.11.2024.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

struct LoginView: View {
    @State private var emailID: String = ""
    @State private var password: String = ""
    @State private var createAccount: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    // MARK: UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        VStack(spacing: 10.0) {
            Text("Let's Sign you in")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Welcome Back, \nYou have been missed")
                .font(.title3)
                .hAlign(.leading)
            
            VStack(spacing: 12.0) {
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top, 25)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                Button("Reset Password ?") {
                    loginUser()
                }
                .font(.callout)
                .fontWeight(.medium)
                .tint(.black)
                .hAlign(.trailing)
                
                Button {
                    loginUser()
                } label: {
                    Text("Sign In")
                        .foregroundStyle(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .padding(.top, 10)
            }
            
            HStack {
                Text("Don't have an account?")
                    .foregroundStyle(.gray)
                
                Button("Register Now") {
                    createAccount.toggle()
                }
                .bold()
                .foregroundStyle(.black)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        .alert(errorMessage, isPresented: $showError) {
            //
        }
    }
    
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
    
    //MARK: If User if Found then Fetching User Data From Firestore
    func fetchUser() async throws {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        
        await MainActor.run {
            userUID = userID
            userNameStored = user.username
            /*
             Only Storage enable
             profileURL = user.userProfileURL
             */
            logStatus = true
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
                print("Password Reset Sent")
            } catch {
                await setError(error)
            }
        }
    }
}

#Preview {
    LoginView()
}
