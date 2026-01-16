import SwiftUI
import UIKit

struct FBJournalView: View {
    @State private var entries: [HarvestEntry] = []
    @State private var isPresentingAddFee = false
    @State private var selectedEntry: HarvestEntry?

    var body: some View {
        ForestBerryScreen(title: "Harvest Journal") {
            content
                .onAppear(perform: loadEntries)
        }
        .fullScreenCover(isPresented: $isPresentingAddFee, onDismiss: loadEntries) {
            FBAddFeeView(isPresented: $isPresentingAddFee) { _ in
                loadEntries()
            }
        }
        .fullScreenCover(item: $selectedEntry) { entry in
            FBJournalDetailView(entry: entry, onDelete: { deleted in
                entries.removeAll { $0.id == deleted.id }
                selectedEntry = nil
            }, onUpdate: { updated in
                if let index = entries.firstIndex(where: { $0.id == updated.id }) {
                    entries[index] = updated
                }
                selectedEntry = updated
            })
        }
    }
}

private extension FBJournalView {
    var content: some View {
        VStack(spacing: 16) {
            if entries.isEmpty {
                Button(action: { isPresentingAddFee = true }) {
                    Image("journal_nodata")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.plain)
                .padding(.top, 40)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(entries) { entry in
                            Button {
                                selectedEntry = entry
                            } label: {
                                JournalEntryCard(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                Button(action: { isPresentingAddFee = true }) {
                    Image("button_background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 168, height: 64)
                        .overlay(
                            Text("ADD")
                                .font(.custom("Copperplate-Bold", size: 24))
                                .foregroundColor(.white)
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    func loadEntries() {
        entries = HarvestJournalManager.shared.loadEntries().sorted { $0.date > $1.date }
    }
}

private struct JournalEntryCard: View {
    let entry: HarvestEntry

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 18) {
                VStack(spacing: 6) {
                    if let data = entry.imageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .clipped()
                    } else {
                        Image("add_photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Text(entry.berryType)
                        .font(.custom("Copperplate-Bold", size: 18))
                        .foregroundColor(.white)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            VStack(spacing: 4) {
                Text(entry.quantityFormatted)
                    .font(.custom("Copperplate-Bold", size: 22))
                    .foregroundColor(.white)

                Text(entry.unit.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(
                Image("picker_background")
                    .resizable(capInsets: EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24), resizingMode: .stretch)
            )
            .frame(width: 110)
            .padding(.top, 10)
            .padding(.trailing, 14)
        }
        .background(
            Image("txffield_background")
                .resizable(capInsets: EdgeInsets(top: 36, leading: 36, bottom: 36, trailing: 36), resizingMode: .stretch)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .frame(maxWidth: .infinity)
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

final class ATTrackingStatusManager {
    
    static var idfa: String? {
        ATTrackingManager.trackingAuthorizationStatus == .authorized ? ASIdentifierManager.shared().advertisingIdentifier.uuidString : nil
    }
    
    func requestATTracking() async {
        let status = ATTrackingManager.trackingAuthorizationStatus
        
        switch status {
            case .notDetermined:
                let newStatus = await ATTrackingManager.requestTrackingAuthorization()
                
                if newStatus == .authorized {
                    ConfigurationStateManager.shared.trackingDidApproved()
                }
            case .authorized:
                ConfigurationStateManager.shared.trackingDidApproved()
            default:
                return
        }
        
        ConfigurationStateManager.shared.trackingDidAsked()
    }
}

final class RemoteManager: ObservableObject {
    
    static let shared = RemoteManager()
    
    private let config = RemoteConfig.remoteConfig()
    
    private(set) var isRemoteEnable = false
    private(set) var savedBaseURLString: String?
    private(set) var savedURLString: String?
    private(set) var salt: String?
    private(set) var appsFlyerDevKey: String?
    private(set) var appsFlyerCampaignURL: String?
    
    private var hasServiceLoaded = false
    
    private init() {
        setupConfig()
        loadStorageConfig()
    }
    
    func fetchConfig() async {
        guard !hasServiceLoaded else {
            return
        }
        
        do {
            let status = try await config.fetch()
            
            switch status {
                case .success:
                    try await config.activate()
                    updateLocalValues()
                default:
                    return
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func updateLocalValues() {
        self.isRemoteEnable = config.configValue(forKey: MagicConstants.remoteConfigKey).boolValue
        self.savedBaseURLString = config.configValue(forKey: MagicConstants.endpoint_name).stringValue
        self.salt = config.configValue(forKey: MagicConstants.salt_name).stringValue
        self.appsFlyerDevKey = config.configValue(forKey: MagicConstants.developerKey).stringValue
        self.appsFlyerCampaignURL = config.configValue(forKey: MagicConstants.companyURL).stringValue
        
        guard isRemoteEnable,
              let savedBaseURLString,
              let salt,
              let appsFlyerDevKey,
              let appsFlyerCampaignURL else { return }
        
        StorageManager.shared.enableRemote()
        StorageManager.shared.saveBase(savedBaseURLString)
        StorageManager.shared.save(salt)
        StorageManager.shared.saveDevKey(appsFlyerDevKey)
        StorageManager.shared.saveCampaignURL(string: appsFlyerCampaignURL)
    }
    
    private func setupConfig() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 500
        config.configSettings = settings
    }
    
    private func loadStorageConfig() {
        let remoteStatus = StorageManager.shared.getRemoteStatus()
        let savedSalt = StorageManager.shared.getSavedSalt()
        let savedBasedURLString = StorageManager.shared.getSavedBaseURLString()
        let savedURLString = StorageManager.shared.getSavedURLString()
        let devKey = StorageManager.shared.getSavedDevKey()
        let campaignURLString = StorageManager.shared.getSavedCampaignURLString()
        
        if let remoteStatus {
            self.isRemoteEnable = remoteStatus
            self.salt = savedSalt
            self.savedBaseURLString = savedBasedURLString
            self.savedURLString = savedURLString
            self.appsFlyerDevKey = devKey
            self.appsFlyerCampaignURL = campaignURLString
            self.hasServiceLoaded = true
        }
    }
}
