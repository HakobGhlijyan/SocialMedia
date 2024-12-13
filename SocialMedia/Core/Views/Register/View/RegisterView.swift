//
//  RegisterView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/8/24.
//

import SwiftUI
import PhotosUI

struct RegisterView: View {
    @StateObject private var vm: RegisterViewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 10.0) {
            sectionHeader()
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false) {
                    HelperView()
                }
                HelperView()
            }
            sectionBottom()
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $vm.isLoading)
        })
        .photosPicker(isPresented: $vm.showImagePicker, selection: $vm.photoItem)
        .onChange(of: vm.photoItem) { oldValue, newValue in
            if let newValue {
                Task {
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else { return }
                        await MainActor.run {
                            vm.userProfilePicData = imageData
                        }
                    } catch { }
                }
            }
        }
        .alert(vm.errorMessage, isPresented: $vm.showError) {}
    }
    
    
}

#Preview {
    RootView()
}

extension RegisterView {
    @ViewBuilder func sectionHeader() -> some View {
        Text("Let's Register\nAccount")
            .font(.largeTitle.bold())
            .hAlign(.leading)
        
        Text("Hello user, have a wonderful journey")
            .font(.title3)
            .hAlign(.leading)
    }
    
    @ViewBuilder func HelperView() -> some View {
        VStack(spacing: 12.0) {
            sectionImage()
            sectionTextField()
            sectionButton()
        }
    }
    
    @ViewBuilder func sectionImage() -> some View {
        ZStack {
            if let userProfilePicData = vm.userProfilePicData , let image = UIImage(data: userProfilePicData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("NullProfile")
                    .resizable()
                    .scaledToFill()
                    .background(.red)
            }
        }
        .frame(width: 85, height: 85)
        .clipShape(Circle())
        .contentShape(Circle())
        .onTapGesture {
            vm.showImagePicker.toggle()
        }
        .padding(.top, 25)
    }
    
    @ViewBuilder func sectionTextField() -> some View {
        VStack(spacing: 12) {
            TextField("User Name", text: $vm.userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Email", text: $vm.emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            SecureField("Password", text: $vm.password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            TextEditor(text: $vm.userBio)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Bio Link", text: $vm.userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }
    
    @ViewBuilder func sectionButton() -> some View {
        Button {
            vm.registerUser()
        } label: {
            Text("Sign up")
                .foregroundStyle(.white)
                .hAlign(.center)
                .fillView(.black)
        }
        .padding(.top, 10)
        .disablingWithOpacity(vm.isEmpty())
    }
    
    @ViewBuilder func sectionBottom() -> some View {
        HStack {
            Text("Already have an account?")
                .foregroundStyle(.gray)
            
            Button("Login Now") {
                dismiss()
            }
            .bold()
            .foregroundStyle(.black)
        }
        .font(.callout)
        .vAlign(.bottom)
    }
}
