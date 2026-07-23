import Foundation
import MapKit

final class MapKitCitySearchClient: NSObject, CitySearchClientProtocol {

    private struct SearchRequest {
        let id: UUID
        let query: String
        let continuation: CheckedContinuation<[CitySearchCompletionModel], Error>
    }

    private let completer = MKLocalSearchCompleter()
    private var currentRequest: SearchRequest?
    private var completionCache: [String: MKLocalSearchCompletion] = [:]

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func searchCompletions(for query: String) async throws -> [CitySearchCompletionModel] {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            finishCurrentRequest(with: .failure(CancellationError()))
            completionCache.removeAll()

            currentRequest = SearchRequest(
                id: UUID(),
                query: query,
                continuation: continuation
            )
            completer.queryFragment = query
        }
    }

    func resolve(_ completion: CitySearchCompletionModel) async throws -> SavedCity {
        guard let mapKitCompletion = completionCache[completion.id] else {
            throw LocationError.locationUnavailable
        }

        let request = MKLocalSearch.Request(completion: mapKitCompletion)
        let response = try await MKLocalSearch(request: request).start()

        guard let mapItem = response.mapItems.first else {
            throw LocationError.locationUnavailable
        }

        let placemark = mapItem.placemark
        return SavedCity(
            name: makeCityName(from: placemark, fallback: completion.title),
            subtitle: makeSubtitle(from: placemark, fallback: completion.subtitle),
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude
        )
    }

    func clear() {
        finishCurrentRequest(with: .failure(CancellationError()))
        completionCache.removeAll()
        completer.queryFragment = ""
    }

    private func finishCurrentRequest(with result: Result<[CitySearchCompletionModel], Error>) {
        guard let request = currentRequest else { return }
        currentRequest = nil

        switch result {
        case .success(let completions):
            request.continuation.resume(returning: completions)
        case .failure(let error):
            request.continuation.resume(throwing: error)
        }
    }

    private func makeCityName(from placemark: MKPlacemark, fallback: String) -> String {
        [placemark.locality, placemark.name, placemark.administrativeArea]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? fallback
    }

    private func makeSubtitle(from placemark: MKPlacemark, fallback: String) -> String {
        let parts = [placemark.administrativeArea, placemark.country]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !parts.isEmpty {
            return parts.joined(separator: ", ")
        }

        return fallback.isEmpty ? "Сохранённый город" : fallback
    }
}

extension MapKitCitySearchClient: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        guard currentRequest != nil else { return }

        let completions = completer.results.enumerated().map { index, completion in
            let model = CitySearchCompletionModel(
                id: "\(index):\(completion.title):\(completion.subtitle)",
                title: completion.title,
                subtitle: completion.subtitle
            )
            completionCache[model.id] = completion
            return model
        }

        finishCurrentRequest(with: .success(completions))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        finishCurrentRequest(with: .failure(error))
    }
}
