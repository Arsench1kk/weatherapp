import Foundation
import CoreLocation

protocol LocationNameResolving {
    func resolveName(for location: CLLocation) async -> String?
}

final class ReverseGeocodingService: LocationNameResolving {

    private let geocoder = CLGeocoder()
    private var cachedLocation: CLLocation?
    private var cachedName: String?

    func resolveName(for location: CLLocation) async -> String? {
        if let cachedLocation,
           let cachedName,
           cachedLocation.distance(from: location) < 1_000 {
            return cachedName
        }

        do {
            let name = try await withThrowingTaskGroup(of: String?.self) { group in
                group.addTask { [geocoder] in
                    let placemarks = try await geocoder.reverseGeocodeLocation(location)
                    return placemarks.first?.displayName
                }

                group.addTask {
                    try await Task.sleep(nanoseconds: 2_500_000_000)
                    return nil
                }

                let result = try await group.next() ?? nil
                group.cancelAll()
                return result
            }

            if let name {
                cachedLocation = location
                cachedName = name
            }

            return name
        } catch {
            return nil
        }
    }
}

private extension CLPlacemark {
    var displayName: String? {
        [locality, subAdministrativeArea, administrativeArea, country]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }
}
