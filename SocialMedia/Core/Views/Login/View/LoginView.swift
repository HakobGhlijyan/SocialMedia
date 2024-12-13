//
//  LoginView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 15.11.2024.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var vm: LoginViewModel = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 10.0) {
            sectionHeader()
            VStack(spacing: 12.0) {
                sectionTextField()
                sectionButton()
            }
            sectionBottom()
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $vm.isLoading)
        })
        .fullScreenCover(isPresented: $vm.createAccount) {
            RegisterView()
        }
        .alert(vm.errorMessage, isPresented: $vm.showError) {}
    }
}

#Preview {
    LoginView()
}

extension LoginView {
    @ViewBuilder func sectionHeader() -> some View {
        VStack {
            Text("Let's Sign you in")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Welcome Back, \nYou have been missed")
                .font(.title3)
                .hAlign(.leading)
        }
    }
    
    @ViewBuilder func sectionTextField() -> some View {
        VStack {
            TextField("Email", text: $vm.emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .padding(.top, 25)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            SecureField("Password", text: $vm.password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }
    
    @ViewBuilder func sectionButton() -> some View {
        VStack {
            Button("Reset Password ?") {
                vm.loginUser()
            }
            .font(.callout)
            .fontWeight(.medium)
            .tint(.black)
            .hAlign(.trailing)
            
            Button {
                vm.loginUser()
            } label: {
                Text("Sign In")
                    .foregroundStyle(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .padding(.top, 10)
        }
    }
    
    @ViewBuilder func sectionBottom() -> some View {
        HStack {
            Text("Don't have an account?")
                .foregroundStyle(.gray)
            
            Button("Register Now") {
                vm.createAccount.toggle()
            }
            .bold()
            .foregroundStyle(.black)
        }
        .font(.callout)
        .vAlign(.bottom)
    }
}
