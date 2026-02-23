//
//  RepoListStore.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Combine
import SwiftUI

final class RepoListStore: ObservableObject {
    @Published private(set) var state = RepoListState()
    
    private let reducer = RepoListReducer()
    private let recipeService: RecipeServiceProtocol

    private var isPreview: Bool = false
    private let limit = 20
    private var skip = 0
    private var cancellables = Set<AnyCancellable>()
    
    init(container: Container = AppDelegate.container) {
        recipeService = container.resolve(RecipeServiceProtocol.self)!
        
        // Debounce search text
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .scan(("", "")) { previous, newValue in
                (previous.1, newValue)
            }
            .sink { [weak self] oldValue, newValue in
                guard let self else { return }
                if !oldValue.isEmpty, newValue.isEmpty {
                    self.send(.cancelSearch)
                } else if !newValue.isEmpty {
                    self.send(.search(newValue))
                }
            }
            .store(in: &cancellables)
    }

    // Only for Preview
    convenience init(state: RecipeListState) {
        self.init()
        self.state = state
        self.isPreview = true
    }
    
    // MARK: - Intent
    func send(_ intent: RecipeListIntent) {
        guard !(isPreview) else { return }

        let newState = reducer.reduce(state: state, intent: intent)
        guard newState != state else { return }

        state = newState

        switch intent {
        case .onAppear, .loadMore, .retry:
            if state.isLoading, !state.isSearching {
                loadRecipes()
            }
            
        case .search(let keyword):
            if state.isLoading, state.isSearching {
                searchRecipes(keyword)
            }

        case .cancelSearch:
            break
        }
    }

    // MARK: - Side Effect
    private func loadRecipes() {
        Task {
            do {
                let response = try await recipeService.fetchRecipes(limit: limit, skip: skip)

                skip += response.recipes.count

                state.isLoading = false
                state.loadedRecipes.append(contentsOf: response.recipes)
                state.hasMore = !response.recipes.isEmpty
                state.recipes = state.loadedRecipes

            } catch {
                state.isLoading = false
                state.errorMessage = error.localizedDescription
            }
        }
    }
}
