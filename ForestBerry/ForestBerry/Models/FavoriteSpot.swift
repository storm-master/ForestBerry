import Foundation

struct FavoriteSpot: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var name: String
    var directions: String
    var type: SpotType
    var imageData: Data

    init(id: UUID = UUID(), createdAt: Date = Date(), name: String, directions: String, type: SpotType, imageData: Data) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.directions = directions
        self.type = type
        self.imageData = imageData
    }
}

enum SpotType: String, CaseIterable, Codable {
    case crop
    case rareBerries

    var displayName: String {
        switch self {
        case .crop: return "Crop"
        case .rareBerries: return "Rare berries"
        }
    }

    var assetName: String {
        switch self {
        case .crop: return "crop_pick"
        case .rareBerries: return "rare_berries_pick"
        }
    }
    
    var iconName: String {
        switch self {
        case .crop: return "basket_icon"
        case .rareBerries: return "berries_icon"
        }
    }
}

