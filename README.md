# GitHubRepoExplorer

GitHubRepoExplorer is a modern iOS application built with Swift and SwiftUI that allows users to browse public GitHub repositories, explore detailed repository information, and bookmark favorites for offline reference. It demonstrates a robust **MVVM-Coordinator** architecture with a service-oriented design, comprehensive unit tests, and automated UI tests.

---

## Features

- **Infinite Scrolling**: Browse public GitHub repositories with seamless pagination.
- **Dynamic Grouping**: Group repositories by owner type, fork status, language, or star count.
- **Advanced Navigation**: Uses the **Coordinator pattern** to manage deep-linkable and testable navigation flows.
- **Rich Details**: View enriched information including stars, forks, open issues, and primary language.
- **Local Persistence**: Bookmark repositories for offline access using **SwiftData**.
- **Persistent Detail Cache**: Repository details (stars, forks, etc.) are cached on disk with a configurable Time-To-Live (TTL), reducing redundant network calls.
- **Real-time Synchronization**: Bookmark state and repository data are synchronised across all screens via Combine subjects.
- **Smart Image Caching**: Custom-built image caching system to reduce network traffic and improve scrolling performance.
- **Connectivity Monitoring**: Real-time network status tracking with global alerts for offline states.
- **iPad Optimised**: Adaptive UI designed to work beautifully on both iPhone and iPad.
- **Polished UX**: Smooth collapse/expand animations and optimised touch targets for a native feel.

---

## Development Environment

- **Xcode**: 26.5
- **Swift**: 5
- **iOS Deployment Target**: 18.6+
- **Architecture**: MVVM-Coordinator

---

## Third-Party Dependencies

This project has **zero third-party dependencies** by design. All core functionalities are implemented using Apple's first-party frameworks:

| Framework       | Usage                                                 |
| --------------- | ----------------------------------------------------- |
| **SwiftUI**     | Declarative UI and view-level state management        |
| **SwiftData**   | Modern local persistence and bookmark storage         |
| **Combine**     | Reactive data streams between services and ViewModels |
| **Network**     | Connectivity monitoring via `NWPathMonitor`           |
| **Observation** | Modern `@Observable` state tracking (iOS 17+)         |

---

## Code Structure

```
GitHubRepoExplorer/
├── Features/
│   ├── RepoList/             # Grouped list view + pagination logic
│   ├── RepoDetail/           # Enriched repository detail screen
│   └── BookmarkList/         # Local bookmark management
├── Navigation/
│   ├── Coordinator.swift     # Protocol-based navigation definition
│   ├── AppCoordinator.swift  # Main flow orchestrator
│   └── ...                   # Feature-specific coordinators
├── Services/
│   ├── GitHubService.swift   # REST API client with DTO-to-Domain mapping
│   ├── BookmarkService.swift # Local business logic & sync
│   ├── Persistence/          # SwiftData service & SDRepository models
│   ├── ImageCache/           # Custom memory-efficient image loading
│   └── Networking/           # Generic NetworkClient & DTO definitions
├── Models/                   # Pure business logic domain models
├── Mocks/                    # Comprehensive mocks for hermetic testing
└── DependencyManager/        # Environment-based Dependency Injection
```

---

## Architecture

### MVVM-Coordinator

The app uses a decoupled architecture that prioritises testability and separation of concerns:

- **Coordinators**: Own the navigation state (`NavigationPath`) and the lifecycle of ViewModels. They decouple views from the navigation hierarchy.
- **ViewModels**: Marked with **`@MainActor`** and **`@Observable`**. They manage UI-specific logic, subscribe to background services, and provide clean data to the views.
- **Service Layer**: Foundation of the app. Services are responsible for data fetching, persistence, and broadcasting updates via Combine.
- **DTO Decoupling**: Networking models (DTOs) are strictly separated from domain models. `GitHubService` handles the mapping, ensuring API changes don't leak into the UI.

### Dependency Injection

Dependencies are managed through a centralised **`DependencyContainer`**, provided to the view hierarchy via the SwiftUI **`Environment`**. This allows for easy swapping of real services with mocks during unit and UI testing.

---

## Core Technical Strategies

### Dynamic Grouping

To provide a more organised browsing experience, the app supports multiple grouping modes:

- **Owner Type**: Distinguishes between User and Organization repositories.
- **Fork Status**: Separates original projects from forks.
- **Language**: Groups by the primary programming language.
- **Star Count (Star Bands)**: Instead of raw numbers, repositories are grouped into meaningful "Star Bands" (e.g., `1000+ ★`, `100–999 ★`, `10–99 ★`). This gives users an immediate sense of project popularity at a glance.

### Cursor-Based Pagination

The app implements the **GitHub Link Header** specification for pagination.

- Rather than calculating page numbers manually, the app follows the absolute "next" URL provided by the GitHub API.
- This ensures a robust "Infinite Scroll" experience where subsequent data is fetched only as the user nears the end of the list, preventing data duplication and optimizing network usage.

### Graceful Error Handling

The app employs a two-tier error handling strategy:

- **Global Alerts**: Uses **`NWPathMonitor`** to detect connectivity loss in real-time. If the device goes offline, a global alert is presented to inform the user.
- **Inline List Banners**: Non-fatal errors, such as hitting the GitHub API rate limit, are displayed as an inline banner within the repository list. This allows users to still interact with already-loaded data while providing a clear "Retry" action for the failed request.

---

## Testing

### Unit Testing (Swift Testing Framework)

The project utilises the modern **Swift Testing** framework (Xcode 16+) for fast, deterministic, and parallel execution:

- **ViewModel Tests**: Verify state transitions, service integration, and reactive updates.
- **Service Tests**: Ensure business logic, error mapping, and cache expiry work correctly.
- **Network Tests**: Use **`URLProtocol`** interception to verify the `NetworkClient` without hitting the internet.
- **DTO Tests**: Validate parsing logic against real GitHub API JSON samples.

### UI Testing (XCUITest)

End-to-end UI tests cover critical user journeys:

- Tap-based navigation and tab switching.
- Complete bookmarking flow (Add -> Verify -> Remove).
- Infinite scroll triggering and pagination verification.
- Grouping logic and collapsible header interaction.

---

## Known Limitations

### GitHub API Rate Limiting

The GitHub public API is unauthenticated and subject to a **60 requests/hour** limit. Since fetching detail for each repository (stars, forks, language, etc.) requires a separate API call per repository, fetching detail for a full page of 100 repositories would immediately exhaust the entire hourly limit.

Currently, the app fetches details lazily when a user navigates to a repository's detail screen, or for the visible set when grouping by Stars/Language is active.

---

## Future Improvements

**1. Lazy Detail Fetching for Visible Rows Only**
To optimise quota usage, a planned improvement is to fetch details only for rows currently visible on screen. This would use `onAppear`/`onDisappear` combined with a debounce mechanism to ensure only repositories the user actually pauses on consume the rate limit.

**2. GitHub Authentication**
Adding support for GitHub Personal Access Tokens (PAT) would raise the rate limit from 60 to 5,000 requests/hour. This would make background pre-fetching for the entire list viable and improve the overall "out-of-the-box" experience.

**3. Background Sync for Bookmarks**
A planned enhancement is to automatically pre-fetch and store the full `RepositoryDetail` for any bookmarked repository in the background. This would ensure that even if a repository was bookmarked while the details were unknown, the app will eventually make them available for offline viewing.

**4. Contacts-style Index Bar**
The current grouped list becomes hard to navigate when many sections are present. An alphabetical index bar on the right edge (similar to the iOS Contacts app) would allow users to jump directly to specific sections.

**5. Adaptive iPad Layouts**
Implementing **`NavigationSplitView`** to make better use of iPad screen real estate. This would allow the repository list to stay visible in a primary column while the detail view updates in the secondary area.

**6. Dependency Injection with Swinject**
While the current hand-rolled `DependencyContainer` works well, migrating to [Swinject](https://github.com/Swinject/Swinject) would provide better scope management (singleton, transient, graph) and clearer assembly-based registration as the app scales.

---

## AI Assistance

This project was developed with the assistance of **Gemini CLI**, focusing on:

- Architectural design and SOLID principle enforcement.
- Implementation of modern Swift structured concurrency and actor isolation.
- Test strategy optimisation (Deterministic async waiting vs. sleeps).
- UI/UX polish and accessibility tree refinement.

---
