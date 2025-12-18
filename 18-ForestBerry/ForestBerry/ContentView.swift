import SwiftUI

struct ContentView: View {
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            guard isLoading else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
