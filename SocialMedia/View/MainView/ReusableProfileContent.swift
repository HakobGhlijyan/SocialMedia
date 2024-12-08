//
//  ReusableProfileContent.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/8/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct ReusableProfileContent: View {
    let user: User
    let url: String = "https://picsum.photos/id/237/200/300"
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                //1
                HStack(spacing: 12) {
                    WebImage(url: URL(string: url)) { image in
//                        Image("NullProfile")
//                            .resizable()
                        image.image?.resizable()
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())

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
                    .foregroundStyle(.black)
                    .hAlign(.leading)
                    .padding(.vertical, 15)
            }
            .padding(15)
        }
    }
}

#Preview {
    ReusableProfileContent(
        user: User(
            username: "Hakob",
            userBio: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
            userBioLink: "https://github.com/HakobGhlijyan",
            userUID: "007",
            userEmail: "hakob@hakob.com"
        )
    )
}

//ex photo 1. web and 2. apple asyncimage
/*
     //This only image load , not work
     WebImage(url: URL(string: url)) { image in
         Image("NullProfile")
             .resizable()
//                        image
//                            .image?.resizable()
     }
     .scaledToFill()
     .frame(width: 100, height: 100)
     .clipShape(Circle())
     
     AsyncImage(url: URL(string: url)) { image in
         Image("NullProfile")
             .resizable()
//                        image
//                            .resizable()
     } placeholder: {
         
     }
     .scaledToFill()
     .frame(width: 100, height: 100)
     .clipShape(Circle())
     
 */

//2
/*
 HStack(spacing: 12) {
     AsyncImage(url: URL(string: url)) { image in
//                        Image("NullProfile")
//                            .resizable()
         image
             .resizable()
     } placeholder: {
         
     }
     .scaledToFill()
     .frame(width: 100, height: 100)
     .clipShape(Circle())
     
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
 */
