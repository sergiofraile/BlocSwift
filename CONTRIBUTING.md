# Contributing to Bloc

Thank you for your interest in contributing! This document covers everything you need to get started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Making Changes](#making-changes)
- [Running Tests](#running-tests)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)
- [Style Guide](#style-guide)

## Code of Conduct

This project follows a simple rule: be kind and respectful. We welcome contributors of all experience levels. Harassment or exclusionary behavior of any kind will not be tolerated.

## Getting Started

### Prerequisites

- Xcode 16.0+
- Swift 6.0+
- macOS 14+

### Cloning the Repository

```bash
git clone https://github.com/sergiofraile/BlocSwift.git
cd BlocSwift
```

The repository contains two things:

| Path | Purpose |
|------|---------|
| `Sources/Bloc/` | The Bloc Swift Package (library code) |
| `Tests/BlocTests/` | Library unit tests |
| `BlocSwift/` | Example app demonstrating library usage |
| `BlocSwift.xcodeproj` | Xcode project for the example app |

### Opening the Project

- **Library only (SPM):** Open the root folder in Xcode via **File → Open** and select the repo root. Xcode will detect `Package.swift` automatically.
- **Example app:** Open `BlocSwift.xcodeproj`.

## Development Workflow

1. **Fork** the repository on GitHub
2. **Clone** your fork locally
3. Create a **feature branch**: `git checkout -b feature/my-feature`
4. Make your changes following the [style guide](#style-guide)
5. **Run tests** to make sure nothing is broken
6. **Commit** with a clear message
7. **Push** and open a Pull Request

## Making Changes

### Library Changes (`Sources/Bloc/`)

When modifying the library:

- Follow SOLID principles (see `.cursorrules` for detailed guidelines)
- Use `@MainActor` for UI-related classes
- Prefer Combine publishers for reactive patterns
- Use weak references in closures to avoid retain cycles
- Keep the public API minimal and well-documented

After changing the library, always:
1. Update or add tests in `Tests/BlocTests/`
2. Verify the example app still builds and runs correctly

### Example App Changes (`BlocSwift/`)

Examples should demonstrate best practices:

- Each example should showcase a specific library feature
- Keep examples focused and easy to understand
- Include comments explaining non-obvious concepts

## Running Tests

### Via Command Line (Swift Package)

```bash
swift test
```

### Via Xcode

Open the package in Xcode and press `⌘U`, or use the **Product → Test** menu.

CI runs `swift test` automatically on every pull request.

## Submitting a Pull Request

Before submitting:

- [ ] Tests pass locally (`swift test`)
- [ ] New features have corresponding tests
- [ ] Public APIs have DocC documentation comments
- [ ] The example app compiles if the library API changed
- [ ] Commit messages are clear and descriptive

**PR title format:** Use a short imperative sentence, e.g.:
- `Add BlocSelector support for derived state`
- `Fix memory leak in BlocRegistry`
- `Update HydratedBloc to support async storage`

Include a description of *what* changed and *why*.

## Reporting Bugs

Please use [GitHub Issues](https://github.com/sergiofraile/BlocSwift/issues) and include:

- A clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Swift and Xcode version
- Minimal code example (if possible)

## Requesting Features

Open a [GitHub Issue](https://github.com/sergiofraile/BlocSwift/issues) with the `enhancement` label. Describe:

- The use case or problem you're solving
- Your proposed API (if applicable)
- Any alternatives you've considered

## Style Guide

- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use Swift 6 strict concurrency (`@MainActor`, `Sendable`)
- Prefer `async/await` over completion handlers for new async code
- Document all public symbols with DocC comments (`///`)
- Keep functions focused — if it needs a long comment to explain, consider splitting it
- No force unwraps (`!`) in library code

---

If you have questions, open a [Discussion](https://github.com/sergiofraile/BlocSwift/discussions) — we're happy to help.
