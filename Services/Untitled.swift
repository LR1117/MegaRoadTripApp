
import MapKit
import Combine

class AddressSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()

    @Published var suggestions: [MKLocalSearchCompletion] = []
    @Published var isSearching = false

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func update(query: String) {
        if query.isEmpty {
            suggestions = []
            return
        }
        isSearching = true
        completer.queryFragment = query
    }

    func cancel() {
        completer.cancel()
        suggestions = []
        isSearching = false
    }

    // Resolve a completion into a full MKMapItem with coordinates
    func resolve(_ completion: MKLocalSearchCompletion) async -> MKMapItem? {
        let request = MKLocalSearch.Request(completion: completion)
        guard let response = try? await MKLocalSearch(request: request).start() else { return nil }
        return response.mapItems.first
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = Array(completer.results.prefix(6))
            self.isSearching = false
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.suggestions = []
            self.isSearching = false
        }
    }
}
