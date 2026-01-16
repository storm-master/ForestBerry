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

import Alamofire
import SwiftUI
import Combine
import AppTrackingTransparency
import AdSupport
import CryptoKit
import FirebaseCore
import FirebaseRemoteConfig
import FirebaseMessaging
import OneSignalFramework
import AppsFlyerLib
import WebKit

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching remote FCM registration token: \(error)")
            } else if let token = token {
                print("Remote instance ID token: \(token)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

extension Notification.Name {
    static let notificationRequestCompleted = Notification.Name("notificationRequestCompleted")
    static let trackingRequestCompleted = Notification.Name("trackingRequestCompleted")
}

enum AppStateType {
    case loading
    case original
    case magic
}
