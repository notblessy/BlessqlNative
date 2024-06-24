//
//  Color.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 06/06/24.
//

import SwiftUI

extension Color {
    init(hex: String) {
        var cleanHexCode = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHexCode = cleanHexCode.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: cleanHexCode).scanHexInt64(&rgb)
        
        let redValue = Double((rgb >> 16) & 0xFF) / 255.0
        let greenValue = Double((rgb >> 8) & 0xFF) / 255.0
        let blueValue = Double(rgb & 0xFF) / 255.0
        
        self.init(red: redValue, green: greenValue, blue: blueValue)
    }
}

extension Color {
    public static let blessqlPrimary = Color(hex: "FFAB09")
    public static let blessqlSecondary = Color(hex: "FFF8E1")
    public static let blessqlDimmed = Color(hex: "7D7D7D")
    public static let blessqlLight = Color(hex: "ECECEC")
    public static let blessqlWhite = Color(hex: "F9F9F9")
    public static let blessqlSuccess = Color(hex: "D6E9B0")
    public static let blessqlError = Color(hex: "FADAD6")
}
