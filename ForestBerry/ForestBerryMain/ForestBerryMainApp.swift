import SwiftUI

@main
struct ForestBerryMainApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MagicView {
                LoadingView()
            }
        }
    }
}

enum MagicConstants {
    static let remoteConfigKey = "isForestBerryEnable"
    static let endpoint_name = "linka"
    static let salt_name = "solya"
    static let signalID = "6b13dbdb-6628-41b4-9ad5-7db908653794"
    static let developerKey = "developerKey"
    static let companyURL = "campaignURL"
    static let flyID = "6755539235"
}

