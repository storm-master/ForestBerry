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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize(MagicConstants.signalID, withLaunchOptions: launchOptions)
        Messaging.messaging().delegate = self
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppsFlyerLib.shared().start()
    }
}

