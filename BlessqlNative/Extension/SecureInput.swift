//
//  SecureInput.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 24/06/24.
//

import SwiftUI

struct SecureInput: View {
    var label: String
    var showLabel: Bool
    var borderStyle: String
    
    @Binding var value: String
    
    var body: some View {
        HStack {
            if showLabel {
                Text(label)
                    .frame(width: 70, alignment: .leading)
            }
            
            switch borderStyle {
            case "success":
                SecureField(label, text: $value)
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
                SecureField(label, text: $value)
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
                SecureField(label, text: $value)
                    .textFieldStyle(.roundedBorder)
            }
            
            
        }
    }
}

#Preview {
    SecureInput(label: "", showLabel: false, borderStyle: "", value: .constant(""))
}
