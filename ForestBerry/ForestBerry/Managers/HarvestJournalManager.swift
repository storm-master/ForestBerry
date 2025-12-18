import Foundation

final class HarvestJournalManager {
    static let shared = HarvestJournalManager()

    private let storageKey = "harvest_entries_storage"
    private let defaults = UserDefaults.standard

    func loadEntries() -> [HarvestEntry] {
        guard
            let data = defaults.data(forKey: storageKey),
            let entries = try? JSONDecoder().decode([HarvestEntry].self, from: data)
        else {
            return []
        }
        return entries
    }

    func addEntry(_ entry: HarvestEntry) {
        var entries = loadEntries()
        entries.append(entry)
        save(entries)
    }

    func updateEntry(_ entry: HarvestEntry) {
        var entries = loadEntries()
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            save(entries)
        }
    }

    func deleteEntry(_ entry: HarvestEntry) {
        var entries = loadEntries()
        entries.removeAll { $0.id == entry.id }
        save(entries)
    }
    
    func clearAll() {
        defaults.removeObject(forKey: storageKey)
    }

    private func save(_ entries: [HarvestEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

