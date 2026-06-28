import MapKit
import Combine

final class AddressSearchService: ObservableObject {
    @Published var suggestions: [MKMapItem] = []
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?

    func update(query: String) {
        searchTask?.cancel()
        guard query.count >= 2 else {
            suggestions = []
            isSearching = false
            return
        }

        searchTask = Task {
            await MainActor.run { self.isSearching = true }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = [.address, .pointOfInterest]

            let items = (try? await MKLocalSearch(request: request).start())?.mapItems ?? []

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.suggestions = Array(items.prefix(3))
                self.isSearching = false
            }
        }
    }

    func cancel() {
        searchTask?.cancel()
        suggestions = []
        isSearching = false
    }
}
