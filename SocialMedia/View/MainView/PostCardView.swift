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
    var post: Post
    //CallBack
    var onUpdate: (Post) -> ()
    var onDelete: () -> ()
    @AppStorage("user_UID") var userUID: String = ""
    @State private var docListener: ListenerRegistration? // For Live Update
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            //1
            WebImage(url: post.userProfileURL)
                .resizable()
                .scaledToFill()
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            //2
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
                
                //Post Image...
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
            //remove button , if its autor this post
            if post.userUID == userUID {
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
            //Adding only Once
            if docListener == nil {
                guard let postID = post.id else { return }
                docListener = Firestore
                    .firestore()
                    .collection("SocialMedia_Posts")
                    .document(postID)
                    .addSnapshotListener({ snapshot, error in
                        if let snapshot {
                            if snapshot.exists {  // exists -> true, если документ существует
                                //Doc Update
                                //fetch updated doc
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
            // Applying Snapshot Linstener only when the post is Available on screen
            // Esle Removing the Listener (It saves unwanted live update frome the posts which was swiped away from the screen)
            // Применяем средство создания моментальных снимков только тогда, когда запись доступна на экране
            // После удаления прослушивателя (это сохраняет нежелательные обновления в реальном времени из записей, которые были удалены с экрана)
            if let docListener {
                docListener.remove()
                self.docListener = nil
            }
        }
    }
    
    //Like / Dislike Interaction
    @ViewBuilder func PostInteraction() -> some View {
        HStack(spacing: 6) {
            Button {
                likePost()
            } label: {
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundStyle(.gray)
            
            Button {
                dislikePost()
            } label: {
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }.padding(.leading, 25)
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .foregroundStyle(.black)
        .padding(.vertical, 8)
    }
    
    //Like Post
    private func likePost() {
        Task {
            //1: ID
            guard let postID = post.id else { return }
            //2:
            if post.likedIDs.contains(userUID) {
                //Remove UserID in array liked post
                try await Firestore.firestore().collection("SocialMedia_Posts")
                    .document(postID)
                    .updateData(["likedIDs": FieldValue.arrayRemove([userUID])])
            } else {
                //Adding UserID in array liked post
                try await Firestore.firestore().collection("SocialMedia_Posts")
                    .document(postID)
                    .updateData(["likedIDs": FieldValue.arrayUnion([userUID]), "dislikedIDs": FieldValue.arrayRemove([userUID])])
            }
        }
    }
    
    //DisLike Post
    private func dislikePost() {
        Task {
            //1: ID
            guard let postID = post.id else { return }
            //2:
            if post.dislikedIDs.contains(userUID) {
                //Remove UserID in array liked post
                try await Firestore.firestore().collection("SocialMedia_Posts")
                    .document(postID)
                    .updateData(["dislikedIDs": FieldValue.arrayRemove([userUID])])
            } else {
                //Adding UserID in array liked post
                try await Firestore.firestore().collection("SocialMedia_Posts")
                    .document(postID)
                    .updateData(["likedIDs": FieldValue.arrayRemove([userUID]), "dislikedIDs": FieldValue.arrayUnion([userUID])])
            }
        }
    }
    
    //Delete Post
    private func deletePost() {
        Task {
            //Step 1: delete Image firebase id present
            do {
                if post.imageReferenceID != "" {
                    try await Storage.storage().reference().child("SocialMedia_Post_Images")
                        .child(post.imageReferenceID).delete()
                }
                //Step 2: Delete firestore document
                guard let postID = post.id else { return }
                try await Firestore.firestore().collection("SocialMedia_Posts")
                    .document(postID).delete()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
}
