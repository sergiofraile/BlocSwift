// FormulaOneExampleTests.swift
//
// Faithful inline replica of the FormulaOne example from BlocSwift/Examples/FormulaOne.
//
// The real FormulaOneBloc uses a concrete FormulaOneNetworkService with no
// dependency injection, making it hard to unit-test the async path.
//
// This replica introduces a lightweight FormulaOneServiceProtocol and injects it
// via the initialiser — the recommended pattern for any Bloc that performs
// network work. The mock can be configured to succeed or fail, so both happy-
// path and error scenarios are exercised without any real network calls.

import Testing
import Combine
@testable import Bloc

// MARK: - Domain types

private struct Driver: Equatable {
    let name: String
    let points: Int
}

private enum FormulaOneEvent: BlocEvent {
    case clear
    case loadChampionship
}

private enum FormulaOneState: BlocState {
    case initial
    case loading
    case loaded([Driver])
    case error(String)
}

private enum FormulaOneNetworkError: Error { case serverDown }

// MARK: - Service protocol (enables mocking)

private protocol FormulaOneServiceProtocol: Sendable {
    func fetchDrivers() async throws -> [Driver]
}

// MARK: - Mock service

private struct SucceedingService: FormulaOneServiceProtocol {
    let drivers: [Driver]
    func fetchDrivers() async throws -> [Driver] { drivers }
}

private struct FailingService: FormulaOneServiceProtocol {
    func fetchDrivers() async throws -> [Driver] { throw FormulaOneNetworkError.serverDown }
}

// MARK: - Inline replica of FormulaOneBloc (with protocol injection)

@MainActor
private class FormulaOneBloc: Bloc<FormulaOneState, FormulaOneEvent> {

    private let service: any FormulaOneServiceProtocol

    init(service: any FormulaOneServiceProtocol) {
        self.service = service
        super.init(initialState: .initial)

        on(.clear) { _, emit in emit(.initial) }
    }

    override func mapEventToState(event: FormulaOneEvent, emit: @escaping Emitter) {
        if case .loadChampionship = event {
            emit(.loading)
            Task { [weak self] in await self?.loadChampionship() }
        }
    }

    private func loadChampionship() async {
        do {
            let drivers = try await service.fetchDrivers()
            emit(.loaded(drivers))
        } catch {
            addError(error)
            emit(.error(error.localizedDescription))
        }
    }
}

// MARK: - Tests

@MainActor
struct FormulaOneExampleTests {

    private let mockDrivers = [
        Driver(name: "Max Verstappen", points: 437),
        Driver(name: "Lando Norris",   points: 374),
        Driver(name: "Charles Leclerc", points: 356),
    ]

    @Test("FormulaOneBloc starts in the initial state")
    func initialStateIsInitial() {
        let bloc = FormulaOneBloc(service: SucceedingService(drivers: mockDrivers))
        if case .initial = bloc.state { } else { Issue.record("Expected .initial") }
    }

    @Test("clear event resets state to initial from any other state")
    func clearEventResetsToInitial() async {
        let bloc = FormulaOneBloc(service: SucceedingService(drivers: mockDrivers))
        bloc.send(.loadChampionship)        // → .loading
        bloc.send(.clear)                   // → .initial
        if case .initial = bloc.state { } else { Issue.record("Expected .initial after clear") }
    }

    @Test("loadChampionship transitions through loading → loaded with mock data")
    func loadChampionshipSucceeds() async throws {
        let bloc = FormulaOneBloc(service: SucceedingService(drivers: mockDrivers))

        bloc.send(.loadChampionship)
        if case .loading = bloc.state { } else { Issue.record("Expected .loading synchronously") }

        try await Task.sleep(for: .milliseconds(20))

        if case .loaded(let drivers) = bloc.state {
            #expect(drivers == mockDrivers)
        } else {
            Issue.record("Expected .loaded after Task completes")
        }
    }

    @Test("loadChampionship emits .error and publishes on errorsPublisher when service fails")
    func loadChampionshipFailureEmitsError() async throws {
        let bloc = FormulaOneBloc(service: FailingService())
        var errors: [Error] = []
        var cancellables = Set<AnyCancellable>()
        bloc.errorsPublisher.sink { errors.append($0) }.store(in: &cancellables)

        bloc.send(.loadChampionship)
        try await Task.sleep(for: .milliseconds(20))

        if case .error = bloc.state { } else { Issue.record("Expected .error state") }
        #expect(errors.count == 1)
        withExtendedLifetime(cancellables) {}
    }
}
