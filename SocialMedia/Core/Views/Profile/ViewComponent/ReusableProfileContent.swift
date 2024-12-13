//
//  ReusableProfileContent.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/8/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct ReusableProfileContent: View {
    @StateObject private var vm: ProfileViewModel = ProfileViewModel()
    let user: User
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                HStack(spacing: 12) {
                    WebImage(url: user.userProfileURL) { image in
                        image
                    } placeholder: {
                        Image("NullProfile")
                            .resizable()
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
//                    AsyncImage(url: URL(string: url)) { image in
//                        image
//                            .resizable()
//                    } placeholder: {
//                        Image("NullProfile")
//                            .resizable()
//                    }
//                    .scaledToFill()
//                    .frame(width: 100, height: 100)
//                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text(user.username)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(user.userBio)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                        
                        if let bioLink = URL(string: user.userBioLink) {
                            Link(user.userBioLink, destination: bioLink)
                                .font(.callout)
                                .tint(.blue)
                                .lineLimit(1)
                        }
                    }
                }
                .hAlign(.leading)
            
                Text("Post's")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .hAlign(.leading)
                    .padding(.vertical, 15)
                
                ReusablePostView(
                    posts: $vm.fetchedPosts,
                    basedOnUID: true,
                    uid: user.userUID
                )
                
            }
            .padding(15)
        }
    }
}
