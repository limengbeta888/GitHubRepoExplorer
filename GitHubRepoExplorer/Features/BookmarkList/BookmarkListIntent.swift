//
//  BookmarkListIntent.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

enum BookmarkListIntent {

    // User actions
    case bookmark(Repository)
    case removeBookmark(Repository)

    // System events
    case loadBookmarks
    case bookmarksLoaded([Repository])      // persistence returned the data
    case updateEnriched([Repository])       // called when detail fetch enriches a bookmarked repo
}
