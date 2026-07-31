# WeatherApp

UIKit weather app built as a junior iOS portfolio project. The goal is not to clone every Weather app feature, but to show reliable UIKit architecture, clean state handling, deterministic mentor testing, and native-feeling weather flows.

## Features

- Current-location weather using CoreLocation.
- Saved cities with persistence through `UserDefaults`.
- City search powered by MapKit search completion.
- Weather preview cards for saved cities and current location.
- Main weather screen with hero weather, hourly forecast, daily forecast, weather details, pull-to-refresh, and error states.
- Pager between current location and saved cities.
- Dynamic weather gradients by time of day and rain state.
- Lightweight last-known weather cache for offline refresh fallback.
- Debug-only launch-argument scenario harness for deterministic mentor review.

## Architecture Overview

- `DIContainer` owns construction of app services, repositories, use cases, view models, and view controllers.
- Repository layer fetches OpenWeather One Call data through `NetworkService`.
- `GetWeatherUseCase` coordinates weather fetching and last-known cache fallback.
- `SavedCitiesStoreProtocol` hides saved-city persistence behind production and debug implementations.
- `CitySearchClientProtocol` separates MapKit search from `CitySearchViewModel`.
- `CityWeatherPreviewLoader` handles preview weather loading so `CitySearchViewModel` can focus on screen state.
- UIKit view controllers own layout, binding, navigation callbacks, and user interaction.
- View models own feature state, async task cancellation, and mapping between user actions and use cases.

## Debug Scenario Harness

The debug harness is controlled only by launch arguments and is compiled behind `#if DEBUG`. There is no debug UI and Release builds use production services.

Arguments may be passed as separate values:

```text
-WeatherDebugNetwork error
```

or assignment style:

```text
-WeatherDebugNetwork=error
```

| Launch argument | Values | What it simulates |
| --- | --- | --- |
| `-WeatherDebugLocation` | `denied` | Location permission denied flow. |
| `-WeatherDebugLocation` | `unavailable` | Current location unavailable. |
| `-WeatherDebugNetwork` | `slow` | Slow weather loading. |
| `-WeatherDebugNetwork` | `error` | Weather request failure. |
| `-WeatherDebugNetwork` | `staleThenOffline` | First request succeeds with fixture data, later refresh falls back to stale/offline behavior. |
| `-WeatherDebugSavedCities` | `empty` | Empty saved cities state with in-memory debug store. |
| `-WeatherDebugSavedCities` | `prefilled` | Prefilled saved cities with in-memory debug store. |
| `-WeatherDebugTheme` | `morning` | Morning weather theme fixture. |
| `-WeatherDebugTheme` | `day` | Day weather theme fixture. |
| `-WeatherDebugTheme` | `evening` | Evening weather theme fixture. |
| `-WeatherDebugTheme` | `night` | Night weather theme fixture. |
| `-WeatherDebugTheme` | `rainNight` | Rainy night theme fixture. |
| `-WeatherDebugSearch` | `results` | Deterministic city search results. |
| `-WeatherDebugSearch` | `noResults` | Search empty state. |
| `-WeatherDebugSearch` | `error` | Search error state. |
| `-WeatherDebugSearch` | `duplicate` | Search result that should resolve to an already saved city. |
| `-WeatherDebugInitialCity` | `astana` | App boots to the seeded Astana saved-city page. |
| `-WeatherDebugDeleteActiveCityAfter` | seconds, for example `2` | Deletes the active saved city after a delay to test pager recovery. |

Debug scenarios use mock services and in-memory stores. They do not mutate real saved cities in `UserDefaults`.

## Useful Mentor Testing Combinations

```text
-WeatherDebugSavedCities prefilled
```
Check pager, saved city cards, and normal city switching.

```text
-WeatherDebugLocation denied
```
Check permission-denied messaging and retry behavior.

```text
-WeatherDebugSearch noResults
```
Check city search empty state.

```text
-WeatherDebugSearch error
```
Check city search error state.

```text
-WeatherDebugSearch duplicate
-WeatherDebugSavedCities prefilled
```
Check that duplicate city selection navigates to the stored city instead of adding another copy.

```text
-WeatherDebugInitialCity astana
-WeatherDebugDeleteActiveCityAfter 2
```
Check active-city deletion and pager recovery.

```text
-WeatherDebugNetwork staleThenOffline
-WeatherDebugSavedCities prefilled
```
Check last-known weather fallback and stale/offline indicator after refresh.

```text
-WeatherDebugTheme rainNight
```
Check rainy night visual treatment and card readability.

## Manual QA Checklist

- Launch fresh install with no saved cities.
- Grant location permission and verify current-location weather loads.
- Deny location permission and verify the app shows a useful error state.
- Pull to refresh on current location and on a saved city.
- Search for a city, add it, and verify the pager opens the selected city.
- Try adding the same city twice and verify it resolves to the existing saved city.
- Delete a non-active saved city.
- Delete the active saved city and verify pager selection recovers cleanly.
- Verify empty, loading, error, and no-results states on city search.
- Turn on VoiceOver and check bottom controls, pager indicator, search field, search results, cards, forecast rows, detail cards, and retry controls.
- Test small and large iPhone simulators for clipped text or unsafe-area issues.
- Test offline fallback by loading weather once, forcing network failure, and refreshing.
- Build both Debug and Release.

## Known Limitations

- The API key is visible intentionally for this learning project.
- No full `.strings` localization system yet; user-facing text is kept simple and consistently Russian in code.
- Weather cache is lightweight last-known data, not a full offline data model with expiry policy or cache management UI.
- Automated test coverage is intentionally minimal; mentor testing is mainly manual plus deterministic debug launch scenarios.
- Map/list bottom controls are intentionally limited while the portfolio focus is reliability, city search, saved cities, and weather presentation.

## Setup and Build

Requirements:

- Xcode with an iOS Simulator runtime.
- Internet access for real OpenWeather and MapKit flows.

Open in Xcode:

```sh
open WeatherApp.xcodeproj
```

Build Debug from terminal:

```sh
xcodebuild -project WeatherApp.xcodeproj \
  -scheme WeatherApp \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Build Release from terminal:

```sh
xcodebuild -project WeatherApp.xcodeproj \
  -scheme WeatherApp \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Run with debug launch arguments in Xcode:

1. Select the `WeatherApp` scheme.
2. Open **Edit Scheme**.
3. Choose **Run > Arguments**.
4. Add the desired launch arguments from the table above.
5. Run a Debug build.

Release builds should be tested without debug launch arguments.
