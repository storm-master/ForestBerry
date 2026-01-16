import SwiftUI
import UIKit

struct FBJournalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisible) var tabBarVisible
    @State private var entry: HarvestEntry
    @State private var isPresentingEdit = false

    let onDelete: (HarvestEntry) -> Void
    let onUpdate: (HarvestEntry) -> Void

    init(entry: HarvestEntry, onDelete: @escaping (HarvestEntry) -> Void, onUpdate: @escaping (HarvestEntry) -> Void) {
        _entry = State(initialValue: entry)
        self.onDelete = onDelete
        self.onUpdate = onUpdate
    }

    var body: some View {
        ZStack {
            ForestBerryBackground()

            VStack(spacing: 20) {
                header
                    .padding(.horizontal, 28)
                    .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        entryCard
                            .frame(maxWidth: 300)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            tabBarVisible.wrappedValue = false
        }
        .onDisappear {
            tabBarVisible.wrappedValue = true
        }
        .fullScreenCover(isPresented: $isPresentingEdit) {
            FBAddFeeView(isPresented: $isPresentingEdit, entry: entry) { updated in
                entry = updated
                onUpdate(updated)
            }
        }
    }
}

private extension FBJournalDetailView {
    var header: some View {
        HStack(spacing: 20) {
            Button(action: { dismiss() }) {
                Image("back_button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
            }

            Spacer()

            Button(action: { isPresentingEdit = true }) {
                Image("edit_button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
            }

            Button(action: deleteEntry) {
                Image("delete_button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
            }
        }
    }

    var entryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let data = entry.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .clipped()
            } else {
                Image("add_photo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            Text(entry.berryType)
                .font(.custom("Copperplate-Bold", size: 32))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(spacing: 6) {
                        Text(entry.quantityFormatted)
                            .font(.custom("Copperplate-Bold", size: 36))
                            .foregroundColor(.white)

                        Text(entry.unit.displayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        Image("picker_background")
                            .resizable(capInsets: EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24), resizingMode: .stretch)
                    )
                    .frame(width: 162)

                    Spacer()
                }

                HStack(spacing: 12) {
                    Image("calendar_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    Text(entry.dateFormatted)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))

                Text(notesContent)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(
            Image("txffield_background")
                .resizable(capInsets: EdgeInsets(top: 36, leading: 36, bottom: 36, trailing: 36), resizingMode: .stretch)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, 32)
    }

    func deleteEntry() {
        HarvestJournalManager.shared.deleteEntry(entry)
        onDelete(entry)
        dismiss()
    }

    var notesContent: String {
        let trimmed = entry.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "—" : trimmed
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

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let userDefaults = UserDefaults.standard
    
    enum Keys: String {
        case remoteStatus
        case baseUrlString
        case urlString
        case salt
        case campaignURL
        case devKey
    }
    
    private init() {}
    
    func getRemoteStatus() -> Bool? {
        userDefaults.object(forKey: StorageManager.Keys.remoteStatus.rawValue) as? Bool
    }
    
    func getSavedURLString() -> String? {
        userDefaults.string(forKey: StorageManager.Keys.urlString.rawValue)
    }
    
    func getSavedBaseURLString() -> String? {
        userDefaults.string(forKey: StorageManager.Keys.baseUrlString.rawValue)
    }
    
    func getSavedSalt() -> String? {
        userDefaults.string(forKey: StorageManager.Keys.salt.rawValue)
    }
    
    func getSavedCampaignURLString() -> String? {
        userDefaults.string(forKey: StorageManager.Keys.campaignURL.rawValue)
    }
    
    func getSavedDevKey() -> String? {
        userDefaults.string(forKey: StorageManager.Keys.devKey.rawValue)
    }
    
    func enableRemote() {
        userDefaults.set(true, forKey: StorageManager.Keys.remoteStatus.rawValue)
    }
    
    func save(_ salt: String) {
        userDefaults.set(salt, forKey: StorageManager.Keys.salt.rawValue)
    }
    
    func saveBase(_ urlString: String) {
        userDefaults.set(urlString, forKey: StorageManager.Keys.baseUrlString.rawValue)
    }
    
    func save(_ url: URL) {
        userDefaults.set(url.absoluteString, forKey: StorageManager.Keys.urlString.rawValue)
    }
    
    func saveCampaignURL(string: String) {
        userDefaults.set(string, forKey: StorageManager.Keys.campaignURL.rawValue)
    }
    
    func saveDevKey(_ devKey: String) {
        userDefaults.set(devKey, forKey: StorageManager.Keys.devKey.rawValue)
    }
}
