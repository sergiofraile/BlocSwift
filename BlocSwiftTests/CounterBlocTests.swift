//
//  CounterBlocTests.swift
//  BlocSwiftTests
//
//  Created by Sergio Fraile on 19/01/2026.
//

import Testing
import Combine
@testable import BlocSwift

/// Tests for `CounterBloc` following the Bloc pattern testing best practices.
///
/// The Bloc pattern is designed to be extremely easy to test. These tests verify:
/// - Initial state is correct
/// - Events produce expected state changes
/// - State transitions are predictable
///
/// Reference: https://bloclibrary.dev/testing/
@MainActor
struct CounterBlocTests {
    
    // MARK: - Initial State Tests
    
    @Test("Initial state should be 0")
    func initialStateIsZero() async throws {
        // Arrange & Act
        let counterBloc = CounterBloc()
        
        // Assert
        #expect(counterBloc.state == 0)
    }
    
    @Test("Initial state can be customized")
    func customInitialState() async throws {
        // Arrange & Act
        let counterBloc = CounterBloc(initialState: 10)
        
        // Assert
        #expect(counterBloc.state == 10)
    }
    
    // MARK: - Increment Event Tests
    
    @Test("Emits 1 when increment is sent from initial state")
    func incrementFromInitialState() async throws {
        // Arrange
        let counterBloc = CounterBloc()
        
        // Act
        counterBloc.send(.increment)
        
        // Assert
        #expect(counterBloc.state == 1)
    }
    
    @Test("Emits 11 when increment is sent from state 10")
    func incrementFromCustomState() async throws {
        // Arrange
        let counterBloc = CounterBloc(initialState: 10)
        
        // Act
        counterBloc.send(.increment)
        
        // Assert
        #expect(counterBloc.state == 11)
    }
    
    @Test("Multiple increments accumulate correctly")
    func multipleIncrements() async throws {
        // Arrange
        let counterBloc = CounterBloc()
        
        // Act
        counterBloc.send(.increment)
        counterBloc.send(.increment)
        counterBloc.send(.increment)
        
        // Assert
        #expect(counterBloc.state == 3)
    }
    
    // MARK: - Decrement Event Tests
    
    @Test("Emits -1 when decrement is sent from initial state")
    func decrementFromInitialState() async throws {
        // Arrange
        let counterBloc = CounterBloc()
        
        // Act
        counterBloc.send(.decrement)
        
        // Assert
        #expect(counterBloc.state == -1)
    }
    
    @Test("Emits 9 when decrement is sent from state 10")
    func decrementFromCustomState() async throws {
        // Arrange
        let counterBloc = CounterBloc(initialState: 10)
        
        // Act
        counterBloc.send(.decrement)
        
        // Assert
        #expect(counterBloc.state == 9)
    }
    
    @Test("Multiple decrements accumulate correctly")
    func multipleDecrements() async throws {
        // Arrange
        let counterBloc = CounterBloc()
        
        // Act
        counterBloc.send(.decrement)
        counterBloc.send(.decrement)
        counterBloc.send(.decrement)
        
        // Assert
        #expect(counterBloc.state == -3)
    }
    
    // MARK: - Reset Event Tests
    
    @Test("Emits 0 when reset is sent")
    func resetToZero() async throws {
        // Arrange
        let counterBloc = CounterBloc(initialState: 100)
        
        // Act
        counterBloc.send(.reset)
        
        // Assert
        #expect(counterBloc.state == 0)
    }
    
    @Test("Reset after increments returns to initial state")
    func resetAfterIncrements() async throws {
        // Arrange
        let counterBloc = CounterBloc()
        counterBloc.send(.increment)
        counterBloc.send(.increment)
        counterBloc.send(.increment)
        
        // Act
        counterBloc.send(.reset)
        
        // Assert
        #expect(counterBloc.state == 0)
    }
    
    @Test("Reset after decrements returns to initial state")
    func resetAfterDecrements() async throws {
        // Arrange
        let counterBloc = CounterBloc()
        counterBloc.send(.decrement)
        counterBloc.send(.decrement)
        
        // Act
        counterBloc.send(.reset)
        
        // Assert
        #expect(counterBloc.state == 0)
    }
    
    // MARK: - Combined Events Tests
    
    @Test("Mixed events produce correct final state")
    func mixedEvents() async throws {
        // Arrange
        let counterBloc = CounterBloc()
        
        // Act: increment 3 times, decrement 1 time -> expected state is 2
        counterBloc.send(.increment)
        counterBloc.send(.increment)
        counterBloc.send(.increment)
        counterBloc.send(.decrement)
        
        // Assert
        #expect(counterBloc.state == 2)
    }
    
    @Test("Complex sequence of events")
    func complexEventSequence() async throws {
        // Arrange
        let counterBloc = CounterBloc(initialState: 5)
        
        // Act
        counterBloc.send(.increment)  // 6
        counterBloc.send(.increment)  // 7
        counterBloc.send(.decrement)  // 6
        counterBloc.send(.reset)      // 0
        counterBloc.send(.decrement)  // -1
        
        // Assert
        #expect(counterBloc.state == -1)
    }
    
    // MARK: - State Publisher Tests
    
    @Test("State publisher emits correct values")
    func statePublisherEmitsValues() async throws {
        // Arrange
        let counterBloc = CounterBloc()
        var emittedStates: [Int] = []
        var cancellables = Set<AnyCancellable>()
        
        counterBloc.statePublisher
            .sink { state in
                emittedStates.append(state)
            }
            .store(in: &cancellables)
        
        // Act
        counterBloc.send(.increment)
        counterBloc.send(.increment)
        counterBloc.send(.decrement)
        
        // Assert
        // First value is initial state (0), then 1, 2, 1
        #expect(emittedStates == [0, 1, 2, 1])
    }
}
