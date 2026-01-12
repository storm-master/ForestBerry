import SwiftUI
import PhotosUI
import UIKit

struct FBAddFeeView: View {
    @Binding var isPresented: Bool
    private let existingEntry: HarvestEntry?
    private let onSave: ((HarvestEntry) -> Void)?

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var existingImageData: Data?
    @State private var selectedDate: Date
    @State private var berryType: String
    @State private var quantity: String
    @State private var selectedUnit: HarvestUnit
    @State private var notes: String
    @State private var isUnitMenuVisible = false
    @State private var isShowingDatePicker = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isLoadingPhoto = false
    @FocusState private var focusedField: InputField?
    @Environment(\.dismiss) private var dismiss

    private let units = HarvestUnit.allCases

    init(isPresented: Binding<Bool>, entry: HarvestEntry? = nil, onSave: ((HarvestEntry) -> Void)? = nil) {
        _isPresented = isPresented
        existingEntry = entry
        self.onSave = onSave
        _selectedDate = State(initialValue: entry?.date ?? Date())
        _berryType = State(initialValue: entry?.berryType ?? "")
        if let quantityValue = entry?.quantity {
            let formatter = NumberFormatter()
            formatter.locale = Locale.current
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            formatter.numberStyle = .decimal
            _quantity = State(initialValue: formatter.string(from: NSNumber(value: quantityValue)) ?? "")
        } else {
            _quantity = State(initialValue: "")
        }
        _selectedUnit = State(initialValue: entry?.unit ?? .kilograms)
        _notes = State(initialValue: entry?.notes ?? "")
        _existingImageData = State(initialValue: entry?.imageData)
    }

    var body: some View {
        ZStack {
            ForestBerryBackground()

            VStack(spacing: 20) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        photoPicker
                        dateField
                            .padding(.top, 8)
                        Spacer().frame(height: 8)
                        berryTypeField
                        Spacer().frame(height: 8)
                        quantityField
                        Spacer().frame(height: 8)
                        notesField
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
        .sheet(isPresented: $isShowingDatePicker) {
            VStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .background(Color(.systemBackground))
                Button("Done") {
                    isShowingDatePicker = false
                }
                .padding()
            }
            .presentationDetents([.medium, .fraction(0.4)])
        }
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
            isLoadingPhoto = true
            Task {
                do {
                    // Try loading as Data first
                    if let data = try await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImage = image
                            existingImageData = data
                            isLoadingPhoto = false
                        }
                        return
                    }
                } catch {
                    // Data loading failed, continue to fallback
                }
                
                // Fallback: try loading as Image and convert
                do {
                    if let image = try await newValue.loadTransferable(type: Image.self) {
                        await MainActor.run {
                            // Create a renderer to convert SwiftUI Image to UIImage
                            let renderer = ImageRenderer(content: image.resizable().frame(width: 800, height: 800))
                            renderer.scale = UIScreen.main.scale
                            if let uiImage = renderer.uiImage,
                               let imageData = uiImage.jpegData(compressionQuality: 0.85) {
                                selectedImage = uiImage
                                existingImageData = imageData
                            }
                            isLoadingPhoto = false
                        }
                    } else {
                        await MainActor.run {
                            isLoadingPhoto = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        isLoadingPhoto = false
                    }
                }
            }
        }
    }
}

private extension FBAddFeeView {
    var header: some View {
        HStack {
            Button(action: {
                isPresented = false
            }) {
                Image("back_button")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
            }

            Spacer()

            Text(existingEntry == nil ? "Add fee" : "Edit fee")
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
                    .frame(width: 160, height: 160)

                if isLoadingPhoto {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .clipped()
                } else if let existingImageData, let image = UIImage(data: existingImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .clipped()
                } else {
                    Image("add_photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                }
            }
            .frame(width: 160, height: 160)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(isLoadingPhoto)
    }

    var dateField: some View {
        Button(action: {
            isShowingDatePicker = true
        }) {
            fieldBackground(height: 56) {
                HStack {
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.custom("Copperplate-Bold", size: 20))
                        .foregroundColor(.white)
                    Spacer()
                    Image("calendar_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .buttonStyle(.plain)
    }

    var berryTypeField: some View {
        fieldBackground(height: 56) {
            TextField("", text: $berryType, prompt: Text("Berry Type").foregroundColor(.white.opacity(0.7)))
                .font(.custom("Copperplate-Bold", size: 20))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .focused($focusedField, equals: .berryType)
        }
    }

    var quantityField: some View {
        fieldBackground(height: 56) {
            HStack(spacing: 12) {
                TextField("", text: $quantity, prompt: Text("Quantity").foregroundColor(.white.opacity(0.7)))
                    .keyboardType(.decimalPad)
                    .font(.custom("Copperplate-Bold", size: 20))
                    .foregroundColor(.white)
                    .focused($focusedField, equals: .quantity)

                Spacer(minLength: 0)

                Button(action: {
                    withAnimation(.easeInOut) {
                        isUnitMenuVisible.toggle()
                    }
                }) {
                    Text(selectedUnit.displayName)
                        .font(.custom("Copperplate-Bold", size: 18))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
        }
        .overlay(alignment: .topTrailing) {
            if isUnitMenuVisible {
                Image("picker_background")
                    .resizable(capInsets: EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24), resizingMode: .stretch)
                    .frame(width: 180, height: CGFloat(units.count) * 56)
                    .overlay(
                        VStack(spacing: 0) {
                            ForEach(units.indices, id: \.self) { index in
                                let unit = units[index]

                                Button(action: {
                                    selectedUnit = unit
                                    withAnimation(.easeInOut) {
                                        isUnitMenuVisible = false
                                    }
                                }) {
                                    Text(unit.displayName)
                                        .font(.custom("Copperplate-Bold", size: 18))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                }
                                .buttonStyle(.plain)

                                if index != units.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.25))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    )
                    .padding(.top, -8)
                    .padding(.trailing, 12)
            }
        }
        .zIndex(isUnitMenuVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: isUnitMenuVisible)
    }

    var notesField: some View {
        fieldBackground(height: 56) {
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Notes")
                        .font(.custom("Copperplate-Bold", size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                }

                TextEditor(text: $notes)
                    .scrollContentBackground(.hidden)
                    .font(.custom("Copperplate-Bold", size: 18))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
                    .background(Color.clear)
                    .focused($focusedField, equals: .notes)
            }
        }
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
        .animation(.easeInOut(duration: 0.2), value: isUnitMenuVisible)
    }

    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }
}

extension FBAddFeeView {
    enum Unit: String, CaseIterable {
        case liters
        case kilograms
        case baskets

        var displayName: String {
            switch self {
            case .liters: return "liters"
            case .kilograms: return "kilograms"
            case .baskets: return "baskets"
            }
        }
    }
}

private extension FBAddFeeView {
    enum InputField: Hashable {
        case berryType
        case quantity
        case notes
    }

    var isFormValid: Bool {
        guard
            !berryType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let quantityValue = Double(quantity.replacingOccurrences(of: ",", with: ".")),
            quantityValue > 0,
            (selectedImage != nil || existingImageData != nil)
        else { return false }

        return true
    }

    func submit() {
        guard isFormValid else { return }

        let cleanedQuantity = Double(quantity.replacingOccurrences(of: ",", with: ".")) ?? 0
        let finalImageData: Data?
        if let selectedImage {
            finalImageData = selectedImage.jpegData(compressionQuality: 0.85)
        } else {
            finalImageData = existingImageData
        }

        let entry = HarvestEntry(
            id: existingEntry?.id ?? UUID(),
            date: selectedDate,
            berryType: berryType.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: cleanedQuantity,
            unit: selectedUnit,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: finalImageData
        )

        if existingEntry == nil {
            HarvestJournalManager.shared.addEntry(entry)
        } else {
            HarvestJournalManager.shared.updateEntry(entry)
        }

        onSave?(entry)
        dismissKeyboard()
        dismiss()
    }

    func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

