//
//  LogoView.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 06/06/24.
//

import SwiftUI

struct LogoView: View {
    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: "cylinder.split.1x2")
                .renderingMode(.original)
                .font(.system(size: 70))
                .frame(width: 50, alignment: .center)
                .foregroundColor(.blessqlPrimary)
            
            Text("Welcome to blessql")
                .font(.system(size: 18))
            Text("Version 0.0.1")
                .font(.system(size: 12))
                .foregroundStyle(Color.blessqlDimmed)
                .fontWeight(Font.Weight.light)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LogoView()
}
