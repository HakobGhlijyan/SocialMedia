//
//  ReusablePostView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/12/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import FirebaseDatabase

struct ReusablePostView: View {
    @Binding var posts: [Post]
    @State private var isFetching: Bool = true                  //For first is see progress view ->
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                if isFetching {
                    ProgressView()                               // this , after task isfetching in fetchPost func false
                        .padding(.top, 30)
                } else {
                    if posts.isEmpty {
                        Text("No Post's Found")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(.top, 30)
                    } else {
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            //refresh all post
            //1: is fetch enable for progressview see
            isFetching = true
            //2: all post array delete
            posts = []
            //3: try again fetch
            await fetchPosts()
        }
        .task {
            //Fetching for one time
            guard posts.isEmpty else { return }
            await fetchPosts()
        }
    }
    
    //Fetched Post
    @ViewBuilder func Posts() -> some View {
        ForEach(posts) { post in
            PostCardView(post: post) { updatedPost in
                //updating post
                //1: - esli index raven v post pervomu elementu po id kotoriy raven id updated post . to ->
                if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
                    //2: - >
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs
                }
            } onDelete: {
                //removing post
                withAnimation(.bouncy(duration: 0.25)) {
                    posts.removeAll(where: { post.id == $0.id }) // Udalenie post po id
                }
            }
            Divider()
                .padding(.horizontal, 5)
                .padding(.bottom, 15)
        }
    }
    
    //Fetch Post Firebase
    func fetchPosts() async {
        do {
            //1: - Query
            var query: Query
            query = Firestore.firestore().collection("SocialMedia_Posts")
                .order(by: "publishedDate", descending: true)
                .limit(to: 10)
            //2: - Documents
            let docs = try await query.getDocuments()
            //3: - Fetch all post in compact map , deleted nil... and doc -> Post model, in: -> doc decode data for Post
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            //4: - Update UI
            await MainActor.run {
                posts = fetchedPosts
                isFetching = false
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    ContentView()
}
