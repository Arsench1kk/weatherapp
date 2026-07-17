import Foundation
import CoreLocation
import MapKit

final class CitySearchViewModel: NSObject {

    var onStateChanged: ((CitySearchState) -> Void)?
    var onCitySelected: ((CitySelection) -> Void)?

    private let savedCitiesStore: SavedCitiesStoreProtocol
    private let getWeatherUseCase: GetWeatherUseCaseProtocol
    private let currentLocationProvider: CurrentLocationProviderProtocol
    private let locationNameResolver: LocationNameResolving
    private let completer = MKLocalSearchCompleter()

    private var savedCities: [SavedCity] = []
    private var cityPreviews: [CityWeatherPreviewUIModel] = []
    private var searchResultsState: CitySearchResultsState = .emptyQuery
    private var completions: [MKLocalSearchCompletion] = []
    private var debounceTask: Task<Void, Never>?
    private var previewTasks: [Task<Void, Never>] = []
    private var selectionTask: Task<Void, Never>?

    init(
        savedCitiesStore: SavedCitiesStoreProtocol,
        getWeatherUseCase: GetWeatherUseCaseProtocol,
        currentLocationProvider: CurrentLocationProviderProtocol,
        locationNameResolver: LocationNameResolving
    ) {
        self.savedCitiesStore = savedCitiesStore
        self.getWeatherUseCase = getWeatherUseCase
        self.currentLocationProvider = currentLocationProvider
        self.locationNameResolver = locationNameResolver
        super.init()

        completer.delegate = self
        completer.resultTypes = .address
    }

    deinit {
        debounceTask?.cancel()
        previewTasks.forEach { $0.cancel() }
        selectionTask?.cancel()
    }

    func viewDidLoad() {
        reloadSavedCities()
        loadWeatherPreviews()
    }

    func updateQuery(_ query: String) {
        debounceTask?.cancel()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            completions = []
            searchResultsState = .emptyQuery
            completer.queryFragment = ""
            emitState()
            return
        }

        searchResultsState = .searching
        emitState()

        debounceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                self?.completer.queryFragment = trimmedQuery
            } catch {
                return
            }
        }
    }

    func clearSearch() {
        debounceTask?.cancel()
        completions = []
        completer.queryFragment = ""
        searchResultsState = .emptyQuery
        emitState()
    }

    func selectSavedCity(at index: Int) {
        guard cityPreviews.indices.contains(index) else { return }
        let preview = cityPreviews[index]

        if preview.isCurrentLocation {
            onCitySelected?(.currentLocation)
            return
        }

        guard let city = preview.city else { return }
        onCitySelected?(.savedCity(city))
    }

    func canDeleteCity(at index: Int) -> Bool {
        guard cityPreviews.indices.contains(index) else { return false }
        return !cityPreviews[index].isCurrentLocation
    }

    func deleteCity(at index: Int) {
        guard canDeleteCity(at: index), let city = cityPreviews[index].city else { return }
        savedCitiesStore.removeCity(id: city.id)
        reloadSavedCities()
        loadWeatherPreviews()
    }

    func selectSearchResult(at index: Int) {
        guard completions.indices.contains(index) else { return }

        let selectedCompletion = completions[index]
        searchResultsState = .searching
        emitState()

        selectionTask?.cancel()
        selectionTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let mapItem = try await self.resolveMapItem(for: selectedCompletion)
                let placemark = mapItem.placemark
                let city = SavedCity(
                    name: self.makeCityName(from: placemark, fallback: selectedCompletion.title),
                    subtitle: self.makeSubtitle(from: placemark, fallback: selectedCompletion.subtitle),
                    latitude: placemark.coordinate.latitude,
                    longitude: placemark.coordinate.longitude
                )

                self.savedCitiesStore.addCity(city)
                self.clearSearch()
                self.reloadSavedCities()
                self.loadWeatherPreviews()
                self.onCitySelected?(.savedCity(city))
            } catch {
                self.searchResultsState = .error("Не удалось получить координаты города")
                self.emitState()
            }
        }
    }

    private func reloadSavedCities() {
        savedCities = savedCitiesStore.loadCities()
        cityPreviews = makeInitialPreviews()
        emitState()
    }

    private func makeInitialPreviews() -> [CityWeatherPreviewUIModel] {
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

    private func loadWeatherPreviews() {
        previewTasks.forEach { $0.cancel() }
        previewTasks.removeAll()

        loadCurrentLocationPreview()
        savedCities.forEach(loadSavedCityPreview)
    }

    private func loadCurrentLocationPreview() {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let location = try await self.currentLocationProvider.requestCurrentLocation()
                async let resolvedName = self.locationNameResolver.resolveName(for: location)
                let response = try await self.getWeatherUseCase.execute(
                    lat: location.coordinate.latitude,
                    lon: location.coordinate.longitude
                )
                guard !Task.isCancelled else { return }

                let locationName = await resolvedName ?? "My Location"
                self.updatePreview(
                    id: CityWeatherPreviewUIModel.currentLocationID,
                    title: locationName,
                    subtitle: "My Location • Home",
                    theme: self.makeWeatherTheme(from: response),
                    state: self.makeLoadedPreviewState(from: response)
                )
            } catch {
                guard !Task.isCancelled else { return }
                self.updatePreview(
                    id: CityWeatherPreviewUIModel.currentLocationID,
                    state: .error("Геолокация недоступна")
                )
            }
        }

        previewTasks.append(task)
    }

    private func loadSavedCityPreview(_ city: SavedCity) {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let response = try await self.getWeatherUseCase.execute(
                    lat: city.latitude,
                    lon: city.longitude
                )
                guard !Task.isCancelled else { return }
                self.updatePreview(
                    id: city.id,
                    subtitle: self.makeLocalTimeText(timezoneOffset: response.timezoneOffset),
                    theme: self.makeWeatherTheme(from: response),
                    state: self.makeLoadedPreviewState(from: response)
                )
            } catch {
                guard !Task.isCancelled else { return }
                self.updatePreview(id: city.id, state: .error("Превью недоступно"))
            }
        }

        previewTasks.append(task)
    }

    private func updatePreview(
        id: String,
        title: String? = nil,
        subtitle: String? = nil,
        theme: WeatherTheme? = nil,
        state: CityWeatherPreviewState
    ) {
        guard let index = cityPreviews.firstIndex(where: { $0.id == id }) else { return }
        let currentPreview = cityPreviews[index]

        cityPreviews[index] = CityWeatherPreviewUIModel(
            id: currentPreview.id,
            title: title ?? currentPreview.title,
            subtitle: subtitle ?? currentPreview.subtitle,
            isCurrentLocation: currentPreview.isCurrentLocation,
            city: currentPreview.city,
            theme: theme ?? currentPreview.theme,
            state: state
        )
        emitState()
    }

    private func makeLoadedPreviewState(from response: OneCallResponse) -> CityWeatherPreviewState {
        let formatter = WeatherFormattingService()
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

    private func makeWeatherTheme(from response: OneCallResponse) -> WeatherTheme {
        WeatherTheme(
            timeOfDay: TimeOfDay.fromTimezone(offset: response.timezoneOffset),
            isRaining: isCurrentlyRaining(current: response.current)
        )
    }

    private func isCurrentlyRaining(current: CurrentWeather) -> Bool {
        guard let weatherId = current.weather?.first?.id else { return false }
        return (200..<600).contains(weatherId)
    }

    private func makeLocalTimeText(timezoneOffset: Int) -> String {
        WeatherFormattingService().localTime(timezoneOffset: timezoneOffset)
    }

    private func resolveMapItem(for completion: MKLocalSearchCompletion) async throws -> MKMapItem {
        let request = MKLocalSearch.Request(completion: completion)
        let response = try await MKLocalSearch(request: request).start()

        guard let mapItem = response.mapItems.first else {
            throw LocationError.locationUnavailable
        }

        return mapItem
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

    private func sentenceCapitalized(_ text: String) -> String {
        guard let firstCharacter = text.first else { return text }
        return firstCharacter.uppercased() + text.dropFirst().lowercased()
    }

    private func emitState() {
        onStateChanged?(CitySearchState(
            cityPreviews: cityPreviews,
            resultsState: searchResultsState
        ))
    }
}

extension CitySearchViewModel: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
        let suggestions = completions.map {
            CitySearchSuggestionUIModel(title: $0.title, subtitle: $0.subtitle)
        }

        searchResultsState = suggestions.isEmpty ? .noResults : .results(suggestions)
        emitState()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = []
        searchResultsState = .error("Не удалось выполнить поиск")
        emitState()
    }
}
