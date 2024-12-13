//
//  PostsView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/10/24.
//

import SwiftUI

struct PostsView: View {
    @State private var createdNewPost: Bool = false
    @State private var recentPost: [Post] = []
    
    var body: some View {
        NavigationStack {
            ReusablePostView(posts: $recentPost)
                .hAlign(.center).vAlign(.center)
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        createdNewPost.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(15)
                            .background(.black, in: .circle)
                    }
                    .padding(15)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SearchUserView()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .tint(.black)
                                .scaleEffect(0.9)
                        }
                    }
                }
                .navigationTitle("Post's")
        }
        .fullScreenCover(isPresented: $createdNewPost) {
            CreateNewPostView { post in
                recentPost.insert(post, at: 0)
            }
        }
    }
}

#Preview {
    PostsView()
}
