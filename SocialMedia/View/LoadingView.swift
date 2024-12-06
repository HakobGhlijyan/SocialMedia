//
//  LoadingView.swift
//  SocialMedia
//
//  Created by Hakob Ghlijyan on 12/6/24.
//

import SwiftUI

struct LoadingView: View {
    @Binding var show: Bool
    
    var body: some View {
        ZStack {
            if show {
                Group {
                    Rectangle()
                        .fill(.black.opacity(0.25))
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .padding(15)
                        .background(.white, in: .rect(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .animation(.bouncy, value: show)
    }
}
