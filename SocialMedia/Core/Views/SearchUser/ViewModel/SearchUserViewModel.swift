//
//  SearchUserViewModel.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/13/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

final class SearchUserViewModel: ObservableObject {
    @Published var fetchedUsers: [User] = []
    @Published var searchText: String = ""
    
    func searchUsers() async {
        do {
            let documents = try await FirestoreConstants.userRef
                .whereField("username", isGreaterThanOrEqualTo: searchText)
                .whereField("username", isLessThanOrEqualTo: "\(searchText)\u{f8ff}")
                .getDocuments()
            
            let users = try documents.documents.compactMap { document -> User? in
                try document.data(as: User.self)
            }
            await MainActor.run {
                fetchedUsers = users
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
