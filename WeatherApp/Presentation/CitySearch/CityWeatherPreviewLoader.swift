import Foundation
import CoreLocation

struct CityWeatherPreviewUpdate {
    let id: String
    let title: String?
    let subtitle: String?
    let theme: WeatherTheme?
    let state: CityWeatherPreviewState
}

@MainActor
final class CityWeatherPreviewLoader {

    private let getWeatherUseCase: GetWeatherUseCaseProtocol
    private let currentLocationProvider: CurrentLocationProviderProtocol
    private let locationNameResolver: LocationNameResolving
    private let mapper = CityWeatherPreviewMapper()

    init(
        getWeatherUseCase: GetWeatherUseCaseProtocol,
        currentLocationProvider: CurrentLocationProviderProtocol,
        locationNameResolver: LocationNameResolving
    ) {
        self.getWeatherUseCase = getWeatherUseCase
        self.currentLocationProvider = currentLocationProvider
        self.locationNameResolver = locationNameResolver
    }

    func makeInitialPreviews(savedCities: [SavedCity]) -> [CityWeatherPreviewUIModel] {
        let currentLocationPreview = CityWeatherPreviewUIModel(
            id: CityWeatherPreviewUIModel.currentLocationID,
            title: "Текущее местоположение",
            subtitle: "Определяется автоматически",
            isCurrentLocation: true,
            city: nil,
            theme: .current,
            state: .loading
        )

        let savedPreviews = savedCities.map { city in
            CityWeatherPreviewUIModel(
                id: city.id,
                title: city.name,
                subtitle: city.subtitle,
                isCurrentLocation: false,
                city: city,
                theme: .current,
                state: .loading
            )
        }

        return [currentLocationPreview] + savedPreviews
    }

    func loadCurrentLocationPreview() async -> CityWeatherPreviewUpdate? {
        do {
            let location = try await currentLocationProvider.requestCurrentLocation()
            async let resolvedName = locationNameResolver.resolveName(for: location)
            let response = try await getWeatherUseCase.execute(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude
            )
            try Task.checkCancellation()

            let locationName = await resolvedName ?? "Моё местоположение"
            return CityWeatherPreviewUpdate(
                id: CityWeatherPreviewUIModel.currentLocationID,
                title: locationName,
                subtitle: "Текущее местоположение",
                theme: mapper.makeWeatherTheme(from: response),
                state: mapper.makeLoadedPreviewState(from: response)
            )
        } catch is CancellationError {
            return nil
        } catch {
            return CityWeatherPreviewUpdate(
                id: CityWeatherPreviewUIModel.currentLocationID,
                title: nil,
                subtitle: nil,
                theme: nil,
                state: .error("Геолокация недоступна")
            )
        }
    }

    func loadSavedCityPreview(_ city: SavedCity) async -> CityWeatherPreviewUpdate? {
        do {
            let response = try await getWeatherUseCase.execute(
                lat: city.latitude,
                lon: city.longitude
            )
            try Task.checkCancellation()

            return CityWeatherPreviewUpdate(
                id: city.id,
                title: nil,
                subtitle: mapper.makeLocalTimeText(
                    timezoneIdentifier: response.timezone,
                    timezoneOffset: response.timezoneOffset
                ),
                theme: mapper.makeWeatherTheme(from: response),
                state: mapper.makeLoadedPreviewState(from: response)
            )
        } catch is CancellationError {
            return nil
        } catch {
            return CityWeatherPreviewUpdate(
                id: city.id,
                title: nil,
                subtitle: nil,
                theme: nil,
                state: .error("Превью недоступно")
            )
        }
    }
}

struct CityWeatherPreviewMapper {

    private let formatter = WeatherFormattingService()

    func makeLoadedPreviewState(from response: OneCallResponse) -> CityWeatherPreviewState {
        let day = response.daily.first
        let highLow = formatter.highLowText(
            highCelsius: day?.temp.max ?? response.current.temp,
            lowCelsius: day?.temp.min ?? response.current.temp
        )

        return .loaded(
            temperature: formatter.temperature(response.current.temp),
            description: sentenceCapitalized(response.current.weather?.first?.description ?? "Нет данных"),
            symbolName: WeatherMapper.sfSymbol(for: response.current.weather?.first?.icon ?? "01d"),
            highLow: highLow
        )
    }

    func makeWeatherTheme(from response: OneCallResponse) -> WeatherTheme {
        WeatherTheme(
            timeOfDay: TimeOfDay.fromTimezone(offset: response.timezoneOffset),
            isRaining: isCurrentlyRaining(current: response.current)
        )
    }

    func makeLocalTimeText(timezoneIdentifier: String, timezoneOffset: Int) -> String {
        formatter.localTime(
            timezoneIdentifier: timezoneIdentifier,
            timezoneOffset: timezoneOffset
        )
    }

    private func isCurrentlyRaining(current: CurrentWeather) -> Bool {
        guard let weatherId = current.weather?.first?.id else { return false }
        return (200..<600).contains(weatherId)
    }

    private func sentenceCapitalized(_ text: String) -> String {
        guard let firstCharacter = text.first else { return text }
        return firstCharacter.uppercased() + text.dropFirst().lowercased()
    }
}
