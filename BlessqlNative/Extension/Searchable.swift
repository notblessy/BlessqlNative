//
//  SearchAble.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 07/06/24.
//

import SwiftUI

struct Searchable: View {
    @Binding var search: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .padding(.leading, 8)
                .foregroundColor(.gray)
            TextField("Search", text: $search)
                .textFieldStyle(.plain)
                .padding(.vertical, 5)
        }
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(lineWidth: 0.3).foregroundColor(Color.gray))
        .background(Color.white, in: RoundedRectangle(cornerRadius: 5))
    }
}

#Preview {
    Searchable(search: .constant(""))
}
