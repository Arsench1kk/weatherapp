#if DEBUG
import Foundation

struct DebugPagerScript {
    let initialCity: DebugScenarioConfig.InitialCityScenario?
    let deleteActiveCityAfter: TimeInterval?

    init?(scenario: DebugScenarioConfig) {
        guard scenario.initialCity != nil || scenario.deleteActiveCityAfter != nil else {
            return nil
        }

        initialCity = scenario.initialCity
        deleteActiveCityAfter = scenario.deleteActiveCityAfter
    }

    func initialSource(from cities: [SavedCity]) -> WeatherLocationSource? {
        guard let initialCity else { return nil }

        switch initialCity {
        case .astana:
            return cities
                .first { $0.id == DebugWeatherFixtures.astana.id }
                .map(WeatherLocationSource.fixedCity)
        }
    }
}
#endif
