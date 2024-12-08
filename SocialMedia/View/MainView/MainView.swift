//
//  MainView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/8/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            Text("Recent Post's")
                .tabItem {
                    Label("Post's", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "gear")
                }
        }
        .tint(.black)
    }
}

#Preview {
    ContentView()
}
