import SwiftUI

struct ForestBerryScreen<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            ForestBerryBackground()

            VStack(spacing: 0) {
                Text(title)
                    .font(.custom("Copperplate-Bold", size: 28))
                    .foregroundColor(Color("FBBlack"))
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                content
                    .padding(.top, 12)

                Spacer(minLength: 0)

                Spacer(minLength: 0)

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 24)
        }
    }
}

