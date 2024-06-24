//
//  ConnectionListView.swift
//  BlessqlNative
//
//  Created by Frederich Blessy on 07/06/24.
//

import SwiftUI
import SwiftData

struct ConnectionListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Connection.createdAt) private var connections: [Connection]
    @State private var search: String = ""
    
    @State private var selection: String = ""
    
    @State var showSheet: Bool = false
    @State var showUpdateSheet: Bool = false
    
    var body: some View {
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
        }
        
        HStack {
            if search.isEmpty {
                List(connections, selection: $selection) { conn in
                    Label(conn.name, systemImage: "bolt.ring.closed")
                        .tag(conn.id.uuidString)
                        .listRowSeparator(.hidden)
                        .contextMenu {
                            Button("Edit", role: .destructive) {
                                if let book = connections.first(where: {$0.id == conn.id}) {
                                    context.delete(book)
                                }
                            }
                            Button("Delete", role: .destructive) {
                                if let book = connections.first(where: {$0.id == conn.id}) {
                                    context.delete(book)
                                }
                            }
                        }
                        .sheet(isPresented: $showUpdateSheet, content: {
                            ConnectionUpdateFormView(connection: conn)
                                .padding()
                        })
                }
            } else {
                List(connections.filter({$0.name.contains(search)}), selection: $selection) { conn in
                    Label(conn.name, systemImage: "bolt.ring.closed")
                        .tag(conn.id.uuidString)
                        .listRowSeparator(.hidden)
                }
            }
        }
    }
}

#Preview {
    ConnectionListView()
}
