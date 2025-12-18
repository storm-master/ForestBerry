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

