//
//  PostCardView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/12/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import FirebaseDatabase

struct PostCardView: View {
    let appStorage = AppStorageConstants.shared
    var post: Post
    var onUpdate: (Post) -> ()
    var onDelete: () -> ()
    @State private var docListener: ListenerRegistration?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: post.userProfileURL)
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .clipShape(Circle())
//            AsyncImage(url: post.userProfileURL) { image in
//                image.image?.resizable()
//            }
//            .scaledToFill()
//            .frame(width: 35, height: 35)
//            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical, 8)
                
                if let postImageURL = post.imageURL {
                    GeometryReader { geometry in
                        //1
                        WebImage(url: postImageURL)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipShape(.rect(cornerRadius: 10, style: .continuous))
                        //2
//                        AsyncImage(url: postImageURL) { image in
//                            image.image?.resizable()
//                        }
//                        .scaledToFill()
//                        .frame(width: geometry.size.width, height: geometry.size.height)
//                        .clipShape(.rect(cornerRadius: 10, style: .continuous))
                        
                    }
                    .frame(height: 200)
                }
                
                PostInteraction()
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            if post.userUID == appStorage.userUID {
                Menu {
                    Button("Delete Post", role: .destructive) {
                        deletePost()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.degrees(-90))
                        .foregroundStyle(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)

            }
        })
        .onAppear {
            if docListener == nil {
                guard let postID = post.id else { return }
                docListener = Firestore
                    .firestore()
                    .collection("SocialMedia_Posts")
                    .document(postID)
                    .addSnapshotListener({ snapshot, error in
                        if let snapshot {
                            if snapshot.exists {
                                if let updatePost = try? snapshot.data(as: Post.self) {
                                    onUpdate(updatePost)
                                }
                            } else {
                                onDelete()
                            }
                        }
                    })
                
            }
        }
        .onDisappear {
            if let docListener {
                docListener.remove()
                self.docListener = nil
            }
        }
    }
    
    @ViewBuilder func PostInteraction() -> some View {
        HStack(spacing: 6) {
            Button {
                likePost()
            } label: {
                Image(systemName: post.likedIDs.contains(appStorage.userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundStyle(.gray)
            
            Button {
                dislikePost()
            } label: {
                Image(systemName: post.dislikedIDs.contains(appStorage.userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }.padding(.leading, 25)
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .foregroundStyle(.black)
        .padding(.vertical, 8)
    }
    
    private func likePost() {
        Task {
            guard let postID = post.id else { return }
            if post.likedIDs.contains(appStorage.userUID) {
                try await Firestore.firestore().collection("SocialMedia_Posts")
                    .document(postID)
                    .updateData(["likedIDs": FieldValue.arrayRemove([appStorage.userUID])])
            } else {
                try await Firestore.firestore().collection("SocialMedia_Posts")
                    .document(postID)
                    .updateData(["likedIDs": FieldValue.arrayUnion([appStorage.userUID]), "dislikedIDs": FieldValue.arrayRemove([appStorage.userUID])])
            }
        }
    }
    
    private func dislikePost() {
        Task {
            guard let postID = post.id else { return }
            if post.dislikedIDs.contains(appStorage.userUID) {
                try await Firestore.firestore().collection("SocialMedia_Posts")
                    .document(postID)
                    .updateData(["dislikedIDs": FieldValue.arrayRemove([appStorage.userUID])])
            } else {
                try await Firestore.firestore().collection("SocialMedia_Posts")
                    .document(postID)
                    .updateData(["likedIDs": FieldValue.arrayRemove([appStorage.userUID]), "dislikedIDs": FieldValue.arrayUnion([appStorage.userUID])])
            }
        }
    }
    
    private func deletePost() {
        Task {
            do {
                if post.imageReferenceID != "" {
                    try await Storage.storage().reference().child("SocialMedia_Post_Images")
                        .child(post.imageReferenceID).delete()
                }
                guard let postID = post.id else { return }
                try await Firestore.firestore().collection("SocialMedia_Posts")
                    .document(postID).delete()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
}
