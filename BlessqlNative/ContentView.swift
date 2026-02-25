import SwiftUI

struct ContentView: View {
    let defaults = UserDefaults.standard

    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow

    @StateObject private var db = DatabaseManager()

    @StateObject private var tabManager = TabManager()

    @State private var sidebarFilter: String = ""
    @State private var functionsExpanded = false
    @State private var tablesExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            if db.isConnecting && !db.isDisconnected {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Connecting...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                HSplitView {
                    sidebarView
                        .frame(minWidth: 180, idealWidth: 250, maxWidth: 300)
                    detailView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .navigationTitle(db.connectionName)
        .onAppear {
            tabManager.attach(db: db)
            connect()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button { } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                }
                .disabled(true)

                Button { } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                }
                .disabled(true)
            }

            ToolbarItem(placement: .principal) {
                if db.isDisconnected {
                    Button {
                        db.reconnect()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.trianglebadge.exclamationmark")
                                .font(.system(size: 10))
                            Text("Disconnected — tap to reconnect")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blessqlError.opacity(0.5))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(toolbarTitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 12)
                }
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    tabManager.openQueryTab()
                } label: {
                    Image(systemName: "terminal")
                        .font(.system(size: 12))
                }
                .help("New SQL Query")

                Button {
                    if let activeTab = tabManager.activeTab {
                        switch activeTab.kind {
                        case .table:
                            db.refresh()
                        case .query:
                            if !tabManager.sqlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                db.executeQuery(sql: tabManager.sqlText)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .help("Refresh")
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!db.isConnected || tabManager.activeTab == nil)
            }
        }
        .alert("Error", isPresented: .init(
            get: { db.error != nil },
            set: { if !$0 { db.error = nil } }
        )) {
            Button("OK") { db.error = nil }
        } message: {
            Text(db.error ?? "")
        }
    }

    // MARK: - Toolbar Title

    private var toolbarTitle: String {
        var parts = [db.connectionURL]
        if !db.selectedTable.isEmpty {
            parts.append("\(db.selectedSchema).\(db.selectedTable)")
        }
        return parts.joined(separator: " : ")
    }

    // MARK: - Sidebar

    private var currentTables: [String] {
        guard let schema = db.schemas.first(where: { $0.name == db.selectedSchema }) else {
            return []
        }
        return schema.tables.filter {
            sidebarFilter.isEmpty || $0.localizedCaseInsensitiveContains(sidebarFilter)
        }
    }

    private var filteredFunctions: [String] {
        db.functions.filter {
            sidebarFilter.isEmpty || $0.localizedCaseInsensitiveContains(sidebarFilter)
        }
    }

    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                TextField("Search for item...", text: $sidebarFilter)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                if !sidebarFilter.isEmpty {
                    Button {
                        sidebarFilter = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.5)).frame(height: 1)
            }

            // Functions & Tables tree
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    // Functions section
                    sectionHeader(
                        title: "Functions",
                        isExpanded: $functionsExpanded
                    )

                    if functionsExpanded {
                        if filteredFunctions.isEmpty {
                            Text("No functions")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .padding(.leading, 30)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(filteredFunctions, id: \.self) { fn in
                                HStack(spacing: 5) {
                                    Image(systemName: "function")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                    Text(fn)
                                        .font(.system(size: 11))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.leading, 30)
                                .padding(.trailing, 10)
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    // Tables section
                    sectionHeader(
                        title: "Tables",
                        isExpanded: $tablesExpanded
                    )

                    if tablesExpanded {
                        ForEach(currentTables, id: \.self) { table in
                            let isSelected: Bool = {
                                if case .table(_, let t) = tabManager.activeTab?.kind {
                                    return t == table
                                }
                                return false
                            }()

                            Button {
                                tabManager.openTable(schema: db.selectedSchema, table: table)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "tablecells")
                                        .font(.system(size: 9))
                                        .foregroundColor(isSelected ? .white : .secondary)
                                    Text(table)
                                        .font(.system(size: 11))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.leading, 30)
                                .padding(.trailing, 10)
                                .padding(.vertical, 4)
                                .background(
                                    isSelected
                                        ? RoundedRectangle(cornerRadius: 4).fill(Color.accentColor)
                                        : RoundedRectangle(cornerRadius: 4).fill(Color.clear)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Bottom bar: + button, schema picker, refresh
            sidebarBottomBar
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .trailing) {
            Rectangle().fill(Color(nsColor: .separatorColor)).frame(width: 1)
        }
    }

    private func sectionHeader(title: String, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 10)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.none)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var sidebarBottomBar: some View {
        HStack(spacing: 8) {
            Button { } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .help("Add item")

            if !db.schemas.isEmpty {
                Picker("", selection: Binding(
                    get: { db.selectedSchema },
                    set: { newSchema in
                        db.switchSchema(newSchema)
                    }
                )) {
                    ForEach(db.schemas) { schema in
                        Text(schema.name).tag(schema.name)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            } else {
                Spacer()
            }

            Button {
                if !db.selectedSchema.isEmpty {
                    db.switchSchema(db.selectedSchema)
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10))
            }
            .buttonStyle(.borderless)
            .help("Reload")
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .overlay(alignment: .top) {
            Rectangle().fill(Color(nsColor: .separatorColor)).frame(height: 1)
        }
    }

    // MARK: - Detail View

    private var detailView: some View {
        VStack(spacing: 0) {
            if !tabManager.tabs.isEmpty {
                TabBarView(tabManager: tabManager)
            }

            if db.isLoading || db.isLoadingStructure || db.isExecutingQuery {
                GeometryReader { geo in
                    let barWidth = geo.size.width * 0.3
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: barWidth, height: 2)
                        .offset(x: 0)
                        .modifier(IndeterminateProgressModifier(width: geo.size.width, barWidth: barWidth))
                }
                .frame(height: 2)
                .clipped()
            }

            if let activeTab = tabManager.activeTab {
                switch activeTab.kind {
                case .table(let schema, let table):
                    switch tabManager.selectedDetailTab {
                    case .data:
                        TableContentView(db: db, selectedTab: $tabManager.selectedDetailTab, columnWidths: $tabManager.tableColumnWidths)
                    case .structure:
                        TableStructureView(db: db, columnWidths: $tabManager.structureColumnWidths)
                            .onAppear {
                                if db.structureData.isEmpty {
                                    db.fetchTableStructure(schema: schema, table: table)
                                }
                            }
                    }
                    detailBottomBar

                case .query:
                    QueryEditorView(db: db, sqlText: $tabManager.sqlText, columnWidths: $tabManager.queryColumnWidths)
                }
            } else {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 36))
                        .foregroundColor(Color(nsColor: .quaternaryLabelColor))
                    Text("Select a table or open a query")
                        .font(.system(size: 13))
                        .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                }
                Spacer()
            }
        }
    }

    // MARK: - Detail Bottom Bar

    private var detailBottomBar: some View {
        HStack(spacing: 0) {
            bottomBarLeft
            Spacer()
            bottomBarCenter
            Spacer()
            bottomBarRight
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .top) {
            Rectangle().fill(Color(nsColor: .separatorColor)).frame(height: 1)
        }
    }

    private var bottomBarLeft: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases) { tab in
                Button {
                    tabManager.selectedDetailTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 11, weight: tabManager.selectedDetailTab == tab ? .semibold : .regular))
                        .foregroundColor(tabManager.selectedDetailTab == tab ? .primary : .secondary)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
                .background(tabManager.selectedDetailTab == tab ? Color(nsColor: .controlBackgroundColor) : Color.clear)
            }

            Rectangle().fill(Color(nsColor: .separatorColor)).frame(width: 1, height: 16)
                .padding(.horizontal, 4)

            Button { } label: {
                HStack(spacing: 3) {
                    Image(systemName: "plus")
                        .font(.system(size: 9))
                    Text("Row")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .help("Insert row (coming soon)")
        }
    }

    @ViewBuilder
    private var bottomBarCenter: some View {
        if db.tableData.totalCount > 0 && tabManager.selectedDetailTab == .data {
            let prefix = db.tableData.isEstimatedCount ? "~" : ""
            Text("\(db.tableData.rangeStart)-\(db.tableData.rangeEnd) of \(prefix)\(db.tableData.totalCount) rows")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var bottomBarRight: some View {
        HStack(spacing: 8) {
            Button { } label: {
                Text("Filters")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Filters (coming soon)")

            Button { } label: {
                Text("Columns")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Columns (coming soon)")

            if db.tableData.totalPages > 1 && tabManager.selectedDetailTab == .data {
                Button {
                    db.loadPage(db.tableData.currentPage - 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .disabled(db.tableData.currentPage <= 0)

                Button {
                    db.loadPage(db.tableData.currentPage + 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .disabled(db.tableData.currentPage >= db.tableData.totalPages - 1)
            }
        }
    }

    // MARK: - Actions

    private func connect() {
        guard let jsonStr = defaults.string(forKey: TemporaryStorage.activeConnection),
              let conn = Connection.parseJSON(jsonStr) else {
            db.error = "No connection data found."
            return
        }
        db.connect(host: conn.host, port: conn.port, database: conn.database, user: conn.username, password: conn.password, name: conn.name, useSSL: conn.useSSL)
    }

    private func disconnect() {
        db.disconnect()
        dismissWindow(id: "dashboard")
        openWindow(id: "connection")
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Indeterminate Progress Bar

private struct IndeterminateProgressModifier: ViewModifier, Animatable {
    let width: CGFloat
    let barWidth: CGFloat
    @State private var offsetX: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offsetX)
            .onAppear {
                offsetX = -barWidth
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    offsetX = width
                }
            }
    }
}

#Preview {
    ContentView()
}
