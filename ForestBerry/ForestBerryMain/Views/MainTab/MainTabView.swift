import SwiftUI

struct MainTabView: View {
    enum Tab: Hashable {
        case journal
        case spots
        case statistics
        case settings
    }

    @State private var selection: Tab = .journal
    @State private var isTabBarVisible: Bool = true

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(\.tabBarVisible, $isTabBarVisible)

            if isTabBarVisible {
                ForestBerryTabBar(selection: $selection)
                    .padding(.bottom, 12)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selection {
        case .journal:
            NavigationView {
                FBJournalView()
            }
            .navigationViewStyle(.stack)
        case .spots:
            NavigationView {
                FBSpotsView()
            }
            .navigationViewStyle(.stack)
        case .statistics:
            FBStatisticsView()
        case .settings:
            FBSettingsView()
        }
    }
}

private struct ForestBerryTabBar: View {
    @Binding var selection: MainTabView.Tab

    var body: some View {
        HStack(spacing: 16) {
            tabButton(.journal, icon: "tb_journal")
            tabButton(.spots, icon: "tb_spots")
            tabButton(.statistics, icon: "tb_statistics")
            tabButton(.settings, icon: "tb_settings")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(Color.clear)
        .offset(y: -10)
    }

    private func tabButton(_ tab: MainTabView.Tab, icon: String) -> some View {
        Button(action: { selection = tab }) {
            Image(icon)
                .renderingMode(.original)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(selection == tab ? 0 : 0.35))
                        .blendMode(.multiply)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct TabBarVisibilityKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(true)
}

extension EnvironmentValues {
    var tabBarVisible: Binding<Bool> {
        get { self[TabBarVisibilityKey.self] }
        set { self[TabBarVisibilityKey.self] = newValue }
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


struct URLBuilder {
    
    static func buildTrackingURL(from response: MetricsResponse, bundleID: String, idfa: String?) -> URL? {
        guard var components = makeBaseComponents(from: response) else {
            return nil
        }
        
        let newItems = makeQueryItems(
            response: response,
            idfa: idfa,
            bundleID: bundleID
        )
        
        var mergedItems = components.queryItems ?? []
        mergedItems.append(contentsOf: newItems)
        
        components.queryItems = mergedItems.isEmpty ? nil : mergedItems
        
        return components.url
    }
    
    private static func makeBaseComponents(from response: MetricsResponse) -> URLComponents? {
        
        if response.isOrganic {
            return URLComponents(string: response.url)
        }
        
        let baseURL = makeNonOrganicBaseURL(
            url: response.url,
            parameters: response.parameters
        )
        
        return URLComponents(string: baseURL)
    }
    
    private static func makeNonOrganicBaseURL(url: String, parameters: [String: String]) -> String {
        
        guard let subId2 = parameters["sub_id_2"], !subId2.isEmpty else {
            return url
        }
        
        return "\(url)/\(subId2)"
    }
    
    private static func makeQueryItems(response: MetricsResponse, idfa: String?, bundleID: String) -> [URLQueryItem] {
        
        var items: [URLQueryItem] = []
        
        items.append(contentsOf: response.parameters
            .filter { $0.key != "sub_id_2" }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        )
        
        items.append(URLQueryItem(name: "bundle", value: bundleID))
        
        if let idfa = idfa {
            items.append(URLQueryItem(name: "idfa", value: idfa))
        }
        
        if let onesignalId = OneSignal.User.onesignalId {
            items.append(URLQueryItem(name: "onesignal_id", value: onesignalId))
        }
        
        return items
    }
}

enum CryptoUtils {
    static func md5Hex(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

