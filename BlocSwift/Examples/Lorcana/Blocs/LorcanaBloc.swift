//
//  LorcanaBloc.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import Bloc
import Foundation

/// Bloc for managing Lorcana card browsing and search.
///
/// The `.search` event is handled with a `.debounce(.milliseconds(300))` transformer,
/// which means the search network call is only triggered after 300 ms of silence.
/// This replaces manual Task-cancellation debounce in the view layer.
@MainActor
class LorcanaBloc: Bloc<LorcanaState, LorcanaEvent> {

    private let networkService: any LorcanaNetworkServiceProtocol
    private let pageSize = 100

    init(networkService: any LorcanaNetworkServiceProtocol) {
        self.networkService = networkService
        super.init(initialState: .initial)

        on(.clear) { _, emit in
            emit(.initial)
        }

        on(.fetchAllCards) { [weak self] _, _ in
            guard let self else { return }
            Task { await self.fetchAllCards() }
        }

        on(.loadNextPage) { [weak self] _, _ in
            guard let self else { return }
            Task { await self.loadNextPage() }
        }

        on(.loadSets) { [weak self] _, _ in
            guard let self else { return }
            Task { await self.loadSets() }
        }

        // Debounce search: the handler fires only after 300 ms of no new
        // search events. Each keystroke resets the timer, so the API call
        // is made once the user pauses typing.
        on(
            where: { if case .search = $0 { return true }; return false },
            transformer: .debounce(.milliseconds(300))
        ) { [weak self] event, _ in
            guard let self, case .search(let query) = event else { return }
            Task { await self.searchCards(query: query) }
        }

        on(
            where: { if case .loadSet = $0 { return true }; return false }
        ) { [weak self] event, _ in
            guard let self, case .loadSet(let setName) = event else { return }
            Task { await self.loadSetCards(setName: setName) }
        }
    }

    // MARK: - Async handlers

    private func fetchAllCards() async {
        var newState = state
        newState.isLoading = true
        newState.error = nil
        newState.searchQuery = ""
        newState.currentPage = 1
        newState.cards = []
        emit(newState)

        do {
            let cards = try await networkService.fetchAllCards(page: 1, pageSize: pageSize)
            var loadedState = state
            loadedState.cards = cards
            loadedState.isLoading = false
            loadedState.hasMorePages = cards.count == pageSize
            emit(loadedState)
        } catch {
            addError(error)
            var errorState = state
            errorState.isLoading = false
            errorState.error = LorcanaError(message: error.localizedDescription)
            emit(errorState)
        }
    }

    private func loadNextPage() async {
        guard !state.isLoadingMore && !state.isLoading && state.hasMorePages else { return }

        var newState = state
        newState.isLoadingMore = true
        emit(newState)

        let nextPage = state.currentPage + 1

        do {
            let cards: [LorcanaCard]
            if state.isSearching {
                cards = try await networkService.searchCards(query: state.searchQuery, page: nextPage, pageSize: pageSize)
            } else {
                cards = try await networkService.fetchAllCards(page: nextPage, pageSize: pageSize)
            }

            var loadedState = state
            loadedState.cards.append(contentsOf: cards)
            loadedState.currentPage = nextPage
            loadedState.isLoadingMore = false
            loadedState.hasMorePages = cards.count == pageSize
            emit(loadedState)
        } catch {
            addError(error)
            var errorState = state
            errorState.isLoadingMore = false
            errorState.error = LorcanaError(message: error.localizedDescription)
            emit(errorState)
        }
    }

    private func searchCards(query: String) async {
        guard query.count >= 3 else { return }
        var newState = state
        newState.isLoading = true
        newState.error = nil
        newState.searchQuery = query
        newState.currentPage = 1
        newState.cards = []
        emit(newState)

        do {
            let cards = try await networkService.searchCards(query: query, page: 1, pageSize: pageSize)
            var loadedState = state
            loadedState.cards = cards
            loadedState.isLoading = false
            loadedState.hasMorePages = cards.count == pageSize
            emit(loadedState)
        } catch {
            addError(error)
            var errorState = state
            errorState.isLoading = false
            errorState.error = LorcanaError(message: error.localizedDescription)
            emit(errorState)
        }
    }

    private func loadSetCards(setName: String) async {
        var newState = state
        newState.isLoading = true
        newState.error = nil
        newState.currentPage = 1
        newState.cards = []
        emit(newState)

        do {
            let cards = try await networkService.fetchCardsFromSet(setName: setName, page: 1, pageSize: pageSize)
            var loadedState = state
            loadedState.cards = cards
            loadedState.isLoading = false
            loadedState.hasMorePages = cards.count == pageSize
            emit(loadedState)
        } catch {
            addError(error)
            var errorState = state
            errorState.isLoading = false
            errorState.error = LorcanaError(message: error.localizedDescription)
            emit(errorState)
        }
    }

    private func loadSets() async {
        do {
            let sets = try await networkService.fetchSets()
            var newState = state
            newState.sets = sets
            emit(newState)
        } catch {
            addError(error)
            var errorState = state
            errorState.error = LorcanaError(message: error.localizedDescription)
            emit(errorState)
        }
    }
}
