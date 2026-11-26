# iTunes Search · Agent guide

Native iOS app built with **Swift 6 and SwiftUI** (iOS 17, iPhone and iPad). It searches albums in the [iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/) and shows their details. This is a technical assessment: clarity, layer separation, cancellation, caching and tests are what matter. Keep it simple; do not add features nobody asked for.

The user-facing explanation and the reasoning behind each decision live in [README.md](README.md); don't repeat it here.

## Layers

Local Swift package `Packages/SearchFeature`, one target per layer, each with its own test target.

| Target         | Role                                   | What's inside                                                              | Depends on |
|----------------|----------------------------------------|----------------------------------------------------------------------------|------------|
| `Domain`       | The contract: what an album is         | Entities, errors, repository protocols, use cases                          | Nothing    |
| `Data`         | Fetches the data                       | HTTP client, endpoints, DTOs and mappers, in-memory cache, repository      | `Domain`   |
| `Presentation` | Shows the data                         | SwiftUI views, view models, design system, String Catalog                  | `Domain`   |

The app target (`App/`) starts the app and wires the layers in `CompositionRoot`. It is the only place that knows all three.

Rules:

- `Presentation` never imports `Data`, and vice versa. The package manifest enforces it; don't add the dependency.
- View models receive use cases through their initializer. No singletons, no service locators.
- No business, network or cache logic in `App/`.

## Flow

- **Search:** text field → `SearchViewModel` (cancels the previous `Task`, 300 ms debounce) → `SearchAlbumsUseCase` → repository (3-minute in-memory cache per normalized query) → `GET /search`. Editing the query cancels the request in flight, and a cancelled task never writes its result.
- **Detail:** row → `AlbumDetailViewModel` → `GetAlbumDetailUseCase` → `GET /lookup`.

## Code rules

- **Language:** code and commits in English. Existing code comments are in Spanish; follow the surrounding file.
- **Concurrency:** Swift 6 strict concurrency, 0 warnings. Cancellation must keep working: don't swallow `CancellationError`.
- **UI:** SwiftUI only.
  - Colors, spacing and metrics come from the design system in `Presentation/Shared/DesignSystem`. No hardcoded colors or fixed font sizes.
  - Support Dynamic Type; don't fix screen frames.
  - Adapt layouts with size classes (`horizontalSizeClass`, `verticalSizeClass`), not device models. iPad and iPhone share one adaptive layout.
  - User-facing text lives in `Localizable.xcstrings` (es and en), with `bundle: .module`. No hardcoded strings.
- **Platform:** the package also compiles on macOS for `swift test`. Guard iOS-only APIs with `#if os(iOS)` or `#if canImport(UIKit)`.
- **Test data:** only in tests and previews. The one exception is `-UITestMockData`, a launch argument that runs the app with fixed in-memory data and no network.
- **Dependencies:** none external. Don't add libraries.

## Tests

Every behavior change comes with a test. No network and no `sleep`: the cache clock and the debounce are injected.

| Layer        | How it's tested                                                              |
|--------------|------------------------------------------------------------------------------|
| Domain       | Swift Testing with the repository mocked                                     |
| Data         | Mock HTTP client and injected clock (cache use and expiry)                   |
| Presentation | View models with fakes; deterministic cancellation test; localization check  |
| UI           | XCTest with `-UITestMockData`: flow, accessibility audit, iPad layout        |

```bash
# Domain and Data, no simulator
cd Packages/SearchFeature && swift test --filter "DomainTests|DataTests"

# All unit tests (the simulator needs OS=18.6 on this Mac)
xcodebuild test -project iTunesSearch.xcodeproj -scheme iTunesSearch \
  -testPlan iTunesSearch -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'

# UI tests (run them on an iPad simulator too: some tests only run there)
xcodebuild test -project iTunesSearch.xcodeproj -scheme iTunesSearch \
  -testPlan iTunesSearchUITests -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

Before delivering: 0 warnings, unit tests green also with `-test-iterations 5 -run-tests-until-failure`, and UI tests green on an iPhone and an iPad simulator.

## Branches and commits

- Branches: `feature/<topic>`, `fix/<topic>`, `refactor/<topic>`, `test/<topic>`, `chore/<topic>`, `docs/<topic>`, in kebab-case.
- Flow: work on your own branch, merge into `develop` with `--no-ff`, and `develop` into `main` (with a tag) only at delivery. Never commit directly on `main` or `develop`.
- Commits: atomic, Conventional Commits in English, imperative, lowercase, subject up to 50 characters (`feat(search): add debounce`). Every commit must compile.
- The author is the repository's configured identity. Don't add co-author trailers or tool attributions.
- Don't force-push or rewrite published history.

## Restrictions

- Don't change the architecture (targets, layers or their dependencies) unless explicitly asked.
- Don't skip tests or warnings to make something pass; don't disable them.
- The Xcode project is classic (no synchronized folders): adding files to `App/` requires editing `project.pbxproj`.
- No keys or secrets. The iTunes Search API doesn't need any.
