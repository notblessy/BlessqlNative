import SwiftUI

struct ConnectionUpdateFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss

    let connection: Connection

    @State private var connectionStatus: String = ""
    @State private var isTesting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @State private var name: String = ""
    @State private var host: String = ""
    @State private var port: String = ""
    @State private var user: String = ""
    @State private var password: String = ""
    @State private var database: String = ""
    @State private var useSSL: Bool = true

    private var portValue: Int { Int(port) ?? 5432 }

    var body: some View {
        VStack(spacing: 8) {
            Text("Edit Connection")
                .font(.headline)
                .padding(.bottom, 4)

            InputText(label: "Name", showLabel: true, borderStyle: connectionStatus, value: $name)

            HStack(spacing: 8) {
                InputText(label: "Host", showLabel: true, borderStyle: connectionStatus, value: $host)
                InputText(label: "Port", placeholder: "5432", showLabel: false, borderStyle: connectionStatus, value: $port)
                    .frame(width: 64)
            }

            InputText(label: "User", showLabel: true, borderStyle: connectionStatus, value: $user)
            SecureInput(label: "Password", showLabel: true, borderStyle: connectionStatus, value: $password)
            InputText(label: "Database", showLabel: true, borderStyle: connectionStatus, value: $database)

            HStack {
                Text("SSL")
                    .frame(width: 70, alignment: .leading)
                Toggle("", isOn: $useSSL)
                    .toggleStyle(.switch)
                    .labelsHidden()
                Spacer()
            }

            HStack {
                Button("Cancel") { dismiss() }

                Spacer()

                Button("Test") {
                    isTesting = true
                    performTestConnection(host: host, port: portValue, database: database, user: user, password: password, useSSL: useSSL) { error in
                        isTesting = false
                        if let error {
                            alertMessage = error
                            showAlert = true
                            connectionStatus = "error"
                        } else {
                            connectionStatus = "success"
                        }
                    }
                }
                .disabled(isTesting)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }

                if isTesting {
                    ProgressView()
                        .controlSize(.small)
                }

                Button("Save") {
                    connection.name = name
                    connection.host = host
                    connection.port = portValue
                    connection.username = user
                    connection.password = password
                    connection.database = database
                    connection.useSSL = useSSL
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
        }
        .frame(width: 320)
        .onAppear {
            name = connection.name
            host = connection.host
            port = String(connection.port)
            user = connection.username
            password = connection.password
            database = connection.database
            useSSL = connection.useSSL
        }
    }
}

#Preview {
    ConnectionFormView()
}
