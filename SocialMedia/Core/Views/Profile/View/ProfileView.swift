//
//  ProfileView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/8/24.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var vm: ProfileViewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if let myProfile = vm.myProfile {
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            vm.myProfile = nil
                            await vm.fetchUserProfile()
                        }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Log Out", action: vm.logOutUser)
                        Button("Delete Acount", role: .destructive, action: vm.deleteAccount)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
            .overlay {
                LoadingView(show: $vm.isLoading)
            }
            .alert(vm.errorMessage, isPresented: $vm.showError) {}
            .task {
                if vm.myProfile != nil { return }
                await vm.fetchUserProfile()
            }
        }
    }

}

#Preview {
    ProfileView()
}
