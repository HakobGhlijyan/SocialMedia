//
//  User.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/6/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var userBio: String
    var userBioLink: String
    var userUID: String
    var userEmail: String
    var userProfileURL: URL
    
    enum CodingKeys: CodingKey {
        case id
        case username
        case userBio
        case userBioLink
        case userUID
        case userEmail
        case userProfileURL
    }
}
