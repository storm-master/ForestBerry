import SwiftUI

struct ForestBerryBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Image("app_backround")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

