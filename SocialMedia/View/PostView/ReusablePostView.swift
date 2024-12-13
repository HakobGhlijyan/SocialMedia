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
    @State private var isFetching: Bool = true
    @State private var paginationDoc: QueryDocumentSnapshot?
    var basedOnUID: Bool = false
    var uid: String = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                if isFetching {
                    ProgressView()
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
            guard !basedOnUID else { return }
            isFetching = true
            posts = []
            paginationDoc = nil
            await fetchPosts()
            print("FETCH NEW POST'S refreshable ")
        }
        .task {
            guard posts.isEmpty else { return }
            await fetchPosts()
            print("FETCH NEW POST'S TASK")
        }
    }
    
    @ViewBuilder func Posts() -> some View {
        ForEach(posts) { post in
            PostCardView(post: post) { updatedPost in
                if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs
                }
            } onDelete: {
                withAnimation(.bouncy(duration: 0.25)) {
                    posts.removeAll(where: { post.id == $0.id })
                }
            }
            .onAppear {
                if post.id == posts.last?.id && paginationDoc != nil {
                    Task {
                        await fetchPosts()
                        print("FETCH NEW POST'S , Pagination Doc")
                    }
                }
            }
            
            Divider()
                .padding(.horizontal, 5)
                .padding(.bottom, 15)
        }
    }
    
    func fetchPosts() async {
        print("FETCH POST")
        do {
            var query: Query
            
            if let paginationDoc {
                query = Firestore.firestore().collection("SocialMedia_Posts")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            } else {
                query = Firestore.firestore().collection("SocialMedia_Posts")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
            }
            if basedOnUID {
                query = query
                    .whereField("userUID", isEqualTo: uid)
            }
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            await MainActor.run {
                posts.append(contentsOf: fetchedPosts)
                paginationDoc = docs.documents.last
                isFetching = false
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    RootView()
}
