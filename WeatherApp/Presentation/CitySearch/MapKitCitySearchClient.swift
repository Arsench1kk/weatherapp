import Foundation
import MapKit

final class MapKitCitySearchClient: NSObject, CitySearchClientProtocol {

    private struct SearchRequest {
        let token: UUID
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

        let token = UUID()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                cancelCurrentRequest()
                completionCache.removeAll()

                currentRequest = SearchRequest(
                    token: token,
                    query: query,
                    continuation: continuation
                )
                completer.queryFragment = query
            }
        } onCancel: {
            Task { @MainActor [weak self, token] in
                self?.cancelRequest(token: token)
            }
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
        cancelCurrentRequest()
        completionCache.removeAll()
        completer.queryFragment = ""
    }

    private func cancelCurrentRequest() {
        guard let request = currentRequest else { return }
        currentRequest = nil
        request.continuation.resume(throwing: CancellationError())
    }

    private func cancelRequest(token: UUID) {
        guard currentRequest?.token == token else { return }
        cancelCurrentRequest()
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
        guard let request = currentRequest,
              completer.queryFragment == request.query else {
            return
        }

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
        guard let request = currentRequest,
              completer.queryFragment == request.query else {
            return
        }

        finishCurrentRequest(with: .failure(error))
    }
}
