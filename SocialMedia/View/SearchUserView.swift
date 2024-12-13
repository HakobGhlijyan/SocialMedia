//
//  SearchUserView.swift
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

struct SearchUserView: View {
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(fetchedUsers) { user in
                NavigationLink {
                    ReusableProfileContent(user: user)
                } label: {
                    Text(user.username)
                        .font(.callout)
                        .hAlign(.leading)
                }
            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search User")
        .searchable(text: $searchText)
        .onSubmit(of: .search) {
            //Fetch User from firebase
            Task { await searchUsers() }
        }
        .onChange(of: searchText) { oldValue, newValue in
            if newValue.isEmpty {
                fetchedUsers = []
            }
        }
    }
    
    func searchUsers() async {
        do {
            let documents = try await Firestore.firestore().collection("SocialMedia_Users")
                .whereField("username", isGreaterThanOrEqualTo: searchText)
                .whereField("username", isLessThanOrEqualTo: "\(searchText)\u{f8ff}")
                .getDocuments()
            
            let users = try documents.documents.compactMap { document -> User? in
                try document.data(as: User.self)
            }
            // updateUI
            await MainActor.run {
                fetchedUsers = users
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    SearchUserView()
}
