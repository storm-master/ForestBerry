import SwiftUI

struct FBSpotDetailedView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.tabBarVisible) var tabBarVisible
    @Binding var spot: FavoriteSpot
    @State private var showingDeleteAlert = false
    @State private var navigateToEdit = false
    
    var body: some View {
        ZStack {
            ForestBerryBackground()
            
            VStack(spacing: 20) {
                header
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        detailCard
                            .frame(maxWidth: 300)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear {
            tabBarVisible.wrappedValue = false
        }
        .onDisappear {
            tabBarVisible.wrappedValue = true
        }
        .alert("Delete", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSpot()
            }
        } message: {
            Text("Are you sure you want to delete this entry?")
        }
        .fullScreenCover(isPresented: $navigateToEdit) {
            FBAddSpotView(isPresented: $navigateToEdit, spotToEdit: Binding(
                get: { spot },
                set: { spot = $0 ?? spot }
            ))
        }
    }
    
    private var header: some View {
        HStack(spacing: 20) {
            Button(action: { dismiss() }) {
                Image("back_button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
            }
            
            Spacer()
            
            Button(action: { navigateToEdit = true }) {
                Image("edit_button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
            }
            
            Button(action: { showingDeleteAlert = true }) {
                Image("delete_button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
            }
        }
    }
    
    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let uiImage = UIImage(data: spot.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .clipped()
            }
            
            Text(spot.name)
                .font(.custom("Copperplate-Bold", size: 32))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Image(spot.type.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                
                Text(spot.type.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
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
    
    private func deleteSpot() {
        FavoriteSpotsManager.shared.deleteSpot(spot)
        dismiss()
    }
    
    private var notesContent: String {
        let trimmed = spot.directions.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "—" : trimmed
    }
}

