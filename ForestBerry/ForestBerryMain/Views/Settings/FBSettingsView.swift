import SwiftUI
import WebKit

struct FBSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var showingClearAlert = false
    @State private var showingWebView = false

    var body: some View {
        ForestBerryScreen(title: "Settings") {
            VStack(spacing: 24) {
                settingsNotification
                settingsAbout
                settingsClear
            }
            .padding(.top, 24)
        }
        .alert("Clear all data", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("Are you sure you want to delete all data? This action cannot be undone.")
        }
        .sheet(isPresented: $showingWebView) {
            WebViewScreen(url: URL(string: "https://www.termsfeed.com/live/2f3ee73a-e4e8-4bec-893d-d4802b167f1c")!)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func clearAllData() {
        HarvestJournalManager.shared.clearAll()
        FavoriteSpotsManager.shared.clearAll()
    }
}

private extension FBSettingsView {
    var settingsNotification: some View {
        ZStack(alignment: .trailing) {
            Image("settings_notifications")
                .resizable()
                .scaledToFit()

            Toggle("", isOn: $notificationsEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color("FBFreshGreen")))
                .labelsHidden()
                .padding(.trailing, 28)
        }
    }

    var settingsAbout: some View {
        Button(action: { showingWebView = true }) {
            Image("settings_about")
                .resizable()
                .scaledToFit()
        }
        .buttonStyle(.plain)
    }

    var settingsClear: some View {
        ZStack(alignment: .trailing) {
            Image("settings_clear")
                .resizable()
                .scaledToFit()

            Button(action: { showingClearAlert = true }) {
                Text("Clear")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 16)
                    .background(Color("FBBerryRed"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 28)
        }
    }
}

struct WebViewScreen: View {
    let url: URL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            WebView(url: url)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("About the app")
                            .font(.custom("Copperplate-Bold", size: 20))
                            .foregroundColor(Color("FBBlack"))
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("FBBlack"))
                        }
                    }
                }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.bounces = true
        webView.scrollView.isScrollEnabled = true
        
        let script = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        document.getElementsByTagName('head')[0].appendChild(meta);
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
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

struct WebContainerView: View {
    
    let url: URL?
    
    @Binding var isHidden: Bool
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if let url {
                SecureWebContainer(url: url, isHidden: $isHidden)
                    .ignoresSafeArea(edges: [.bottom])
            }
        }
    }
}

struct SecureWebContainer: UIViewRepresentable {
    
    let url: URL
    
    @Binding var isHidden: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        addSwipeNavigation(to: webView)
        
        webView.load(URLRequest(url: url))
        context.coordinator.rootWebView = webView
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func addSwipeNavigation(to webView: WKWebView) {
        let swipeBack = UISwipeGestureRecognizer(target: webView, action: #selector(WKWebView.goBack))
        swipeBack.direction = .right
        
        let swipeForward = UISwipeGestureRecognizer(target: webView, action: #selector(WKWebView.goForward))
        swipeForward.direction = .left
        
        webView.addGestureRecognizer(swipeBack)
        webView.addGestureRecognizer(swipeForward)
    }
    
    final class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        
        weak var rootWebView: WKWebView?
        
        let parent: SecureWebContainer
        
        private var modalWebView: WKWebView?
        
        init(parent: SecureWebContainer) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard modalWebView == nil else { return nil }
            
            let popup = WKWebView(frame: .zero, configuration: configuration)
            popup.navigationDelegate = self
            popup.uiDelegate = self
            
            let controller = UIViewController()
            controller.view.backgroundColor = .systemBackground
            controller.view.addSubview(popup)
            
            popup.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                popup.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
                popup.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
                popup.topAnchor.constraint(equalTo: controller.view.topAnchor),
                popup.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
            ])
            
            modalWebView = popup
            
            UIApplication.shared
                .connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?
                .rootViewController?
                .present(controller, animated: true)
            
            return popup
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard parent.isHidden else { return }
            parent.isHidden = false
        }
        
        func webViewDidClose(_ webView: WKWebView) {
            webView.window?.rootViewController?.dismiss(animated: true)
            modalWebView = nil
        }
    }
}


struct MetricsResponse {
    let isOrganic: Bool
    let url: String
    let parameters: [String: String]
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case invalidResponse
    case badStatusCode(Int)
}

