import SwiftUI
import PhotosUI
import UIKit

struct FBAddSpotView: View {
    @Binding var isPresented: Bool
    @Binding var spotToEdit: FavoriteSpot?
    private let onSave: ((FavoriteSpot) -> Void)?

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var spotName: String = ""
    @State private var spotDirections: String = ""
    @State private var selectedType: SpotType?
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: InputField?
    @Environment(\.dismiss) private var dismiss

    init(isPresented: Binding<Bool>, spotToEdit: Binding<FavoriteSpot?> = .constant(nil), onSave: ((FavoriteSpot) -> Void)? = nil) {
        _isPresented = isPresented
        _spotToEdit = spotToEdit
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            ForestBerryBackground()

            VStack(spacing: 20) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        photoPicker
                        nameField
                        directionsField
                        typePicker
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                }
                .padding(.horizontal, 24)
                .simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })
            }
            .padding(.top, 16)
            .padding(.bottom, 24 + (keyboardHeight > 0 ? keyboardHeight + 8 : 0))
        }
        .ignoresSafeArea(edges: .bottom)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.25)) {
                    keyboardHeight = frame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
        .onChange(of: selectedPhotoItem) { newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
            }
        }
        .onAppear {
            if let spot = spotToEdit {
                spotName = spot.name
                spotDirections = spot.directions
                selectedType = spot.type
                selectedImage = UIImage(data: spot.imageData)
            }
        }
    }
}

private extension FBAddSpotView {
    var header: some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image("back_button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
            }

            Spacer()

            Text("Add location")
                .font(.custom("Copperplate-Bold", size: 28))
                .foregroundColor(Color("FBBlack"))

            Spacer()

            Button(action: submit) {
                Image("blank_backround")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .overlay(
                        Group {
                            if isFormValid {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color("FBFreshGreen"))
                            }
                        }
                    )
            }
            .disabled(!isFormValid)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    var photoPicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack {
                Image("field_backround")
                    .resizable(capInsets: EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40), resizingMode: .stretch)
                    .frame(width: 140, height: 140)

                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .clipped()
                } else {
                    Image("add_photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                }
            }
            .frame(width: 140, height: 140)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    var nameField: some View {
        fieldBackground(height: 70) {
            TextField("", text: $spotName, prompt: Text("Location name").foregroundColor(.white.opacity(0.7)))
                .font(.custom("Copperplate-Bold", size: 20))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .focused($focusedField, equals: .name)
        }
    }

    var directionsField: some View {
        fieldBackground(height: 70) {
            TextField("", text: $spotDirections, prompt: Text("Directions or notes").foregroundColor(.white.opacity(0.7)))
                .font(.custom("Copperplate-Bold", size: 20))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .focused($focusedField, equals: .directions)
        }
    }

    var typePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            HStack(spacing: 20) {
                Spacer()
                ForEach(SpotType.allCases, id: \.self) { type in
                    Button(action: { selectedType = type }) {
                        Image(type.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 135, height: 135)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(selectedType == type ? Color("FBFreshGreen") : Color.clear, lineWidth: 5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func fieldBackground<Content: View>(height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Image("txffield_background")
                .resizable(capInsets: EdgeInsets(top: 36, leading: 36, bottom: 36, trailing: 36), resizingMode: .stretch)
                .frame(height: height)
            content()
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }

    var isFormValid: Bool {
        guard
            let selectedType,
            let imageData = selectedImage?.jpegData(compressionQuality: 0.85),
            !spotName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !spotDirections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return false }

        return !imageData.isEmpty
    }

    func submit() {
        guard
            let selectedType,
            let image = selectedImage,
            let imageData = image.jpegData(compressionQuality: 0.85)
        else { return }

        if var existingSpot = spotToEdit {
            existingSpot.name = spotName.trimmingCharacters(in: .whitespacesAndNewlines)
            existingSpot.directions = spotDirections.trimmingCharacters(in: .whitespacesAndNewlines)
            existingSpot.type = selectedType
            existingSpot.imageData = imageData
            
            FavoriteSpotsManager.shared.updateSpot(existingSpot)
            spotToEdit = existingSpot
        } else {
            let spot = FavoriteSpot(
                name: spotName.trimmingCharacters(in: .whitespacesAndNewlines),
                directions: spotDirections.trimmingCharacters(in: .whitespacesAndNewlines),
                type: selectedType,
                imageData: imageData
            )
            
            FavoriteSpotsManager.shared.addSpot(spot)
            onSave?(spot)
        }
        
        dismissKeyboard()
        dismiss()
        isPresented = false
    }

    func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    enum InputField: Hashable {
        case name
        case directions
    }
}

