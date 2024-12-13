//
//  SocialMediaApp.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 15.11.2024.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

@main
struct SocialMediaApp: App {
    init() {
        FirebaseApp.configure()
        print("FireBase Configure Now")
        print("FireBase Configure Now")
        print("FireBase Configure Now")
        print("FireBase Configure Now")
    }
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
