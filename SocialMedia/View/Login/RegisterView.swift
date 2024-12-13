//
//  RegisterView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/8/24.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

struct RegisterView: View {
    @State private var emailID: String = ""
    @State private var password: String = ""
    @State private var userName: String = ""
    @State private var userBio: String = ""
    @State private var userBioLink: String = ""
    @State private var userProfilePicData: Data?
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(spacing: 10.0) {
            Text("Let's Register\nAccount")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Hello user, have a wonderful journey")
                .font(.title3)
                .hAlign(.leading)
            
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false) {
                    HelperView()
                }
                HelperView()
            }
            
            HStack {
                Text("Already have an account?")
                    .foregroundStyle(.gray)
                
                Button("Login Now") {
                    dismiss()
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
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { oldValue, newValue in
            if let newValue {
                Task {
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else { return }
                        await MainActor.run {
                            userProfilePicData = imageData
                        }
                    } catch { }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError) {}
    }
    
    @ViewBuilder func HelperView() -> some View {
        VStack(spacing: 12.0) {
            ZStack {
                if let userProfilePicData , let image = UIImage(data: userProfilePicData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image("NullProfile")
                        .resizable()
                        .scaledToFill()
                        .background(.red)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top, 25)
            
            TextField("User Name", text: $userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            SecureField("Password", text: $password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            TextEditor(text: $userBio)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Bio Link", text: $userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            Button {
                registerUser()
            } label: {
                Text("Sign up")
                    .foregroundStyle(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .padding(.top, 10)
            .disablingWithOpacity(isEmpty())
        }
    }
    
    private func isEmpty() -> Bool {
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
                
                let storageRef = Storage.storage().reference().child("SocialMedia_Profile_Images").child(userUID)
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
                
                let _ = try Firestore
                    .firestore()
                    .collection("SocialMedia_Users")
                    .document(userUID)
                    .setData(from: user) { error in
                        if error == nil {
                            print("Saved Successfully")
                            userNameStored = userName
                            self.userUID = userUID
                            profileURL = downloadURL
                            logStatus = true
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
}

#Preview {
    RootView()
}
