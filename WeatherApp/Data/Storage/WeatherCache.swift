import Foundation

protocol WeatherCacheProtocol {
    func cachedResponse(for key: String) -> OneCallResponse?
    func save(_ response: OneCallResponse, for key: String)
}

final class UserDefaultsWeatherCache: WeatherCacheProtocol {

    private let defaults: UserDefaults
    private let storageKey = "weather.lastKnown.responses"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func cachedResponse(for key: String) -> OneCallResponse? {
        guard let data = storage()[key] else { return nil }
        return try? decoder.decode(OneCallResponse.self, from: data)
    }

    func save(_ response: OneCallResponse, for key: String) {
        guard let data = try? encoder.encode(response) else { return }
        var storage = storage()
        storage[key] = data
        defaults.set(storage, forKey: storageKey)
    }

    private func storage() -> [String: Data] {
        defaults.dictionary(forKey: storageKey) as? [String: Data] ?? [:]
    }
}

final class InMemoryWeatherCache: WeatherCacheProtocol {

    private var storage: [String: OneCallResponse] = [:]

    func cachedResponse(for key: String) -> OneCallResponse? {
        storage[key]
    }

    func save(_ response: OneCallResponse, for key: String) {
        storage[key] = response
    }
}
