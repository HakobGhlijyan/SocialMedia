//
//  FirestoreConstants.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/13/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import FirebaseStorageCombineSwift
import FirebaseDatabase

struct FirestoreConstants {
    static let postImagesRef = Storage
        .storage()
        .reference()
        .child("SocialMedia_Post_Images")
    
    static let profileImagesRef = Storage
        .storage()
        .reference()
        .child("SocialMedia_Profile_Images")
    
    static let postRef = Firestore
        .firestore()
        .collection("SocialMedia_Posts")
    
    static let userRef = Firestore
        .firestore()
        .collection("SocialMedia_Users")
    
}
