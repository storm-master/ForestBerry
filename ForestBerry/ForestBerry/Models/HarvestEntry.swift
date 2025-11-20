import Foundation

struct HarvestEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let berryType: String
    let quantity: Double
    let unit: HarvestUnit
    let notes: String
    let imageData: Data?

    init(id: UUID = UUID(), date: Date, berryType: String, quantity: Double, unit: HarvestUnit, notes: String, imageData: Data?) {
        self.id = id
        self.date = date
        self.berryType = berryType
        self.quantity = quantity
        self.unit = unit
        self.notes = notes
        self.imageData = imageData
    }
}

enum HarvestUnit: String, CaseIterable, Codable {
    case liters
    case kilograms
    case baskets

    var displayName: String { rawValue }
}

extension HarvestEntry {
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }

    var quantityFormatted: String {
        if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", quantity)
        } else {
            return String(format: "%.2f", quantity)
        }
    }
}

