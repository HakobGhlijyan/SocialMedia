//
//  ContentView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 15.11.2024.
//

import SwiftUI

struct RootView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
        if logStatus {
            MainView()
        } else {
            LoginView()
        }        
    }
}

#Preview {
    RootView()
}
