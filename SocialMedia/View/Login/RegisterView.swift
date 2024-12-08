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
            .disablingWithOpacity(isEmptyNoPic())
        }
    }
    
    private func isEmpty() -> Bool {
        userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil
    }
    private func isEmptyNoPic() -> Bool {
        userName == "" || userBio == "" || emailID == "" || password == ""
    }
    
     func registerUser() {
         isLoading = true
         closeKeyBoard()
         Task {
             do {
                 // Step 1: Creating Firebase Account
                 try await Auth.auth().createUser(withEmail: emailID, password: password)
                 
                 //Step 2: Uploading Profile Photo Into Firebase Storage
                 guard let userUID = Auth.auth().currentUser?.uid else { return }
                 /*
                  Enable only Storage , not work
                  guard let imageData = userProfilePicData else { return }
                  */
                 
                 //Enable only Storage , not work
                 /*
                  //Step 2.1: Storage for image
                  let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                  let _ = try await storageRef.putDataAsync(imageData)
                  
                  //Step 3: downloading Photo URL
                  let downloadURL = try await storageRef.downloadURL()
                  */
                
                 //Step 4: Creating a User Firebase Objects - Add Image
                 /*
                  let user = User(
                      username: userName,
                      userBio: userBio,
                      userBioLink: userBioLink,
                      userUID: userUID,
                      userEmail: emailID,
                      userProfileURL: downloadURL
                  )
                  */
                 //Step 4: Creating a User Firebase Objects - NO Add Image
                 let user = User(
                     username: userName,
                     userBio: userBio,
                     userBioLink: userBioLink,
                     userUID: userUID,
                     userEmail: emailID
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
                            //Enable only Storage , not work
                            /*
                             profileURL = downloadURL
                            */
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
    ContentView()
}


//Mock data log in
/*
 Hakob
 Sam
 
 hakob@hakob.com
 sam@sam.com
 
 Qq1234567890
 
 Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
 
 https://github.com/HakobGhlijyan
 */
