import SwiftUI

struct FBSpotsView: View {
    @State private var spots: [FavoriteSpot] = []
    @State private var isPresentingAdd = false
    @State private var selectedSpot: FavoriteSpot?
    @State private var navigateToDetail = false

    var body: some View {
        ForestBerryScreen(title: "Favorite Spots") {
            VStack(spacing: 16) {
                if spots.isEmpty {
                    Button(action: { isPresentingAdd = true }) {
                        Image("spots_nodata")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 40)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach($spots) { $spot in
                                Button(action: {
                                    selectedSpot = spot
                                    navigateToDetail = true
                                }) {
                                    SpotCardView(spot: spot)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 16)
                        .padding(.bottom, 36)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                    Button(action: { isPresentingAdd = true }) {
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
            .onAppear(perform: loadSpots)
        }
        .fullScreenCover(isPresented: $isPresentingAdd, onDismiss: loadSpots) {
            FBAddSpotView(isPresented: $isPresentingAdd) { _ in
                loadSpots()
            }
        }
        .background(
            NavigationLink(
                destination: selectedSpot.map { spot in
                    FBSpotDetailedView(spot: binding(for: spot))
                },
                isActive: $navigateToDetail
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    private func loadSpots() {
        spots = FavoriteSpotsManager.shared.loadSpots().sorted { $0.createdAt > $1.createdAt }
    }
    
    private func binding(for spot: FavoriteSpot) -> Binding<FavoriteSpot> {
        guard let index = spots.firstIndex(where: { $0.id == spot.id }) else {
            return .constant(spot)
        }
        return $spots[index]
    }
}

private struct SpotCardView: View {
    let spot: FavoriteSpot

    var body: some View {
        HStack(spacing: 18) {
            if let uiImage = UIImage(data: spot.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .clipped()
            } else {
                Image("add_photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(spot.name)
                    .font(.custom("Copperplate-Bold", size: 22))
                    .foregroundColor(.white)

                Text(spot.directions)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            VStack(spacing: 10) {
                Image(spot.type.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)

                Text(spot.type.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            Image("txffield_background")
                .resizable(capInsets: EdgeInsets(top: 36, leading: 36, bottom: 36, trailing: 36), resizingMode: .stretch)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .frame(maxWidth: .infinity)
    }
}

