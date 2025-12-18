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

