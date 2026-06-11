//
//  AvatarView.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 11/06/2026.
//

import SwiftUI

struct AvatarView: View {
    let urlString: String?
    let size: CGFloat
    
    @Environment(\.dependencyContainer) private var container
    @State private var loader = ImageLoader()
    
    var body: some View {
        Group {
            if let uiImage = loader.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if loader.isLoading {
                placeholder
                    .overlay(ProgressView().scaleEffect(0.6))
            } else {
                placeholder
                    .overlay(Image(systemName: "person").foregroundStyle(.white))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
        .task(id: urlString) {
            await loader.load(from: URL(string: urlString ?? ""), 
                            cache: container.imageCache)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: size * 0.25)
            .fill(Color.secondary.opacity(0.3))
    }
}

// MARK: - Previews

#Preview("States") {
    HStack(spacing: 16) {
        AvatarView(urlString: "https://avatars.githubusercontent.com/u/1?v=4", size: 60)
        AvatarView(urlString: nil, size: 60)
        AvatarView(urlString: "bad-url", size: 60)
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    AvatarView(urlString: "https://avatars.githubusercontent.com/u/1?v=4", size: 60)
        .padding()
        .preferredColorScheme(.dark)
}
