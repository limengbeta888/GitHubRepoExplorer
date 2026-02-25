//
//  AppEventBus.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 25/02/2026.
//

// AppEventBus.swift

import Combine

/// The proper way to communicate between independent stores without coupling them is a shared event stream.
/// Each store publishes domain events, other stores subscribe to the ones they care about. No store holds a reference to another.

enum AppEvent {
    case bookmarkToggled(Repository, isBookmarked: Bool)
    case repositoryEnriched(Repository)
}

@MainActor
final class AppEventBus {
    static let shared = AppEventBus()
    
    let events = PassthroughSubject<AppEvent, Never>()
    
    private init() {}
}
