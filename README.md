# GitHubRepoExplorer

GitHubRepoExplorer is an iOS app built with Swift and SwiftUI that lets users browse public GitHub repositories, explore rich repository details, and bookmark favourites for offline reference. It demonstrates a clean MVI architecture with a service-oriented design, comprehensive unit tests, and UI tests.

---

## Features

- Browse public GitHub repositories with infinite scroll pagination
- Group repositories by owner type, fork status, language, or star count
- Collapsible section groups for focused browsing
- View detailed repository information — stars, forks, open issues, language, and owner type
- Bookmark repositories locally using SwiftData persistence
- Swipe-to-bookmark and swipe-to-remove from both the repo list and bookmarks tab
- Real-time bookmark sync across all screens via Combine subjects
- Open any repository directly in Safari
- Pull-to-refresh on the repo list
- Graceful error handling with inline banners and retry actions

---

## Development Environment

- Xcode: 26.2
- Swift: 5
- iOS Deployment Target: 17.6
- Architecture: MVI (Model–View–Intent)

---

## Third-Party Dependencies

This project has **zero third-party dependencies** by design. All networking, persistence, image loading, and reactive state management are handled using Apple frameworks only:

| Framework | Usage |
|-----------|-------|
| SwiftUI | Declarative UI |
| Combine | Reactive state propagation between services and stores |
| SwiftData | Local bookmark persistence |
| Foundation | Networking, URL parsing, JSON decoding |

---

## Code Structure

```
GitHubRepoExplorer/
├── GitHubRepoExplorer/
│   ├── Core/
│   │   ├── Configurations/
│   │   │   ├── APIConfig.swift                  # API protocol definition
│   │   │   └── GitHubAPIConfig.swift            # GitHub-specific base URL & headers
│   │   ├── DependencyManager/
│   │   │   └── DependencyContainer.swift        # App-wide dependency injection container
│   │   ├── Networking/
│   │   │   ├── Endpoints/
│   │   │   │   ├── Endpoint.swift               # Endpoint protocol definition
│   │   │   │   └── PublicRepoEndpoint.swift     # GitHub public repo endpoint implementations
│   │   │   ├── NetworkClient.swift              # Generic async/await network client
│   │   │   ├── NetworkError.swift               # Typed network error enum
│   │   │   └── NetworkResponse.swift            # Wraps decoded body + pagination headers
│   │   ├── Persistence/
│   │   │   ├── SwiftDataModels/
│   │   │   │   └── RepositoryModel.swift        # SwiftData @Model for bookmarks
│   │   │   └── PersistenceService.swift         # Pure SwiftData CRUD operations
│   │   └── Utils/
│   │       └── LinkHeaderParser.swift           # Parses GitHub Link header for pagination URLs
│   │
│   ├── Features/
│   │   ├── BookmarkList/
│   │   │   ├── BookmarkListIntent.swift         # User intents (load, remove)
│   │   │   ├── BookmarkListReducer.swift        # Pure state reducer
│   │   │   ├── BookmarkListState.swift          # View state definition
│   │   │   ├── BookmarkListStore.swift          # MVI store + BookmarkService subscriptions
│   │   │   └── BookmarkListView.swift           # SwiftUI list with swipe-to-remove
│   │   │
│   │   ├── RepoDetail/
│   │   │   ├── Components/
│   │   │   │   └── RepoInfoCard.swift           # Stat card (stars, forks, language etc.)
│   │   │   ├── RepoDetailIntent.swift           # User intents (load, toggle bookmark)
│   │   │   ├── RepoDetailReducer.swift          # Pure state reducer
│   │   │   ├── RepoDetailState.swift            # View state (phase, isBookmarked)
│   │   │   ├── RepoDetailStore.swift            # MVI store + lazy detail fetch
│   │   │   └── RepoDetailView.swift             # Stats grid, header, open-in-browser
│   │   │
│   │   └── RepoList/
│   │       ├── RepoListIntent.swift             # User intents (load, paginate, group, bookmark)
│   │       ├── RepoListReducer.swift            # Pure state reducer
│   │       ├── RepoListState.swift              # View state + grouping computed properties
│   │       ├── RepoListStore.swift              # MVI store + pagination + visibility tracking
│   │       └── RepoListView.swift               # Collapsible grouped list + toolbar
│   │
│   ├── Mocks/
│   │   ├── MockBookmarkService.swift            # In-memory bookmark service for tests
│   │   ├── MockGitHubService.swift              # Configurable mock (success/error/rateLimit)
│   │   ├── MockModels.swift                     # Static Repository/RepositoryDetail fixtures
│   │   ├── MockNetworkClient.swift              # Mock HTTP client
│   │   ├── MockPersistenceService.swift         # In-memory SwiftData replacement
│   │   ├── MockRepositoryUpdateService.swift    # Mock enrichment publisher
│   │   └── UITestGitHubService.swift            # Deterministic service for UI test target
│   │
│   ├── Models/
│   │   ├── GroupingOption.swift                 # Enum for list grouping modes
│   │   ├── Owner.swift                          # Repository owner domain model
│   │   ├── Repository.swift                     # Core repository domain model
│   │   └── RepositoryDetail.swift               # Enriched detail model (stars, forks etc.)
│   │
│   ├── Services/
│   │   ├── BookmarkService.swift                # Bookmark cache + Combine subjects
│   │   ├── GitHubService.swift                  # GitHub REST API + actor-isolated detail cache
│   │   └── RepositoryUpdateService.swift        # Cross-store enrichment propagation
│   │
│   ├── Shared/
│   │   ├── AvatarView.swift                     # Async owner avatar with placeholder
│   │   └── RepoRowView.swift                    # Shared row used in list and bookmarks
│   │
│   ├── Assets.xcassets
│   ├── ContentView.swift                        # Tab bar root (Explore + Bookmarks)
│   └── GitHubRepoExplorerApp.swift              # App entry point + DependencyContainer init
│
├── GitHubRepoExplorerTests/
│   ├── BookmarkList/
│   │   ├── BookmarkListReducerTests.swift
│   │   └── BookmarkListStoreTests.swift
│   ├── Helpers/
│   │   └── TestDependencyContainer.swift        # Shared mock wiring for store tests
│   ├── RepoDetail/
│   │   ├── RepoDetailReducerTests.swift
│   │   ├── RepoDetailStateTests.swift
│   │   └── RepoDetailStoreTests.swift
│   ├── RepoList/
│   │   ├── RepoListReducerTests.swift
│   │   ├── RepoListStateTests.swift
│   │   └── RepoListStoreTests.swift
│   └── Services/
│       ├── BookmarkServiceTests.swift
│       ├── GitHubServiceTests.swift
│       └── RepositoryUpdateServiceTests.swift
│
└── GitHubRepoExplorerUITests/
    └── GitHubRepoExplorerUITests.swift          # End-to-end UI tests (tab bar, navigation,
                                                 # bookmark flow, swipe actions)
```

---

## Architecture

### MVI (Model–View–Intent)

Each feature follows a strict unidirectional data flow:

```
User Action
    ↓
Intent (enum)
    ↓
Store.dispatch()
    ↓
Reducer (pure function: State × Intent → State)
    ↓
@Published State
    ↓
SwiftUI View re-renders
```

**Key properties of this architecture:**

- **Reducers are pure functions.** Given the same state and intent, they always produce the same result. No async, no side effects, no dependencies — making them trivially testable without mocks.
- **Stores own side effects.** Network calls, persistence writes, and Combine subscriptions live in the store's `dispatch` method after the reducer runs.
- **Views are stateless.** Views read from `store.state` and dispatch intents. They never mutate state directly.
- **Bindings are constructed in the view.** `Binding(get:set:)` reads from state and dispatches an intent on set — the store never touches SwiftUI's `Binding` type.

### Service Layer

Three dedicated services decouple cross-feature concerns:

| Service | Responsibility |
|---------|---------------|
| `GitHubService` | GitHub REST API calls + actor-isolated in-memory detail cache |
| `BookmarkService` | Bookmark business logic, in-memory cache, Combine subjects |
| `PersistenceService` | Pure SwiftData CRUD — no business logic |
| `RepositoryUpdateService` | Publishes enriched repositories so `RepoListStore` stays in sync when `RepoDetailStore` fetches detail |

Stores subscribe to service subjects and dispatch intents on receive — they never hold references to other stores.

### Dependency Injection

`DependencyContainer` is constructed at app launch and passed through the environment. This makes every dependency swappable in tests without global state or singletons leaking into test runs.

---

## Testing

### Unit Tests

The project has three layers of unit tests per feature:

**Reducer tests** — pure function tests with no mocks, no async, no `XCTestExpectation`. Fast and deterministic:

```swift
func test_toggleBookmark_setsIsBookmarkedTrue() {
    var state = RepoDetailState(repository: .mockOriginal)
    state.isBookmarked = false
    let result = RepoDetailReducer.reduce(state, intent: .toggleBookmark)
    XCTAssertTrue(result.isBookmarked)
}
```

**State tests** — computed property tests verifying derived state (grouping, pagination flags, visibility):

```swift
func test_groupedRepositories_groupsByOwnerType() { ... }
func test_hasMorePages_isTrue_whenNextPageURLIsSet() { ... }
```

**Store tests** — async side effect tests using injected mocks and a `waitForState` helper that subscribes to `@Published` state rather than relying on `Task.sleep`:

```swift
func test_loadInitial_loadsRepositoriesOnSuccess() async throws {
    store.dispatch(.loadInitial)
    try await waitForState { $0.phase == .loaded }
    XCTAssertFalse(store.state.repositories.isEmpty)
}
```

### Service Tests

`BookmarkService`, `GitHubService`, and `RepositoryUpdateService` each have dedicated test files using injected `MockPersistenceService` and `MockNetworkClient` — no real network or disk access in any test.

### UI Tests

End-to-end tests using `XCUITest` cover the full user journey:

- Tab bar navigation
- Repo list loading and grouping
- Collapsible section headers
- Navigating to repo detail
- Bookmarking from detail view and via swipe action
- Verifying bookmarked repos appear in the Bookmarks tab after switching

UI tests inject `UITestGitHubService` via the `--uitesting` launch argument, serving deterministic mock data with a fixed set of known repositories. Each test relaunches the app fresh via `app.terminate()` + `app.launch()` to guarantee a clean state.

---

## Known Limitations

### GitHub API Rate Limiting

The GitHub public `/repositories` endpoint is unauthenticated and subject to a **60 requests/hour** limit. The list endpoint returns up to **100 repos per page**. Fetching detail for each repo to populate stars, forks, language, and open issues requires a separate API call per repository — fetching detail for a full page of 100 repos would exhaust the entire hourly limit in a single page load.

Currently the app does **not** auto-fetch detail for all loaded repos. Detail fields are only populated when the user navigates to a repo's detail screen. See Future Improvements for planned solutions.

Adding a GitHub personal access token raises the rate limit to **5,000 requests/hour**, which would make background detail pre-fetching viable. To enable this, add an `Authorization: Bearer <your_token>` header in `GitHubAPIConfig.swift`.

---

## Future Improvements

**1. Replace `AsyncImage` with a persistent image cache**

The current `AvatarView` uses SwiftUI's built-in `AsyncImage`, which does not persist images to disk. Every cold launch re-fetches all owner avatars. A third-party library such as Nuke or Kingfisher, or a custom `URLCache`-backed image loader, would eliminate redundant requests and improve perceived performance on slow connections.

**2. Repo list UI — Contacts-style index bar**

The current grouped list works well for small datasets but becomes hard to navigate with many groups. A Contacts-style alphabetical index bar on the right edge would let users jump directly to a section, matching a native iOS interaction pattern users already know.

**3. Lazy detail fetching for visible rows only**

Repository detail fields (stars, language, forks, open issues) are not included in the `/repositories` list response and require a separate API call per repo. With 100 repos per page and a 60 req/hour unauthenticated rate limit, fetching detail for all loaded repos upfront is not viable. A planned improvement is to fetch detail only for rows currently visible on screen, using `onAppear`/`onDisappear` to track visibility and a debounce to absorb rapid scrolling — so only the repos the user actually pauses on consume rate limit quota.

**4. Auto-fetch details with GitHub authentication**

With a GitHub personal access token the rate limit rises from 60 to 5,000 requests/hour, making it practical to pre-fetch detail for all loaded repos in the background. The architecture is already designed for this — `RepoListStore` has a `.fetchDetails([Repository])` intent and `RepositoryUpdateService` propagates enriched repos back to the list. Swapping in an authenticated `GitHubAPIConfig` would enable this with no architectural changes.

**5. Offline support**

Currently bookmarked repositories are persisted via SwiftData but their enriched detail fields (stars, language etc.) are only available after a network fetch. Persisting the full `RepositoryDetail` alongside the bookmark model would allow the detail screen to load instantly from disk and show cached data when offline.

**6. iPad and landscape layouts**

The current UI is optimised for iPhone portrait. A two-column layout using `NavigationSplitView` would make better use of iPad screen real estate, with the repo list in the primary column and detail in the secondary column.

**7. Replace custom DI container with Swinject**

The current `DependencyContainer` is a hand-rolled dictionary-based container that covers the app's basic injection needs. It lacks scope management, thread safety guarantees, and compile-time resolution checks. Replacing it with [Swinject](https://github.com/Swinject/Swinject) would bring proper lifetime scopes (singleton, transient, object scope), cleaner assembly-based registration, and a more maintainable wiring layer as the app grows.

---

## AI Assistance

Tools: Claude Sonnet 4.6

Usage:

- Architecture brainstorming — MVI pattern design, service layer responsibilities, store-to-store communication via Combine subjects
- Generating initial drafts of reducers, stores, and SwiftUI views
- Unit test strategy — three-layer approach (reducer / state / store), `waitForState` helper pattern, mock design
- UI test debugging — accessibility tree analysis, `XCUIApplication` element lookup strategies
- Code review and refactoring suggestions throughout development

Validation:

- All generated code was reviewed, tested, and refactored before integration
- Architecture decisions were validated against real-world constraints (rate limiting, SwiftData threading, Swift 6 actor isolation)
- Tests were run against the actual app to verify correctness before being committed