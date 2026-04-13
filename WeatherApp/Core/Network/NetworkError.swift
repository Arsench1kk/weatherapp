import Foundation

enum NetworkError: Error, LocalizedError {
    
    // URL
    case invalidURL
    case invalidResponse
    
    // Connectivity
    case noInternetConnection
    case timeout
    case connectionLost
    
    // HTTP 4xx
    case badRequest              // 400
    case unauthorized            // 401 — неверный API ключ
    case forbidden               // 403
    case notFound                // 404
    case rateLimited             // 429 — превышен лимит запросов
    case unexpectedStatusCode(Int)
    
    // HTTP 5xx
    case serverError(Int)
    
    // Parsing
    case decodingFailed(Error)
    
    // Other
    case unknown(Error)
    
    // MARK: - Локализованное описание для UI
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL запроса"
        case .invalidResponse:
            return "Получен некорректный ответ от сервера"
        case .noInternetConnection:
            return "Нет подключения к интернету"
        case .timeout:
            return "Превышено время ожидания. Проверьте соединение"
        case .connectionLost:
            return "Соединение было прервано"
        case .badRequest:
            return "Неверный запрос (400)"
        case .unauthorized:
            return "Неверный API ключ. Проверьте настройки (401)"
        case .forbidden:
            return "Доступ запрещён (403)"
        case .notFound:
            return "Данные не найдены (404)"
        case .rateLimited:
            return "Превышен лимит запросов. Попробуйте позже (429)"
        case .unexpectedStatusCode(let code):
            return "Неожиданный ответ сервера: \(code)"
        case .serverError(let code):
            return "Ошибка сервера: \(code). Попробуйте позже"
        case .decodingFailed(let error):
            return "Ошибка разбора данных: \(error.localizedDescription)"
        case .unknown(let error):
            return "Неизвестная ошибка: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Маппинг URLError → NetworkError
    
    static func map(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost where urlError.code == .notConnectedToInternet:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        case .networkConnectionLost:
            return .connectionLost
        default:
            return .unknown(urlError)
        }
    }
}
