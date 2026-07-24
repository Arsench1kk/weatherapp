#if DEBUG
import Foundation

struct DebugScenarioConfig {

    enum LocationScenario: String {
        case denied
        case unavailable
    }

    enum NetworkScenario: String {
        case slow
        case error
        case staleThenOffline
    }

    enum SavedCitiesScenario: String {
        case empty
        case prefilled
    }

    enum SearchScenario: String {
        case results
        case noResults
        case error
        case duplicate
    }

    enum InitialCityScenario: String {
        case astana
    }

    let location: LocationScenario?
    let network: NetworkScenario?
    let savedCities: SavedCitiesScenario?
    let theme: DebugWeatherTheme?
    let search: SearchScenario?
    let initialCity: InitialCityScenario?
    let deleteActiveCityAfter: TimeInterval?

    static var current: DebugScenarioConfig? {
        make(arguments: ProcessInfo.processInfo.arguments)
    }

    static func make(arguments: [String]) -> DebugScenarioConfig? {
        let config = DebugScenarioConfig(
            location: value(for: "-WeatherDebugLocation", in: arguments).flatMap(LocationScenario.init(rawValue:)),
            network: value(for: "-WeatherDebugNetwork", in: arguments).flatMap(NetworkScenario.init(rawValue:)),
            savedCities: value(for: "-WeatherDebugSavedCities", in: arguments).flatMap(SavedCitiesScenario.init(rawValue:)),
            theme: value(for: "-WeatherDebugTheme", in: arguments).flatMap(DebugWeatherTheme.init(rawValue:)),
            search: value(for: "-WeatherDebugSearch", in: arguments).flatMap(SearchScenario.init(rawValue:)),
            initialCity: value(for: "-WeatherDebugInitialCity", in: arguments).flatMap(InitialCityScenario.init(rawValue:)),
            deleteActiveCityAfter: value(for: "-WeatherDebugDeleteActiveCityAfter", in: arguments).flatMap(TimeInterval.init)
        )

        guard config.location != nil
            || config.network != nil
            || config.savedCities != nil
            || config.theme != nil
            || config.search != nil
            || config.initialCity != nil
            || config.deleteActiveCityAfter != nil else {
            return nil
        }

        return config
    }

    private static func value(for key: String, in arguments: [String]) -> String? {
        for (index, argument) in arguments.enumerated() {
            if argument == key,
               arguments.indices.contains(arguments.index(after: index)) {
                return arguments[arguments.index(after: index)]
            }

            let assignmentPrefix = "\(key)="
            if argument.hasPrefix(assignmentPrefix) {
                return String(argument.dropFirst(assignmentPrefix.count))
            }
        }

        return nil
    }
}
#endif
