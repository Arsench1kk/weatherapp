import Foundation

enum MainScreenState {
    case loading
    case loaded(MainWeatherUIModel)
    case error(String)
}
