//
//  SearchUserView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/13/24.
//

import SwiftUI

struct SearchUserView: View {
    @StateObject private var vm: SearchUserViewModel = SearchUserViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(vm.fetchedUsers) { user in
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
        .searchable(text: $vm.searchText)
        .onSubmit(of: .search) {
            Task { await vm.searchUsers() }
        }
        .onChange(of: vm.searchText) { oldValue, newValue in
            if newValue.isEmpty {
                vm.fetchedUsers = []
            }
        }
    }
    
    
}

#Preview {
    SearchUserView()
}
