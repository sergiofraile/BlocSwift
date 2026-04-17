// BlocTests module entry point.
// All tests are organised across the following files:
//
//   CubitTests.swift          – Cubit state, publishers, lifecycle hooks
//   BlocCoreTests.swift       – Bloc events, handlers, publishers, lifecycle hooks
//   EventTransformerTests.swift – sequential, concurrent, droppable, restartable,
//                                 debounce, throttle strategies
//   BlocObserverTests.swift   – Global observer lifecycle notifications
//   HydratedBlocTests.swift   – State persistence and rehydration
//   ModelTests.swift          – Change, Transition, BlocError value types
//   BlocRegistryTests.swift   – Type-safe Bloc / Cubit resolution
//   ExampleShowcaseTests.swift – Self-contained CounterBloc + StopwatchCubit
//                                examples demonstrating how easy testing is
