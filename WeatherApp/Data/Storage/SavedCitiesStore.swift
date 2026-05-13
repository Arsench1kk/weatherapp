import Foundation

extension Notification.Name {
    static let savedCitiesDidChange = Notification.Name("SavedCitiesStore.savedCitiesDidChange")
}

protocol SavedCitiesStoreProtocol {
    func loadCities() -> [SavedCity]
    func saveCities(_ cities: [SavedCity])
    @discardableResult func addCity(_ city: SavedCity) -> Bool
    func removeCity(id: String)
}

final class UserDefaultsSavedCitiesStore: SavedCitiesStoreProtocol {

    private let userDefaults: UserDefaults
    private let storageKey = "savedCities.v1"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadCities() -> [SavedCity] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        return (try? JSONDecoder().decode([SavedCity].self, from: data)) ?? []
    }

    func saveCities(_ cities: [SavedCity]) {
        guard persistCities(cities) else { return }
        notifySavedCitiesDidChange()
    }

    @discardableResult
    func addCity(_ city: SavedCity) -> Bool {
        var cities = loadCities()
        guard !cities.contains(where: { isDuplicate($0, city) }) else {
            return false
        }

        cities.append(city)
        guard persistCities(cities) else { return false }
        notifySavedCitiesDidChange()
        return true
    }

    func removeCity(id: String) {
        var cities = loadCities()
        let originalCount = cities.count
        cities.removeAll { $0.id == id }
        guard cities.count != originalCount,
              persistCities(cities) else {
            return
        }

        notifySavedCitiesDidChange()
    }

    private func persistCities(_ cities: [SavedCity]) -> Bool {
        guard let data = try? JSONEncoder().encode(cities) else { return false }
        userDefaults.set(data, forKey: storageKey)
        return true
    }

    private func notifySavedCitiesDidChange() {
        NotificationCenter.default.post(name: .savedCitiesDidChange, object: self)
    }

    private func isDuplicate(_ lhs: SavedCity, _ rhs: SavedCity) -> Bool {
        let namesMatch = normalized(lhs.name) == normalized(rhs.name)
            && normalized(lhs.subtitle) == normalized(rhs.subtitle)

        let coordinatesMatch = roundedCoordinate(lhs.latitude) == roundedCoordinate(rhs.latitude)
            && roundedCoordinate(lhs.longitude) == roundedCoordinate(rhs.longitude)

        return namesMatch || coordinatesMatch
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func roundedCoordinate(_ value: Double) -> Int {
        Int((value * 1000).rounded())
    }
}
