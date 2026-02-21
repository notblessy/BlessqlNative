import SwiftUI
import SwiftData

struct ConnectionListView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.modelContext) private var context

    @State private var search: String = ""
    @State private var selection: String = ""
    @State private var showSheet: Bool = false
    @State private var showUpdateSheet: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var connectionToDelete: Connection?

    @Query(sort: \Connection.createdAt) private var connections: [Connection]

    private var filteredConnections: [Connection] {
        if search.isEmpty {
            return connections
        }
        return connections.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search + Add
            HStack {
                Searchable(search: $search)
                Button {
                    showSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Connection list
            if filteredConnections.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bolt.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.blessqlDimmed)
                    Text("No connections")
                        .font(.system(size: 14))
                        .foregroundColor(.blessqlDimmed)
                    if connections.isEmpty {
                        Text("Click + to add a new connection")
                            .font(.system(size: 12))
                            .foregroundColor(.blessqlDimmed)
                    }
                }
                Spacer()
            } else {
                List(filteredConnections, selection: $selection) { conn in
                    ConnectionRowView(connection: conn)
                        .tag(conn.id.uuidString)
                        .onTapGesture(count: 2) {
                            connectTo(conn)
                        }
                        .contextMenu {
                            Button("Connect") {
                                connectTo(conn)
                            }
                            Button("Edit") {
                                selection = conn.id.uuidString
                                showUpdateSheet.toggle()
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                connectionToDelete = conn
                                showDeleteAlert = true
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showSheet) {
            ConnectionFormView()
                .padding()
        }
        .sheet(isPresented: $showUpdateSheet) {
            if let conn = connections.first(where: { $0.id.uuidString == selection }) {
                ConnectionUpdateFormView(connection: conn)
                    .padding()
            }
        }
        .alert("Delete Connection", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let conn = connectionToDelete {
                    context.delete(conn)
                    connectionToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this connection?")
        }
    }

    private func connectTo(_ conn: Connection) {
        let defaults = UserDefaults.standard
        defaults.set(conn.toStringJSON(), forKey: TemporaryStorage.activeConnection)
        openWindow(id: "dashboard")
        dismissWindow(id: "connection")
    }
}

struct ConnectionRowView: View {
    let connection: Connection

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive.connected.to.line.below")
                .font(.system(size: 18))
                .foregroundColor(.blessqlPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(connection.name)
                    .font(.system(size: 13, weight: .medium))
                Text("\(connection.username)@\(connection.host):\(connection.port)/\(connection.database)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("PostgreSQL")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blessqlSecondary)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConnectionListView()
}
