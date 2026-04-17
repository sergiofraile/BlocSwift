import Testing
@testable import Bloc

// MARK: - Test Helpers

private enum RegistryEvent: BlocEvent { case ping }

@MainActor
private class PingBloc: Bloc<Int, RegistryEvent> {
    init() {
        super.init(initialState: 0)
        on(.ping) { [weak self] _, emit in
            guard let self else { return }
            emit(self.state + 1)
        }
    }
}

@MainActor
private class AnotherBloc: Bloc<String, RegistryEvent> {
    init() { super.init(initialState: "hello") }
}

@MainActor
private class RegistryCubit: Cubit<Bool> {
    init() { super.init(initialState: false) }
    func toggle() { emit(!state) }
}

// MARK: - BlocRegistry Tests

@MainActor
struct BlocRegistryTests {

    /// `BlocRegistry.init(with:)` is `@usableFromInline` and accessible via
    /// `@testable import`. Each test creates a fresh registry instance, which
    /// automatically replaces the previous shared instance.

    @Test func resolvingARegisteredBlocReturnsTheCorrectInstance() {
        let bloc = PingBloc()
        _ = BlocRegistry(with: [bloc])

        let resolved = BlocRegistry.resolve(PingBloc.self)
        resolved.send(.ping)
        #expect(resolved.state == 1)

        // Ensure it's the exact same object
        #expect(resolved === bloc)
    }

    @Test func resolvingARegisteredCubitReturnsTheCorrectInstance() {
        let cubit = RegistryCubit()
        _ = BlocRegistry(with: [cubit])

        let resolved = BlocRegistry.resolve(RegistryCubit.self)
        resolved.toggle()
        #expect(resolved.state == true)
        #expect(resolved === cubit)
    }

    @Test func registryCanHoldMultipleDistinctTypes() {
        let bloc = PingBloc()
        let cubit = RegistryCubit()
        _ = BlocRegistry(with: [bloc, cubit])

        let resolvedBloc  = BlocRegistry.resolve(PingBloc.self)
        let resolvedCubit = BlocRegistry.resolve(RegistryCubit.self)

        #expect(resolvedBloc  === bloc)
        #expect(resolvedCubit === cubit)
    }
}
