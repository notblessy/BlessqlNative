import Foundation

// MARK: - Tab Kind

enum WorkspaceTabKind: Equatable {
    case table(schema: String, table: String)
    case query
}

// MARK: - Tab Identity

struct WorkspaceTab: Identifiable, Equatable {
    let id: UUID
    var kind: WorkspaceTabKind
    var title: String
    var icon: String

    init(kind: WorkspaceTabKind) {
        self.id = UUID()
        self.kind = kind
        switch kind {
        case .table(_, let table):
            self.title = table
            self.icon = "tablecells"
        case .query:
            self.title = "Query"
            self.icon = "terminal"
        }
    }

    static func == (lhs: WorkspaceTab, rhs: WorkspaceTab) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Per-Tab State Snapshot

struct TabStateSnapshot {
    // Table-tab state
    var tableData: TableRow
    var structureData: [ColumnDefinition]
    var sortColumn: String?
    var sortDirection: DatabaseManager.SortDirection
    var selectedDetailTab: DetailTab
    var tableColumnWidths: [String: CGFloat]
    var structureColumnWidths: [String: CGFloat]

    // Query-tab state
    var sqlText: String
    var queryResult: QueryResult
    var queryColumnWidths: [String: CGFloat]

    static func newTable() -> TabStateSnapshot {
        TabStateSnapshot(
            tableData: TableRow(),
            structureData: [],
            sortColumn: nil,
            sortDirection: .ascending,
            selectedDetailTab: .data,
            tableColumnWidths: [:],
            structureColumnWidths: [:],
            sqlText: "",
            queryResult: .empty,
            queryColumnWidths: [:]
        )
    }

    static func newQuery() -> TabStateSnapshot {
        TabStateSnapshot(
            tableData: TableRow(),
            structureData: [],
            sortColumn: nil,
            sortDirection: .ascending,
            selectedDetailTab: .data,
            tableColumnWidths: [:],
            structureColumnWidths: [:],
            sqlText: "",
            queryResult: .empty,
            queryColumnWidths: [:]
        )
    }
}
