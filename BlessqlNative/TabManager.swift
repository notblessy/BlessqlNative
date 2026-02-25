import SwiftUI
import Combine

final class TabManager: ObservableObject {

    // MARK: - Published State

    @Published var tabs: [WorkspaceTab] = []
    @Published var activeTabID: UUID? = nil

    // View-level state owned by TabManager so it persists per-tab
    @Published var selectedDetailTab: DetailTab = .data
    @Published var tableColumnWidths: [String: CGFloat] = [:]
    @Published var structureColumnWidths: [String: CGFloat] = [:]
    @Published var queryColumnWidths: [String: CGFloat] = [:]
    @Published var sqlText: String = ""

    // MARK: - Private

    private var snapshots: [UUID: TabStateSnapshot] = [:]
    private weak var db: DatabaseManager?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    func attach(db: DatabaseManager) {
        self.db = db

        // Keep active tab's snapshot in sync with async DB results
        db.$tableData
            .sink { [weak self] newData in
                guard let self, let id = self.activeTabID else { return }
                self.snapshots[id]?.tableData = newData
            }
            .store(in: &cancellables)

        db.$structureData
            .sink { [weak self] newData in
                guard let self, let id = self.activeTabID else { return }
                self.snapshots[id]?.structureData = newData
            }
            .store(in: &cancellables)

        db.$queryResult
            .sink { [weak self] newResult in
                guard let self, let id = self.activeTabID else { return }
                self.snapshots[id]?.queryResult = newResult
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed

    var activeTab: WorkspaceTab? {
        guard let id = activeTabID else { return nil }
        return tabs.first(where: { $0.id == id })
    }

    // MARK: - Open Table Tab

    func openTable(schema: String, table: String) {
        // Focus existing tab if already open
        if let existing = tabs.first(where: {
            if case .table(let s, let t) = $0.kind {
                return s == schema && t == table
            }
            return false
        }) {
            switchToTab(existing.id)
            return
        }

        saveCurrentTabState()

        let tab = WorkspaceTab(kind: .table(schema: schema, table: table))
        snapshots[tab.id] = .newTable()
        tabs.append(tab)

        activeTabID = tab.id
        restoreTabState(tab.id)

        // Trigger data load
        db?.selectTable(schema: schema, table: table)
    }

    // MARK: - Open Query Tab

    func openQueryTab() {
        saveCurrentTabState()

        var tab = WorkspaceTab(kind: .query)
        let queryCount = tabs.filter {
            if case .query = $0.kind { return true }
            return false
        }.count
        tab.title = "Query \(queryCount + 1)"

        snapshots[tab.id] = .newQuery()
        tabs.append(tab)

        activeTabID = tab.id
        restoreTabState(tab.id)
    }

    // MARK: - Switch Tab

    func switchToTab(_ tabID: UUID) {
        guard tabID != activeTabID else { return }
        guard tabs.contains(where: { $0.id == tabID }) else { return }

        saveCurrentTabState()
        activeTabID = tabID
        restoreTabState(tabID)
    }

    // MARK: - Close Tab

    func closeTab(_ tabID: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }

        snapshots.removeValue(forKey: tabID)
        tabs.remove(at: index)

        if activeTabID == tabID {
            if tabs.isEmpty {
                activeTabID = nil
                clearDatabaseManager()
            } else {
                let newIndex = min(index, tabs.count - 1)
                activeTabID = tabs[newIndex].id
                restoreTabState(tabs[newIndex].id)
            }
        }
    }

    // MARK: - Save / Restore

    func saveCurrentTabState() {
        guard let id = activeTabID, let db = db else { return }

        var snapshot = snapshots[id] ?? .newTable()

        snapshot.tableData = db.tableData
        snapshot.structureData = db.structureData
        snapshot.sortColumn = db.sortColumn
        snapshot.sortDirection = db.sortDirection
        snapshot.selectedDetailTab = selectedDetailTab
        snapshot.tableColumnWidths = tableColumnWidths
        snapshot.structureColumnWidths = structureColumnWidths

        snapshot.sqlText = sqlText
        snapshot.queryResult = db.queryResult
        snapshot.queryColumnWidths = queryColumnWidths

        snapshots[id] = snapshot
    }

    private func restoreTabState(_ tabID: UUID) {
        guard let snapshot = snapshots[tabID], let db = db else { return }
        guard let tab = tabs.first(where: { $0.id == tabID }) else { return }

        db.tableData = snapshot.tableData
        db.structureData = snapshot.structureData
        db.sortColumn = snapshot.sortColumn
        db.sortDirection = snapshot.sortDirection
        db.queryResult = snapshot.queryResult

        switch tab.kind {
        case .table(let schema, let table):
            db.selectedTable = table
            db.selectedSchema = schema
        case .query:
            db.selectedTable = ""
        }

        selectedDetailTab = snapshot.selectedDetailTab
        tableColumnWidths = snapshot.tableColumnWidths
        structureColumnWidths = snapshot.structureColumnWidths
        queryColumnWidths = snapshot.queryColumnWidths
        sqlText = snapshot.sqlText
    }

    private func clearDatabaseManager() {
        guard let db = db else { return }
        db.tableData = TableRow()
        db.structureData = []
        db.sortColumn = nil
        db.sortDirection = .ascending
        db.queryResult = .empty
        db.selectedTable = ""
        selectedDetailTab = .data
        tableColumnWidths = [:]
        structureColumnWidths = [:]
        queryColumnWidths = [:]
        sqlText = ""
    }
}
