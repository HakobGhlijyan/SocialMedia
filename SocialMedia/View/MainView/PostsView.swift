//
//  PostsView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/10/24.
//

import SwiftUI

struct PostsView: View {
    @State private var createdNewPost: Bool = false
    
    var body: some View {
        Text("Posts View")
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
            .fullScreenCover(isPresented: $createdNewPost) {
                CreateNewPost { post in
                    
                }
            }
    }
}

#Preview {
    PostsView()
}

//Start Module 04
