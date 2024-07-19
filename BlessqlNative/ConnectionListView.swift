//
//  ConnectionListView.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 07/06/24.
//

import SwiftUI
import SwiftData

struct ConnectionListView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.modelContext) private var context
    @State private var search: String = ""
    
    @State private var selection: String = ""
    
    @State var showSheet: Bool = false
    @State var showUpdateSheet: Bool = false
    @State var showAlertConnection: Bool = false
    
    
    @Query(sort: \Connection.createdAt) private var connections: [Connection]
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Searchable(search: $search)
                    .padding(.bottom, 5)
                
                Button {
                    showSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                        .padding(.vertical, 6)
                }
                .padding(.top, -1)
                .foregroundStyle(Color.gray)
                .sheet(isPresented: $showSheet, content: {
                    ConnectionFormView()
                        .padding()
                })
                .sheet(isPresented: $showUpdateSheet, content: {
                    let conn = connections.first(where: {$0.id.uuidString == selection})
                    ConnectionUpdateFormView(connection: conn!)
                        .padding()
                })
            }
            
            HStack {
                if search.isEmpty {
                    List(connections, selection: $selection) { conn in
                        Label(conn.name, systemImage: "bolt.ring.closed")
                            .tag(conn.id.uuidString)
                            .listRowSeparator(.hidden)
                            .contextMenu {
                                Button("Connect") {
                                    if let conn = connections.first(where: { $0.id.uuidString == selection }) {
                                        let defaults = UserDefaults.standard
                                        defaults.set(
                                            conn.toStringJSON(),
                                            forKey: TemporaryStorage.activeConnection
                                        )
                                        
                                        openWindow(id: "dashboard")
                                        dismissWindow(id: "connection")
                                    } else {
                                        showAlertConnection.toggle()
                                    }
                                }
                                Button("Edit") {
                                    showUpdateSheet.toggle()
                                }
                                Button("Delete", role: .destructive) {
                                    if let c = connections.first(where: {$0.id == conn.id}) {
                                        context.delete(c)
                                    }
                                }
                            }
                    }
                } else {
                    List(connections.filter({$0.name.contains(search)}), selection: $selection) { conn in
                        Label(conn.name, systemImage: "bolt.ring.closed")
                            .tag(conn.id.uuidString)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .alert(isPresented: $showAlertConnection) {
                Alert(
                    title: Text("Not Found"),
                    message: Text("Please select connection."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    ConnectionListView()
}
