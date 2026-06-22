import SwiftUI
import UIKit
import PhotosUI

struct CounterDraft {
    var title = ""
    var emoji = "💧"
    var colorHex = "#3498DB"
    var goal = ""
    var imageData: Data? = nil
}

struct CounterEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var draft: CounterDraft
    let title: String
    let onSave: (CounterDraft) throws -> Void

    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    private let colors = ["#3498DB", "#E74C3C", "#2ECC71", "#F1C40F", "#9B59B6", "#E67E22"]
    private let quickEmojis = ["💧", "💪", "✨", "📚", "☕️", "💊", "❤️", "⭐️"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $draft.title)
                    TextField("Goal (optional)", text: $draft.goal).keyboardType(.numberPad)
                }
                
                Section("Icon") {
                    VStack(alignment: .leading, spacing: 14) {
                        // Quick select grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                            ForEach(quickEmojis, id: \.self) { emoji in
                                Button {
                                    draft.emoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 24))
                                        .frame(width: 50, height: 50)
                                        .background(draft.emoji == emoji ? Color(hex: draft.colorHex).opacity(0.18) : Color(.systemGray6))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(draft.emoji == emoji ? Color(hex: draft.colorHex) : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Divider()
                        
                        // Custom Emoji input via iOS Keyboard
                        HStack(spacing: 12) {
                            Text("Custom Emoji:")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                            
                            EmojiTextFieldRepresentable(
                                text: Binding(
                                    get: {
                                        quickEmojis.contains(draft.emoji) ? "" : draft.emoji
                                    },
                                    set: { newValue in
                                        if !newValue.isEmpty {
                                            draft.emoji = newValue
                                        }
                                    }
                                ),
                                placeholder: "Enter any emoji..."
                            )
                            .padding(.horizontal, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .frame(height: 38)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Color") {
                    HStack {
                        ForEach(colors, id: \.self) { hex in
                            Button {
                                draft.colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(.primary, lineWidth: draft.colorHex == hex ? 2 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Section("Background Image") {
                    VStack(alignment: .leading, spacing: 10) {
                        if let imageData = draft.imageData, let uiImage = UIImage(data: imageData) {
                            HStack(spacing: 12) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .clipped()
                                
                                Button(role: .destructive) {
                                    draft.imageData = nil
                                    selectedPhotoItem = nil
                                } label: {
                                    Text("Remove Photo")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label(
                                draft.imageData == nil ? "Choose Photo..." : "Change Photo...",
                                systemImage: "photo"
                            )
                            .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        draft.imageData = data
                    }
                }
            }
            .onChange(of: draft.goal) { _, newValue in
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    draft.goal = filtered
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try onSave(draft)
                            dismiss()
                        } catch { }
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// Custom TextField subclass that forces the Emoji Keyboard
class UIEmojiTextField: UITextField {
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return super.textInputMode
    }
}

// SwiftUI Representable wrapper for the custom Emoji text field
struct EmojiTextFieldRepresentable: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextFieldRepresentable

        init(_ parent: EmojiTextFieldRepresentable) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            let clean = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if let firstChar = clean.first {
                let emojiStr = String(firstChar)
                parent.text = emojiStr
                textField.text = emojiStr
                
                // Automatically dismiss the keyboard once an emoji is selected
                DispatchQueue.main.async {
                    textField.resignFirstResponder()
                }
            } else {
                parent.text = ""
                textField.text = ""
            }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty {
                return true
            }
            // Force replacement of existing text with new selection
            textField.text = string
            textFieldDidChange(textField)
            return false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIEmojiTextField {
        let textField = UIEmojiTextField()
        textField.placeholder = placeholder
        textField.textAlignment = .center
        textField.delegate = context.coordinator
        textField.font = .systemFont(ofSize: 16, weight: .regular)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UIEmojiTextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
}
