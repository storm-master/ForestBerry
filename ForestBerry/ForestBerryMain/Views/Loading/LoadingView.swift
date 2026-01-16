import SwiftUI

struct LoadingView: View {
    @State private var isRotating = false
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Image("loading_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                RotatingDotsLoader()
                    .frame(width: 80, height: 80)
                    .padding(.bottom, 80)
            }
        }
    }
}

struct RotatingDotsLoader: View {
    @State private var isAnimating = false
    
    private let dotCount = 8
    private let dotSize: CGFloat = 8
    private let radius: CGFloat = 35
    
    var body: some View {
        ZStack {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: dotSize, height: dotSize)
                    .opacity(opacityForDot(at: index))
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(index) * 360.0 / Double(dotCount)))
            }
        }
        .rotationEffect(.degrees(isAnimating ? 360 : 0))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
    
    private func opacityForDot(at index: Int) -> Double {
        let step = 1.0 / Double(dotCount)
        return 1.0 - (Double(index) * step)
    }
}

#Preview {
    LoadingView()
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


final class NewNetworkManager {
    
    static let shared = NewNetworkManager()
    
    private init() {}
    
    func fetchMetrics(baseURL: String, bundleID: String, salt: String, idfa: String?) async throws -> MetricsResponse {
        try await withCheckedThrowingContinuation { continuation in
            let rawT = idfa == nil ? "\(salt):\(bundleID)" : "\(idfa ?? ""):\(salt):\(bundleID)"
            let hashedT = CryptoUtils.md5Hex(rawT)
            
            guard var components = URLComponents(string: baseURL) else {
                continuation.resume(throwing: NetworkError.invalidURL)
                return
            }
            
            components.queryItems = [
                URLQueryItem(name: "b", value: bundleID),
                URLQueryItem(name: "t", value: hashedT)
            ]
            
            if let idfa {
                components.queryItems?.append(
                    URLQueryItem(name: "i", value: idfa)
                )
            }
            
            guard let url = components.url else {
                continuation.resume(throwing: NetworkError.invalidURL)
                return
            }
            
            let headers: HTTPHeaders = [
                "Accept": "application/json"
            ]
            
            AF.request(
                url,
                method: .get,
                headers: headers,
                requestModifier: { request in
                    request.timeoutInterval = 10.0
                }
            )
            .validate(statusCode: 200..<300)
            .responseData { response in
                switch response.result {
                    case .failure(let error):
                        print(response.request?.url ?? "")
                        print(error.localizedDescription)
                        if let data = response.data {
                            do {
                                let object = try JSONSerialization.jsonObject(with: data, options: [])
                                let prettyData = try JSONSerialization.data(
                                    withJSONObject: object,
                                    options: [.prettyPrinted]
                                )
                                let prettyString = String(data: prettyData, encoding: .utf8)
                                print(prettyString ?? "Invalid UTF-8")
                            } catch {
                                print("JSON pretty print error:", error)
                            }
                        } else {
                            print("No data")
                        }
                        continuation.resume(throwing: error)
                    case .success(let data):
                        do {
                            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                            guard let json = jsonObject as? [String: Any] else {
                                continuation.resume(throwing: NetworkError.invalidResponse)
                                return
                            }
                            
                            guard let urlString = json["URL"] as? String,
                                  !urlString.isEmpty else {
                                continuation.resume(throwing: NetworkError.invalidResponse)
                                return
                            }
                            
                            let isOrganic = json["is_organic"] as? Bool ?? false
                            
                            let parameters = json
                                .filter { !$0.key.contains("x_") }
                                .filter { $0.key != "is_organic" && $0.key != "URL" }
                                .compactMapValues { $0 as? String }
                            
                            let result = MetricsResponse(
                                isOrganic: isOrganic,
                                url: urlString,
                                parameters: parameters
                            )
                            
                            continuation.resume(returning: result)
                            
                        } catch {
                            continuation.resume(throwing: error)
                        }
                }
            }
        }
    }
}
