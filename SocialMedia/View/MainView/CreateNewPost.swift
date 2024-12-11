//
//  CreateNewPost.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/10/24.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import FirebaseDatabase

struct CreateNewPost: View {
    // - CallBack
    var onPost: (Post) -> ()
    // - Post Properties
    @State private var postText: String = ""
    @State private var postImageData: Data?
    // - Stored User Data From UserDefaults (AppStorage)
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    // - View Properties
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    // - Photo Picker and hide keyboard
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var showKeyboard: Bool
    
    var body: some View {
        VStack {
            HStack {
                Menu {
                    Button("Cancel", role: .destructive) { dismiss() }
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundStyle(.black)
                }
                .hAlign(.leading)
                
                Button {
                    createPost()
                } label: {
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(.black, in: Capsule())
                }
                .disablingWithOpacity(postText == "")
                
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                Rectangle()
                    .fill(.gray.opacity(0.1))
                    .ignoresSafeArea()
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    TextField("What's happening?", text: $postText, axis: .vertical)
                        .focused($showKeyboard)
                    
                    if let postImageData, let image = UIImage(data: postImageData) {
                        GeometryReader {
                            let size = $0.size
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: size.width, height: size.height)
                                .clipShape(.rect(cornerRadius: 10, style: .continuous))
                            //Delete selected image
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            self.postImageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .bold()
                                            .tint(.red)
                                    }
                                    .padding(10)
                                }
                            
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                }
                .padding(15)
            }
            Divider()
            HStack {
                Button {
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                }
                .hAlign(.leading)

                Button("Done") {
                    showKeyboard = false
                }
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            
        }
        .vAlign(.top)
        //For PhotoPicker
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { oldValue, newValue in
            if let newValue {
                Task {
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: rawImageData), let compressedImageData = image.jpegData(compressionQuality: 0.5) {
                        await MainActor.run {
                            postImageData = compressedImageData
                            photoItem = nil
                        }
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError) {
            //
        }
        .overlay {
            LoadingView(show: $isLoading)
        }
    }
    // MARK: Post Content To Firebase
    func createPost(){
        isLoading = true
        showKeyboard = false
        Task {
            do {
                guard let profileURL = profileURL else { return }
                // Step: 1 - Uploading Image If any
                // Used to delete the Post(Later shown in the Video)
                let imageReferenceID = "\(userUID)\(Date())"
                let storageRef = Storage.storage().reference().child("Post_Images").child(imageReferenceID)
                if let postImageData {
                    print("Post and Image Uploaded started")
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    
                    // Step 3: Create Post Object With Image Id And URL
                    // Создайте Объект Публикации С Идентификатором Изображения И URL-Адресом
                    let post = Post(
                        text: postText,
                        imageURL: downloadURL,
                        imageReferenceID: imageReferenceID,
                        userName: userName,
                        userUID: userUID,
                        userProfileURL: profileURL
                    )
                    try await createDocumentAtFirebase(post)
                    print("Post and Image Uploaded")
                } else {
                    print("Post start")
                    // Step 2: - Directly Post Text Data to Firebase (Since there is no Images Present)
                    // Непосредственно отправляйте текстовые данные в Firebase (поскольку там нет изображений)
                    let post = Post(
                        text: postText,
                        userName: userName,
                        userUID: userUID,
                        userProfileURL: profileURL
                    )
                    try await createDocumentAtFirebase(post)
                    print("Post")
                }
            } catch {
                print("error")
                print(error.localizedDescription)
                await setError(error)
            }
        }
    }

    func createDocumentAtFirebase(_ post: Post) async throws {
        // Writing Document to Firebase Firestore
        // Запись документа в Firebase Firestore
        let _ = try Firestore.firestore().collection("Posts").addDocument(from: post, completion: { error in
            if error == nil {
                // Post Successfully Stored at Firebase
                // Сообщение успешно сохранено в Firebase
                isLoading = false
                onPost(post)
                dismiss()
            } else {
                print("Error Save Post document")
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    func setError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            showError.toggle()
        }
    }
}

#Preview {
    CreateNewPost { _ in
        
    }
}
