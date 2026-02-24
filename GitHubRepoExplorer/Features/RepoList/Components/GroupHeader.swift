//
//  GroupHeader.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 24/02/2026.
//

import SwiftUI

struct GroupHeader: View {
    let group: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(group)
                .font(.headline)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    return GroupHeader(group: "Organisation", count: 10)
}
