//
//  AvatarView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 24/02/2026.
//

import SwiftUI

struct AvatarView: View {

    let urlString: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder.overlay(ProgressView().scaleEffect(0.6))
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder.overlay(Image(systemName: "person").foregroundStyle(.white))
                    @unknown default:
                        placeholder.overlay(Image(systemName: "person").foregroundStyle(.white))
                    }
                }
            } else {
                placeholder.overlay(Image(systemName: "person").foregroundStyle(.white))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: size * 0.25)
            .fill(Color.secondary.opacity(0.3))
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarView(urlString: "https://avatars.githubusercontent.com/u/1?v=4", size: 44)
        AvatarView(urlString: nil, size: 44)
        AvatarView(urlString: "bad-url", size: 44)
    }.padding()
}
