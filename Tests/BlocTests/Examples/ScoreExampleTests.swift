// ScoreExampleTests.swift
//
// Faithful inline replica of the Score example from BlocSwift/Examples/Score.
//
// In the real app, ScoreBloc drives a BlocListener that fires at every 5-point
// milestone and a buildWhen that redraws the tier badge only every 10 points.
// Both those reactive patterns are tested below via statePublisher — no SwiftUI
// hosting is needed.

import Testing
import Combine
@testable import Bloc

// MARK: - Inline replica of the Score example

private enum ScoreEvent: BlocEvent {
    case addPoint
    case reset
}

@MainActor
private class ScoreBloc: Bloc<Int, ScoreEvent> {
    init() {
        super.init(initialState: 0)
        on(.addPoint) { [weak self] _, emit in
            guard let self else { return }
            emit(state + 1)
        }
        on(.reset) { _, emit in emit(0) }
    }
}

// MARK: - Tests

@MainActor
struct ScoreExampleTests {

    @Test("ScoreBloc starts at zero")
    func initialScoreIsZero() {
        let bloc = ScoreBloc()
        #expect(bloc.state == 0)
    }

    @Test("addPoint increments the score by one each time")
    func addPointIncrementsScore() {
        let bloc = ScoreBloc()
        bloc.send(.addPoint)
        bloc.send(.addPoint)
        bloc.send(.addPoint)
        #expect(bloc.state == 3)
    }

    @Test("reset returns the score to zero from any value")
    func resetClearsScore() {
        let bloc = ScoreBloc()
        for _ in 0..<7 { bloc.send(.addPoint) }
        bloc.send(.reset)
        #expect(bloc.state == 0)
    }

    /// Mirrors the BlocListener milestone logic from the real app:
    /// a listener fires a side effect at every 5-point boundary.
    @Test("Milestone detection: every 5th point triggers a side effect")
    func milestoneDetectionViaStatePublisher() {
        let bloc = ScoreBloc()
        var milestones: [Int] = []
        var cancellables = Set<AnyCancellable>()

        bloc.statePublisher
            .filter { $0 > 0 && $0.isMultiple(of: 5) }
            .sink { milestones.append($0) }
            .store(in: &cancellables)

        for _ in 0..<12 { bloc.send(.addPoint) }

        #expect(milestones == [5, 10])
        withExtendedLifetime(cancellables) {}
    }

    /// Mirrors the buildWhen tier-badge logic:
    /// the badge only redraws when the score crosses a 10-point tier boundary.
    @Test("Tier badge: only redraws when score crosses a 10-point boundary")
    func tierBadgeRebuildsAtTierBoundaries() {
        let bloc = ScoreBloc()
        var tierChanges: [Int] = []
        var cancellables = Set<AnyCancellable>()
        var previousTier = 0

        bloc.statePublisher
            .dropFirst() // skip the initial 0
            .sink { score in
                let tier = score / 10
                if tier != previousTier {
                    previousTier = tier
                    tierChanges.append(score)
                }
            }
            .store(in: &cancellables)

        for _ in 0..<25 { bloc.send(.addPoint) }

        // Boundaries crossed at 10, 20
        #expect(tierChanges == [10, 20])
        withExtendedLifetime(cancellables) {}
    }
}
