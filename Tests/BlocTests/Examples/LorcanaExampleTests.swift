// LorcanaExampleTests.swift
//
// Faithful inline replica of the Lorcana example from BlocSwift/Examples/Lorcana.
//
// LorcanaBloc is the most feature-rich Bloc in the project:
//   - Dependency injection via LorcanaNetworkServiceProtocol
//   - Pagination (loadNextPage appends results, tracks hasMorePages)
//   - Debounced search with on(where:transformer:) — only fires after 300 ms quiet period
//   - Set browsing
//
// These tests drive the Bloc through mock services and demonstrate that
// even complex async state management remains straightforward to verify.

import Testing
import Combine
@testable import Bloc

// MARK: - Domain types (mirrors Lorcana/Models)

private struct Card: Equatable {
    let id: String
    let name: String
}

private struct CardSet: Equatable {
    let name: String
}

private struct NetworkError: Error { let message: String }

// MARK: - State (mirrors LorcanaState)

private struct LorcanaState: BlocState {
    var cards: [Card] = []
    var sets: [CardSet] = []
    var searchQuery: String = ""
    var currentPage: Int = 1
    var hasMorePages: Bool = false
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var error: String? = nil

    var isSearching: Bool { !searchQuery.isEmpty }

    static let initial = LorcanaState()
}

// MARK: - Events (mirrors LorcanaEvent)

private enum LorcanaEvent: BlocEvent {
    case clear
    case fetchAllCards
    case loadNextPage
    case loadSets
    case search(query: String)
    case loadSet(setName: String)
}

// MARK: - Service protocol (mirrors LorcanaNetworkServiceProtocol)

private protocol LorcanaNetworkServiceProtocol: Sendable {
    func fetchAllCards(page: Int, pageSize: Int) async throws -> [Card]
    func searchCards(query: String, page: Int, pageSize: Int) async throws -> [Card]
    func fetchCardsFromSet(setName: String, page: Int, pageSize: Int) async throws -> [Card]
    func fetchSets() async throws -> [CardSet]
}

// MARK: - Mock services

private struct MockLorcanaService: LorcanaNetworkServiceProtocol {
    var cards: [Card] = []
    var sets: [CardSet] = []
    var error: Error?

    func fetchAllCards(page: Int, pageSize: Int) async throws -> [Card] {
        if let err = error { throw err }
        return cards
    }
    func searchCards(query: String, page: Int, pageSize: Int) async throws -> [Card] {
        if let err = error { throw err }
        return cards.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
    func fetchCardsFromSet(setName: String, page: Int, pageSize: Int) async throws -> [Card] {
        if let err = error { throw err }
        return cards
    }
    func fetchSets() async throws -> [CardSet] {
        if let err = error { throw err }
        return sets
    }
}

// MARK: - Inline replica of LorcanaBloc

@MainActor
private class LorcanaBloc: Bloc<LorcanaState, LorcanaEvent> {

    private let service: any LorcanaNetworkServiceProtocol
    private let pageSize = 10

    init(service: any LorcanaNetworkServiceProtocol) {
        self.service = service
        super.init(initialState: .initial)

        on(.clear) { _, emit in emit(.initial) }

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

        on(
            where: { if case .search = $0 { return true }; return false },
            transformer: .debounce(.milliseconds(50))
        ) { [weak self] event, _ in
            guard let self, case .search(let query) = event else { return }
            Task { await self.searchCards(query: query) }
        }
    }

    private func fetchAllCards() async {
        var s = state
        s.isLoading = true; s.error = nil; s.searchQuery = ""; s.currentPage = 1; s.cards = []
        emit(s)
        do {
            let cards = try await service.fetchAllCards(page: 1, pageSize: pageSize)
            var loaded = state
            loaded.cards = cards; loaded.isLoading = false
            loaded.hasMorePages = cards.count == pageSize
            emit(loaded)
        } catch {
            addError(error)
            var errState = state; errState.isLoading = false; errState.error = error.localizedDescription
            emit(errState)
        }
    }

    private func loadNextPage() async {
        guard !state.isLoadingMore && !state.isLoading && state.hasMorePages else { return }
        var s = state; s.isLoadingMore = true; emit(s)
        let nextPage = state.currentPage + 1
        do {
            let cards = try await service.fetchAllCards(page: nextPage, pageSize: pageSize)
            var loaded = state
            loaded.cards.append(contentsOf: cards)
            loaded.currentPage = nextPage; loaded.isLoadingMore = false
            loaded.hasMorePages = cards.count == pageSize
            emit(loaded)
        } catch {
            addError(error)
            var errState = state; errState.isLoadingMore = false; errState.error = error.localizedDescription
            emit(errState)
        }
    }

    private func searchCards(query: String) async {
        guard query.count >= 3 else { return }
        var s = state; s.isLoading = true; s.error = nil; s.searchQuery = query; s.currentPage = 1; s.cards = []
        emit(s)
        do {
            let cards = try await service.searchCards(query: query, page: 1, pageSize: pageSize)
            var loaded = state; loaded.cards = cards; loaded.isLoading = false
            loaded.hasMorePages = cards.count == pageSize
            emit(loaded)
        } catch {
            addError(error)
            var errState = state; errState.isLoading = false; errState.error = error.localizedDescription
            emit(errState)
        }
    }

    private func loadSets() async {
        do {
            let sets = try await service.fetchSets()
            var s = state; s.sets = sets; emit(s)
        } catch {
            addError(error)
            var s = state; s.error = error.localizedDescription; emit(s)
        }
    }
}

// MARK: - Tests

@MainActor
struct LorcanaExampleTests {

    private let sampleCards = (1...5).map { Card(id: "card-\($0)", name: "Card \($0)") }
    private let sampleSets  = [CardSet(name: "The First Chapter"), CardSet(name: "Rise of the Floodborn")]

    @Test("LorcanaBloc starts in the initial empty state")
    func initialStateIsEmpty() {
        let bloc = LorcanaBloc(service: MockLorcanaService())
        #expect(bloc.state.cards.isEmpty)
        #expect(!bloc.state.isLoading)
    }

    @Test("fetchAllCards populates cards when service succeeds")
    func fetchAllCardsSucceeds() async throws {
        let service = MockLorcanaService(cards: sampleCards)
        let bloc = LorcanaBloc(service: service)

        bloc.send(.fetchAllCards)
        // The handler creates an inner Task which then calls async service methods.
        // A short sleep is more reliable than Task.yield() chains because it
        // waits for all async hops to complete regardless of scheduler ordering.
        try await Task.sleep(for: .milliseconds(20))

        #expect(bloc.state.cards == sampleCards)
        #expect(!bloc.state.isLoading)
        #expect(bloc.state.error == nil)
    }

    @Test("fetchAllCards sets error when service throws")
    func fetchAllCardsFailureSetsErrorState() async throws {
        let service = MockLorcanaService(error: NetworkError(message: "offline"))
        let bloc = LorcanaBloc(service: service)

        bloc.send(.fetchAllCards)
        try await Task.sleep(for: .milliseconds(20))

        #expect(bloc.state.error != nil)
        #expect(!bloc.state.isLoading)
    }

    @Test("clear event resets the Bloc to initial state")
    func clearEventResetsState() async throws {
        let service = MockLorcanaService(cards: sampleCards)
        let bloc = LorcanaBloc(service: service)

        bloc.send(.fetchAllCards)
        try await Task.sleep(for: .milliseconds(20))
        #expect(!bloc.state.cards.isEmpty)

        bloc.send(.clear)
        #expect(bloc.state.cards.isEmpty)
        #expect(bloc.state.searchQuery.isEmpty)
    }

    @Test("search (debounced) filters cards by query and sets searchQuery")
    func searchDebounceFiltersCards() async throws {
        let cards = [
            Card(id: "1", name: "Elsa - Snow Queen"),
            Card(id: "2", name: "Mickey Mouse"),
            Card(id: "3", name: "Elsa - Ice Queen"),
        ]
        let service = MockLorcanaService(cards: cards)
        let bloc = LorcanaBloc(service: service)

        // Debounce window is 50 ms — send a search and wait for it to settle
        bloc.send(.search(query: "Elsa"))
        try await Task.sleep(for: .milliseconds(150))

        #expect(bloc.state.searchQuery == "Elsa")
        #expect(bloc.state.cards.allSatisfy { $0.name.contains("Elsa") })
    }
}
