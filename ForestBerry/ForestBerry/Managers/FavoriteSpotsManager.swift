import Foundation

final class FavoriteSpotsManager {
    static let shared = FavoriteSpotsManager()

    private let storageKey = "favorite_spots_storage"
    private let defaults = UserDefaults.standard

    func loadSpots() -> [FavoriteSpot] {
        guard
            let data = defaults.data(forKey: storageKey),
            let spots = try? JSONDecoder().decode([FavoriteSpot].self, from: data)
        else {
            return []
        }
        return spots
    }

    func addSpot(_ spot: FavoriteSpot) {
        var spots = loadSpots()
        spots.append(spot)
        save(spots)
    }
    
    func updateSpot(_ updatedSpot: FavoriteSpot) {
        var spots = loadSpots()
        if let index = spots.firstIndex(where: { $0.id == updatedSpot.id }) {
            spots[index] = updatedSpot
            save(spots)
        }
    }
    
    func deleteSpot(_ spot: FavoriteSpot) {
        var spots = loadSpots()
        spots.removeAll { $0.id == spot.id }
        save(spots)
    }
    
    func clearAll() {
        defaults.removeObject(forKey: storageKey)
    }

    private func save(_ spots: [FavoriteSpot]) {
        guard let data = try? JSONEncoder().encode(spots) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

