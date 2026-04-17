import Testing
@testable import Bloc

// MARK: - Model Tests

/// Tests for the lightweight value types used throughout the library:
/// `Change`, `Transition`, and `BlocError`.
struct ModelTests {

    // MARK: Change

    @Test func changeStoresCurrentAndNextState() {
        let change = Change(currentState: 0, nextState: 1)
        #expect(change.currentState == 0)
        #expect(change.nextState == 1)
    }

    @Test func changeDescriptionContainsStateValues() {
        let change = Change(currentState: "idle", nextState: "loading")
        let description = change.description
        #expect(description.contains("idle"))
        #expect(description.contains("loading"))
    }

    // MARK: Transition

    private enum TestEvent: BlocEvent { case doIt }

    @Test func transitionStoresCurrentStateEventAndNextState() {
        let transition = Transition(currentState: 0, event: TestEvent.doIt, nextState: 1)
        #expect(transition.currentState == 0)
        #expect(transition.event == .doIt)
        #expect(transition.nextState == 1)
    }

    @Test func transitionDescriptionContainsAllThreeValues() {
        let transition = Transition(currentState: 0, event: TestEvent.doIt, nextState: 1)
        let description = transition.description
        #expect(description.contains("0"))
        #expect(description.contains("1"))
        #expect(description.contains("doIt"))
    }

    // MARK: BlocError

    @Test func blocErrorDefaultErrorIsAnError() {
        let error: Error = BlocError.defaultError
        #expect(error is BlocError)
    }
}
