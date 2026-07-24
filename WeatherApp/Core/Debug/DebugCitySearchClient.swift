#if DEBUG
import Foundation

final class DebugCitySearchClient: CitySearchClientProtocol {

    private let scenario: DebugScenarioConfig.SearchScenario
    private let completionsByID: [String: SavedCity]

    init(scenario: DebugScenarioConfig.SearchScenario) {
        self.scenario = scenario
        completionsByID = Dictionary(
            uniqueKeysWithValues: DebugWeatherFixtures.prefilledCities.map { city in
                (city.id, city)
            }
        )
    }

    func searchCompletions(for query: String) async throws -> [CitySearchCompletionModel] {
        try Task.checkCancellation()

        switch scenario {
        case .results:
            return DebugWeatherFixtures.prefilledCities.map(makeCompletion)
        case .noResults:
            return []
        case .error:
            throw DebugCitySearchError.searchFailed
        case .duplicate:
            return [makeCompletion(from: DebugWeatherFixtures.almaty)]
        }
    }

    func resolve(_ completion: CitySearchCompletionModel) async throws -> SavedCity {
        try Task.checkCancellation()

        guard let city = completionsByID[completion.id] else {
            throw DebugCitySearchError.resolveFailed
        }

        return city
    }

    func clear() {}

    private func makeCompletion(from city: SavedCity) -> CitySearchCompletionModel {
        CitySearchCompletionModel(
            id: city.id,
            title: city.name,
            subtitle: city.subtitle
        )
    }
}

private enum DebugCitySearchError: Error {
    case searchFailed
    case resolveFailed
}
#endif
