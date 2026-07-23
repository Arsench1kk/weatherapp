import Foundation

struct CitySearchCompletionModel: Equatable {
    let id: String
    let title: String
    let subtitle: String
}

@MainActor
protocol CitySearchClientProtocol: AnyObject {
    func searchCompletions(for query: String) async throws -> [CitySearchCompletionModel]
    func resolve(_ completion: CitySearchCompletionModel) async throws -> SavedCity
    func clear()
}
