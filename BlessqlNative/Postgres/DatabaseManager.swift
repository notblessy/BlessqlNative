import Foundation
import PostgresClientKit

final class DatabaseManager: ObservableObject {

    // MARK: - Published State

    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var connectionName = ""
    @Published var connectionURL = ""
    @Published var schemas: [SchemaItem] = []
    @Published var tableData = TableRow()
    @Published var selectedSchema = ""
    @Published var selectedTable = ""

    // Structure tab
    @Published var structureData: [ColumnDefinition] = []
    @Published var isLoadingStructure = false

    // Query tab
    @Published var queryResult = QueryResult.empty
    @Published var isExecutingQuery = false
    @Published var queryHistory: [QueryHistoryItem] = []

    // Functions
    @Published var functions: [String] = []

    // Sorting
    @Published var sortColumn: String? = nil
    @Published var sortDirection: SortDirection = .ascending

    enum SortDirection: String {
        case ascending = "ASC"
        case descending = "DESC"
    }

    // MARK: - Private

    private let dbQueue = DispatchQueue(label: "com.blessql.database", qos: .userInitiated)
    private var connection: PostgresClientKit.Connection?  // only touched on dbQueue
    private var connectAttemptID: UUID?  // tracks current attempt so stale ones are discarded

    deinit {
        let conn = connection
        dbQueue.async { conn?.close() }
    }

    // MARK: - Connect

    func connect(host: String, port: Int = 5432, database: String, user: String, password: String, name: String, useSSL: Bool = true) {
        // Set state synchronously (we're already on main thread from .onAppear)
        let attemptID = UUID()
        connectAttemptID = attemptID
        isConnecting = true
        isConnected = false
        error = nil
        connectionName = name
        connectionURL = "\(user)@\(host):\(port)/\(database)"

        let h = host, pt = port, d = database, u = user, p = password, ssl = useSSL

        // Timeout — fires on main after 10s
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self, self.connectAttemptID == attemptID, self.isConnecting else { return }
            self.isConnecting = false
            self.error = "Connection timed out (10 s). Check host, port, and SSL settings."
        }

        // Run on a disposable global thread (NOT the serial dbQueue)
        // so a hung TCP connect doesn't block future operations
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            do {
                let conn = try Self.openConnection(host: h, port: pt, database: d, user: u, password: p, ssl: ssl)

                // If timeout already fired, discard this connection
                guard self.connectAttemptID == attemptID else {
                    conn.close()
                    return
                }

                // Hand the connection to dbQueue
                self.dbQueue.sync {
                    self.connection = conn
                }

                // Load schemas on dbQueue
                let (loaded, schemaError) = self.dbQueue.sync {
                    self.loadSchemasSync(conn)
                }

                // Load functions for the first schema
                let firstSchema = loaded.first?.name ?? "public"
                let funcs = self.dbQueue.sync {
                    self.fetchFunctionsSync(conn, schema: firstSchema)
                }

                DispatchQueue.main.async {
                    guard self.connectAttemptID == attemptID else { return }
                    self.isConnected = true
                    self.isConnecting = false
                    self.schemas = loaded
                    self.selectedSchema = firstSchema
                    self.functions = funcs
                    if let schemaError {
                        self.error = "Connected but failed to load schemas: \(schemaError)"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    guard self.connectAttemptID == attemptID else { return }
                    self.isConnecting = false
                    self.error = "Connection failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Table operations

    func selectTable(schema: String, table: String) {
        selectedSchema = schema
        selectedTable = table
        sortColumn = nil
        sortDirection = .ascending
        loadPage(0)
        fetchTableStructure(schema: schema, table: table)
    }

    func loadPage(_ page: Int) {
        let schema = selectedSchema
        let table = selectedTable
        let sort = sortColumn
        let dir = sortDirection
        guard !schema.isEmpty, !table.isEmpty else { return }

        isLoading = true

        dbQueue.async { [weak self] in
            guard let self, let conn = self.connection else {
                DispatchQueue.main.async { self?.isLoading = false }
                return
            }

            let data = self.fetchPaginatedData(conn, schema: schema, table: table, page: page, pageSize: 200, sortColumn: sort, sortDirection: dir)

            DispatchQueue.main.async {
                self.tableData = data
                self.isLoading = false
            }
        }
    }

    func toggleSort(column: String) {
        if sortColumn == column {
            if sortDirection == .ascending {
                sortDirection = .descending
            } else {
                sortColumn = nil
                sortDirection = .ascending
            }
        } else {
            sortColumn = column
            sortDirection = .ascending
        }
        loadPage(0)
    }

    func refresh() {
        loadPage(tableData.currentPage)
    }

    func switchSchema(_ schema: String) {
        selectedSchema = schema
        selectedTable = ""
        tableData = TableRow()
        structureData = []
        sortColumn = nil
        sortDirection = .ascending

        dbQueue.async { [weak self] in
            guard let self, let conn = self.connection else { return }

            let tables = self.fetchTablesSync(conn, schema: schema)
            let funcs = self.fetchFunctionsSync(conn, schema: schema)

            DispatchQueue.main.async {
                // Update the tables for the selected schema
                if let idx = self.schemas.firstIndex(where: { $0.name == schema }) {
                    self.schemas[idx].tables = tables
                    self.schemas[idx].isExpanded = true
                }
                self.functions = funcs
            }
        }
    }

    func disconnect() {
        connectAttemptID = nil
        dbQueue.async { [weak self] in
            self?.connection?.close()
            self?.connection = nil
        }
        isConnected = false
        isConnecting = false
        schemas = []
        tableData = TableRow()
        selectedSchema = ""
        selectedTable = ""
        error = nil
        functions = []
        structureData = []
        isLoadingStructure = false
        queryResult = QueryResult.empty
        isExecutingQuery = false
        queryHistory = []
        sortColumn = nil
        sortDirection = .ascending
    }

    // MARK: - Connection helper

    /// Tries SSL modes and auth methods in order:
    /// 1. SSL + scram-sha-256, 2. SSL + md5, 3. no-SSL + scram-sha-256, 4. no-SSL + md5
    static func openConnection(host: String, port: Int, database: String, user: String, password: String, ssl: Bool) throws -> PostgresClientKit.Connection {
        var config = ConnectionConfiguration()
        config.host = host
        config.port = port
        config.database = database
        config.user = user
        config.socketTimeout = 10

        // Build list of (ssl, credential) combos to try
        let credentials: [Credential] = [.scramSHA256(password: password), .md5Password(password: password)]
        let sslModes: [Bool] = ssl ? [true, false] : [false]

        var lastError: Error?

        for sslMode in sslModes {
            config.ssl = sslMode
            for credential in credentials {
                config.credential = credential
                do {
                    let conn = try PostgresClientKit.Connection(configuration: config)
                    do {
                        let stmt = try conn.prepareStatement(text: "SELECT 1")
                        defer { stmt.close() }
                        _ = try stmt.execute()
                        return conn
                    } catch {
                        conn.close()
                        lastError = error
                    }
                } catch {
                    lastError = error
                }
            }
        }

        throw lastError ?? PostgresError.connectionClosed
    }

    // MARK: - Sync helpers (run on dbQueue)

    private let excludedSchemas = ["pg_catalog", "information_schema", "pg_toast"]

    private func loadSchemasSync(_ conn: PostgresClientKit.Connection) -> ([SchemaItem], String?) {
        let query = "SELECT schema_name FROM information_schema.schemata ORDER BY schema_name;"
        do {
            // Step 1: Collect all schema names first (fully consume cursor before opening another)
            var schemaNames: [String] = []
            let stmt = try conn.prepareStatement(text: query)
            defer { stmt.close() }
            let cursor = try stmt.execute()
            for row in cursor {
                let name = try row.get().columns[0].string()
                if !excludedSchemas.contains(name) {
                    schemaNames.append(name)
                }
            }

            // Step 2: Now fetch tables for each schema (safe — previous cursor is done)
            var items: [SchemaItem] = []
            for name in schemaNames {
                let tables = fetchTablesSync(conn, schema: name)
                var item = SchemaItem(name: name, tables: tables)
                if items.isEmpty && !tables.isEmpty { item.isExpanded = true }
                items.append(item)
            }
            return (items, nil)
        } catch {
            print("[DB] fetchSchemas error: \(error)")
            return ([], "\(error)")
        }
    }

    private func fetchTablesSync(_ conn: PostgresClientKit.Connection, schema: String) -> [String] {
        let query = "SELECT table_name FROM information_schema.tables WHERE table_schema = $1 AND table_type IN ('BASE TABLE', 'VIEW') ORDER BY table_name;"
        do {
            let stmt = try conn.prepareStatement(text: query)
            defer { stmt.close() }
            let cursor = try stmt.execute(parameterValues: [schema])

            var tables: [String] = []
            for row in cursor {
                tables.append(try row.get().columns[0].string())
            }
            return tables
        } catch {
            print("[DB] fetchTables error: \(error)")
            return []
        }
    }

    private func fetchFunctionsSync(_ conn: PostgresClientKit.Connection, schema: String) -> [String] {
        let query = """
            SELECT p.proname
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = $1
            ORDER BY p.proname;
            """
        do {
            let stmt = try conn.prepareStatement(text: query)
            defer { stmt.close() }
            let cursor = try stmt.execute(parameterValues: [schema])

            var names: [String] = []
            for row in cursor {
                names.append(try row.get().columns[0].string())
            }
            return names
        } catch {
            print("[DB] fetchFunctions error: \(error)")
            return []
        }
    }

    private func fetchPaginatedData(_ conn: PostgresClientKit.Connection, schema: String, table: String, page: Int, pageSize: Int, sortColumn: String? = nil, sortDirection: SortDirection = .ascending) -> TableRow {
        let offset = page * pageSize

        var orderClause = ""
        if let sortCol = sortColumn {
            orderClause = " ORDER BY \"\(sortCol)\" \(sortDirection.rawValue)"
        }

        let countQuery   = "SELECT COUNT(*) FROM \"\(schema)\".\"\(table)\";"
        let columnsQuery = "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = $1 AND table_name = $2 ORDER BY ordinal_position;"
        let dataQuery    = "SELECT * FROM \"\(schema)\".\"\(table)\"\(orderClause) LIMIT \(pageSize) OFFSET \(offset);"

        do {
            let countStmt = try conn.prepareStatement(text: countQuery)
            defer { countStmt.close() }
            let countCursor = try countStmt.execute()
            var totalCount = 0
            for row in countCursor {
                totalCount = try row.get().columns[0].int()
            }

            let colStmt = try conn.prepareStatement(text: columnsQuery)
            defer { colStmt.close() }
            let colCursor = try colStmt.execute(parameterValues: [schema, table])

            var fieldMap: [FieldSchema] = []
            for (index, row) in colCursor.enumerated() {
                let cols = try row.get().columns
                fieldMap.append(FieldSchema(
                    fieldName: try cols[0].string(),
                    fieldType: try cols[1].string(),
                    fieldIndex: index
                ))
            }

            let dataStmt = try conn.prepareStatement(text: dataQuery)
            defer { dataStmt.close() }
            let dataCursor = try dataStmt.execute(retrieveColumnMetadata: true)

            var result = TableRow(
                name: "\(schema).\(table)",
                totalCount: totalCount,
                currentPage: page,
                pageSize: pageSize
            )

            var rowIndex = 0
            for row in dataCursor {
                var fields: [Field] = []
                let columns = try row.get().columns

                for (colIdx, column) in columns.enumerated() {
                    if let fm = fieldMap.first(where: { $0.fieldIndex == colIdx }) {
                        let rawVal = column.rawValue
                        fields.append(Field(
                            id: fm.fieldIndex,
                            fieldName: fm.fieldName,
                            value: rawVal ?? "NULL",
                            type: fm.fieldType,
                            isNull: rawVal == nil
                        ))
                    }
                }

                result.rows.append(Row(id: rowIndex, fields: fields))
                rowIndex += 1
            }

            if let firstRow = result.rows.first {
                result.headers = firstRow.fields.map(\.fieldName)
            }

            return result
        } catch {
            print("[DB] fetchPaginatedData error: \(error)")
            return TableRow()
        }
    }
    // MARK: - Structure operations

    func fetchTableStructure(schema: String, table: String) {
        isLoadingStructure = true

        dbQueue.async { [weak self] in
            guard let self, let conn = self.connection else {
                DispatchQueue.main.async { self?.isLoadingStructure = false }
                return
            }

            let result = self.fetchStructureSync(conn, schema: schema, table: table)

            DispatchQueue.main.async {
                self.structureData = result
                self.isLoadingStructure = false
            }
        }
    }

    private func fetchStructureSync(_ conn: PostgresClientKit.Connection, schema: String, table: String) -> [ColumnDefinition] {
        let query = """
            SELECT DISTINCT ON (c.ordinal_position)
                c.ordinal_position,
                c.column_name,
                c.data_type,
                c.character_maximum_length,
                c.numeric_precision,
                c.column_default,
                c.is_nullable,
                CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END as is_primary_key,
                CASE WHEN fk.column_name IS NOT NULL THEN true ELSE false END as is_foreign_key,
                fk.foreign_ref,
                pgd.description as column_comment
            FROM information_schema.columns c
            LEFT JOIN (
                SELECT DISTINCT kcu.column_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                    ON tc.constraint_name = kcu.constraint_name
                    AND tc.table_schema = kcu.table_schema
                WHERE tc.constraint_type = 'PRIMARY KEY'
                    AND tc.table_schema = $1
                    AND tc.table_name = $2
            ) pk ON pk.column_name = c.column_name
            LEFT JOIN (
                SELECT DISTINCT ON (kcu.column_name)
                    kcu.column_name,
                    ccu.table_schema || '.' || ccu.table_name || '(' || ccu.column_name || ')' as foreign_ref
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                    ON tc.constraint_name = kcu.constraint_name
                    AND tc.table_schema = kcu.table_schema
                JOIN information_schema.constraint_column_usage ccu
                    ON tc.constraint_name = ccu.constraint_name
                    AND tc.table_schema = ccu.table_schema
                WHERE tc.constraint_type = 'FOREIGN KEY'
                    AND tc.table_schema = $1
                    AND tc.table_name = $2
            ) fk ON fk.column_name = c.column_name
            LEFT JOIN pg_catalog.pg_statio_all_tables st
                ON st.schemaname = c.table_schema AND st.relname = c.table_name
            LEFT JOIN pg_catalog.pg_description pgd
                ON pgd.objoid = st.relid AND pgd.objsubid = c.ordinal_position
            WHERE c.table_schema = $1 AND c.table_name = $2
            ORDER BY c.ordinal_position;
            """

        do {
            let stmt = try conn.prepareStatement(text: query)
            defer { stmt.close() }
            let cursor = try stmt.execute(parameterValues: [schema, table])

            var definitions: [ColumnDefinition] = []
            for row in cursor {
                let cols = try row.get().columns
                definitions.append(ColumnDefinition(
                    id: try cols[0].int(),
                    name: try cols[1].string(),
                    dataType: try cols[2].string(),
                    characterMaxLength: cols[3].rawValue.flatMap { Int($0) },
                    numericPrecision: cols[4].rawValue.flatMap { Int($0) },
                    columnDefault: cols[5].rawValue,
                    isNullable: (try cols[6].string()) == "YES",
                    isPrimaryKey: (cols[7].rawValue ?? "false") == "true",
                    isForeignKey: (cols[8].rawValue ?? "false") == "true",
                    foreignKeyRef: cols[9].rawValue,
                    comment: cols[10].rawValue
                ))
            }
            return definitions
        } catch {
            print("[DB] fetchStructure error: \(error)")
            return []
        }
    }

    // MARK: - Query operations

    func executeQuery(sql: String) {
        let trimmed = sql.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isExecutingQuery = true

        dbQueue.async { [weak self] in
            guard let self, let conn = self.connection else {
                DispatchQueue.main.async {
                    self?.isExecutingQuery = false
                    self?.queryResult = QueryResult(columns: [], rows: [], affectedRows: 0, executionTime: 0, error: "Not connected")
                }
                return
            }

            let startTime = CFAbsoluteTimeGetCurrent()
            let result = self.executeQuerySync(conn, sql: trimmed)
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime

            var finalResult = result
            finalResult.executionTime = elapsed

            let historyItem = QueryHistoryItem(sql: trimmed, timestamp: Date(), success: result.error == nil)

            DispatchQueue.main.async {
                self.queryResult = finalResult
                self.isExecutingQuery = false
                self.queryHistory.insert(historyItem, at: 0)
                if self.queryHistory.count > 50 {
                    self.queryHistory = Array(self.queryHistory.prefix(50))
                }
            }
        }
    }

    private func executeQuerySync(_ conn: PostgresClientKit.Connection, sql: String) -> QueryResult {
        do {
            let stmt = try conn.prepareStatement(text: sql)
            defer { stmt.close() }
            let cursor = try stmt.execute(retrieveColumnMetadata: true)

            var columns: [String] = []
            if let metadata = cursor.columns {
                columns = metadata.map { $0.name }
            }

            var rows: [[String]] = []
            var rowCount = 0

            if !columns.isEmpty {
                for row in cursor {
                    let cols = try row.get().columns
                    let values = cols.map { $0.rawValue ?? "NULL" }
                    rows.append(values)
                    rowCount += 1
                }
            }

            return QueryResult(
                columns: columns,
                rows: rows,
                affectedRows: rowCount,
                executionTime: 0,
                error: nil
            )
        } catch let error as PostgresClientKit.PostgresError {
            let msg: String
            switch error {
            case .sqlError(notice: let notice): msg = notice.message ?? "SQL error"
            default: msg = "\(error)"
            }
            return QueryResult(columns: [], rows: [], affectedRows: 0, executionTime: 0, error: msg)
        } catch {
            return QueryResult(columns: [], rows: [], affectedRows: 0, executionTime: 0, error: error.localizedDescription)
        }
    }
}

// MARK: - Standalone test helper (used by connection forms)

func performTestConnection(
    host: String, port: Int = 5432, database: String, user: String, password: String,
    useSSL: Bool = true,
    completion: @escaping (String?) -> Void
) {
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let conn = try DatabaseManager.openConnection(
                host: host, port: port, database: database,
                user: user, password: password, ssl: useSSL
            )
            conn.close()
            DispatchQueue.main.async { completion(nil) }
        } catch let error as PostgresClientKit.PostgresError {
            let msg: String
            switch error {
            case .sqlError(notice: let notice): msg = notice.message ?? "SQL error"
            default: msg = "Connection error: \(error)"
            }
            DispatchQueue.main.async { completion(msg) }
        } catch {
            DispatchQueue.main.async { completion("Connection error: \(error.localizedDescription)") }
        }
    }
}
