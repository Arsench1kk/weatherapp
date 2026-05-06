import Foundation

enum CitySelection {
    case currentLocation
    case savedCity(SavedCity)
}

enum CityWeatherPreviewState {
    case loading
    case loaded(temperature: String, description: String, symbolName: String, highLow: String)
    case error(String)
}

struct CityWeatherPreviewUIModel {
    static let currentLocationID = "current-location"

    let id: String
    let title: String
    let subtitle: String
    let isCurrentLocation: Bool
    let city: SavedCity?
    let theme: WeatherTheme
    var state: CityWeatherPreviewState
}

struct CitySearchSuggestionUIModel {
    let title: String
    let subtitle: String
}

enum CitySearchResultsState {
    case emptyQuery
    case searching
    case results([CitySearchSuggestionUIModel])
    case noResults
    case error(String)
}

struct CitySearchState {
    let cityPreviews: [CityWeatherPreviewUIModel]
    let resultsState: CitySearchResultsState
}
