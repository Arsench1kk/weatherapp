#if DEBUG
import Foundation

final class DebugSavedCitiesStore: SavedCitiesStoreProtocol {

    private var cities: [SavedCity]

    init(cities: [SavedCity] = []) {
        self.cities = cities
    }

    func loadCities() -> [SavedCity] {
        cities
    }

    func saveCities(_ cities: [SavedCity]) {
        self.cities = cities
        notifySavedCitiesDidChange()
    }

    @discardableResult
    func saveCityIfNeeded(_ city: SavedCity) -> AddCityResult {
        if let existingCity = cities.first(where: { isDuplicate($0, city) }) {
            return .existing(existingCity)
        }

        cities.append(city)
        notifySavedCitiesDidChange()
        return .added(city)
    }

    func removeCity(id: String) {
        let originalCount = cities.count
        cities.removeAll { $0.id == id }

        guard cities.count != originalCount else { return }
        notifySavedCitiesDidChange()
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
#endif
