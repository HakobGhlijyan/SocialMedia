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
                
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
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
//            profileURL = user.userProfileURL //Only Storage enable
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
    
    // MARK: UserDefaults
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
                    } catch {
                    //
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError) {
            //
        }
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
            
            SecureField("Password", text: $password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextEditor(text: $userBio)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                        
            TextField("Bio Link", text: $userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            Button {
                registerUser()
            } label: {
                Text("Sign up")
                    .foregroundStyle(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .padding(.top, 10)
            .disablingWithOpacity(isEmptyNoPic())
        }
    }
    
    private func isEmpty() -> Bool {
        userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil
    }
    private func isEmptyNoPic() -> Bool {
        userName == "" || userBio == "" || emailID == "" || password == ""
    }
    
    //StorageEnable
    /*
     func registerUser() {
         isLoading = true
         closeKeyBoard()
         Task {
             do {
                 // Step 1: Creating Firebase Account
 //                let user = try await Auth.auth().createUser(withEmail: emailID, password: password)
                 try await Auth.auth().createUser(withEmail: emailID, password: password)
                 
                 //Step 2: Uploading Profile Photo Into Firebase Storage
                 guard let userUID = Auth.auth().currentUser?.uid else { return }
                 guard let imageData = userProfilePicData else { return }
                 
                 //Step 2.1: Storage for image
                 let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                 let _ = try await storageRef.putDataAsync(imageData)
                 
                 //Step 3: downloading Photo URL
                 let downloadURL = try await storageRef.downloadURL()
                 
                 //Step 4: Creating a User Firebase Objects
                 let user = User(
                     username: userName,
                     userBio: userBio,
                     userBioLink: userBioLink,
                     userUID: userUID,
                     userEmail: emailID,
                     userProfileURL: downloadURL
                 )
                 
                 //Step 5: Saving User Doc into Firestore Database
                 let _ = try Firestore
                     .firestore()
                     .collection("Users")
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
                 // Deleting Created Acount in case of Failure
                 // Потому что это приведет к удалению уже существующего пользователя, добавленного по ошибке. //20.30...
                 await setError(error)
             }
         }
     }
     */
    //Storage Disable
    func registerUser() {
        isLoading = true
        closeKeyBoard()
        Task {
            do {
                // Step 1: Creating Firebase Account
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                
                //Step 2: Uploading Profile Photo Into Firebase Storage
                guard let userUID = Auth.auth().currentUser?.uid else { return }
//                guard let imageData = userProfilePicData else { return }
                
                //Step 2.1: Storage for image
//                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
//                let _ = try await storageRef.putDataAsync(imageData)
                
                //Step 3: downloading Photo URL
//                let downloadURL = try await storageRef.downloadURL()
                
                //Step 4: Creating a User Firebase Objects
                let user = User(
                    username: userName,
                    userBio: userBio,
                    userBioLink: userBioLink,
                    userUID: userUID,
                    userEmail: emailID,
                    userProfileURL: nil
                )
                
                /*
                 Hakob
                 
                 hakob@hakob.com
                 
                 Qq1234567890
                 
                 Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
                 
                 https://github.com/HakobGhlijyan
                 */
                
                //Step 5: Saving User Doc into Firestore Database
                let _ = try Firestore
                    .firestore()
                    .collection("Users")
                    .document(userUID)
                    .setData(from: user) { error in
                        if error == nil {
                            print("Saved Successfully")
                            userNameStored = userName
                            self.userUID = userUID
                            logStatus = true
                        }
                    }
                
            } catch {
                // Deleting Created Acount in case of Failure
                // Потому что это приведет к удалению уже существующего пользователя, добавленного по ошибке. //20.30...
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

//MARK: - UI design Helper function
extension View {
    func hAlign(_ alignment: Alignment) -> some View {
        self.frame(maxWidth: .infinity, alignment: alignment)
    }
    
    func vAlign(_ alignment: Alignment) -> some View {
        self.frame(maxHeight: .infinity, alignment: alignment)
    }
}

//MARK: - UI design Custom Border And FillView
extension View {
    func border(_ width: CGFloat, _ color: Color) -> some View {
        self
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(color, lineWidth: width)
            }
    }
    
    func fillView(_ color: Color) -> some View {
        self
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color)
            }
    }
}

//MARK: - Disabling with Opacity
extension View {
    func disablingWithOpacity(_ condition: Bool) -> some View {
        self.disabled(condition).opacity(condition ? 0.6 : 1)
    }
}

//MARK: - Closing All Active Keyboards
extension View {
    func closeKeyBoard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
