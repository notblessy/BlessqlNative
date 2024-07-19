//
//  ConnectionView.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 06/06/24.
//

import SwiftUI

struct ConnectionView: View {
    var body: some View {
        HSplitView {
            HSplitView {
                LogoView()
            }
            .background(Color.blessqlWhite)
            .frame(width: 250)
            
            // Right side view
            VStack(alignment: .leading) {
                ConnectionListView()
            }
            .padding(.all, 10)
            .frame(minWidth: 400, minHeight: 400)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
    }
}

#Preview {
    ConnectionView()
}
