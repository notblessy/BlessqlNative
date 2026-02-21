import SwiftUI

struct InputText: View {
    var label: String
    var placeholder: String?
    var showLabel: Bool
    var borderStyle: String

    @Binding var value: String

    private var prompt: String {
        placeholder ?? label
    }

    var body: some View {
        HStack {
            if showLabel {
                Text(label)
                    .frame(width: 70, alignment: .leading)
            }

            switch borderStyle {
            case "success":
                TextField(prompt, text: $value)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity)
                    .background(Color.blessqlSuccess)
                    .cornerRadius(5)
                    .shadow(color: Color.black.opacity(0.2), radius: 0.2, x: 0.0, y: 1)
                    .accentColor(Color.blessqlSuccess)
                    .textFieldStyle(.roundedBorder)
            case "error":
                TextField(prompt, text: $value)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity)
                    .background(Color.blessqlError)
                    .cornerRadius(5)
                    .shadow(color: Color.black.opacity(0.2), radius: 0.2, x: 0.0, y: 1)
                    .accentColor(Color.blessqlError)
                    .textFieldStyle(.roundedBorder)
            default:
                TextField(prompt, text: $value)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

#Preview {
    InputText(label: "", showLabel: false, borderStyle: "", value: .constant(""))
}
