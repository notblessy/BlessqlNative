//
//  ConnectionFormView.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 10/06/24.
//

import SwiftUI

struct ConnectionFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    @State private var connectionStatus: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @State var name: String = ""
    @State var host: String = ""
    @State var user: String = ""
    @State var password: String = ""
    @State var database: String = ""
    
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
                
                Button(action: {
                    if let error = performTestConnection(host: host, database: database, user: user, password: password) {
                        DispatchQueue.main.async {
                            alertMessage = error
                            showAlert = true
                            connectionStatus = "error"
                        }
                    } else {
                        DispatchQueue.main.async {
                            connectionStatus = "success"
                        }
                    }
                }, label: {
                    Text("Test")
                })
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                
                Button(action: {
                    let conn = Connection(name: name, host: host, username: user, password: password, database: database, createdAt: Date())
                    context.insert(conn)
                    dismiss()
                }, label: {
                    Text("Save")
                })
            }
            .padding(.top, 10)
        }
        .frame(width: 250)
    }
}

#Preview {
    ConnectionFormView()
}
