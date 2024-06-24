//
//  ConnectionUpdateFormView.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 13/06/24.
//

import SwiftUI

struct ConnectionUpdateFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    let connection: Connection
    let connectionStatus: String = ""
    
    @State private var name: String = ""
    @State private var host: String = ""
    @State private var user: String = ""
    @State private var password: String = ""
    @State private var database: String = ""
    
    var body: some View {
        VStack {
            Text("Add Connection")
                .padding(.bottom, 10)
            InputText(label: "Name", showLabel: true, borderStyle: connectionStatus, value: $name)
            InputText(label: "Host", showLabel: true, borderStyle: connectionStatus, value: $host)
            InputText(label: "User", showLabel: true, borderStyle: connectionStatus, value: $user)
            InputText(label: "Password", showLabel: true, borderStyle: connectionStatus, value: $password)
            InputText(label: "Database", showLabel: true, borderStyle: connectionStatus, value: $database)
            HStack {
                Button(action: {
                    dismiss()
                }, label: {
                    Text("Cancel")
                })
                
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                    Text("Test")
                })
                
                Button(action: {
                    connection.name = name
                    connection.host = host
                    connection.username = user
                    connection.password = password
                    connection.database = database
                    
                    dismiss()
                }, label: {
                    Text("Save")
                })
            }
            .padding(.top, 10)
        }
        .frame(width: 250)
        .onAppear {
            name = connection.name
            host = connection.host
            user = connection.username
            password = connection.password
            database = connection.database
        }
    }
}

#Preview {
    ConnectionFormView()
}
