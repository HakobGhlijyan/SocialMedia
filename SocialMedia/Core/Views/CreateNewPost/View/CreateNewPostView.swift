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

struct CreateNewPostView: View {
    let appStorage = AppStorageConstants.shared
    var onPost: (Post) -> ()
    @State private var postText: String = ""
    @State private var postImageData: Data?
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
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
                }
                .hAlign(.leading)
                .foregroundStyle(.primary)
                
                Button {
                    createPost()
                } label: {
                    Text("Post")
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(.gray, in: Capsule())
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
            .foregroundStyle(.primary)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            
        }
        .vAlign(.top)
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
        .alert(errorMessage, isPresented: $showError) {}
        .overlay {
            LoadingView(show: $isLoading)
        }
    }

    func createPost(){
        isLoading = true
        showKeyboard = false
        Task {
            do {
                guard let profileURL = appStorage.profileURL else { return }

                let imageReferenceID = "\(appStorage.userUID)\(Date())"
                let storageRef = FirestoreConstants.postImagesRef.child(imageReferenceID)
                if let postImageData {
                    print("Post and Image Uploaded started")
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    
                    let post = Post(
                        text: postText,
                        imageURL: downloadURL,
                        imageReferenceID: imageReferenceID,
                        userName: appStorage.userNameStored,
                        userUID: appStorage.userUID,
                        userProfileURL: profileURL
                    )
                    try await createDocumentAtFirebase(post)
                    print("Post and Image Uploaded")
                } else {
                    print("Post start")
                    let post = Post(
                        text: postText,
                        userName: appStorage.userNameStored,
                        userUID: appStorage.userUID,
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
        let doc = FirestoreConstants.postRef.document()
        let _ = try doc.setData(from: post, completion: { error in
            if error == nil {
                isLoading = false
                var updatedPost = post
                updatedPost.id = doc.documentID
                onPost(updatedPost)
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
    CreateNewPostView { _ in
        
    }
}
