import SwiftUI

struct QueryEditorView: View {
    @ObservedObject var db: DatabaseManager

    @State private var sqlText: String = ""
    @State private var resultColumnWidths: [String: CGFloat] = [:]

    private let rowHeight: CGFloat = 28
    private let defaultColWidth: CGFloat = 150

    var body: some View {
        VSplitView {
            editorPane
                .frame(minHeight: 120, idealHeight: 200)

            resultsPane
                .frame(minHeight: 150)
        }
    }

    // MARK: - Editor Pane

    private var editorPane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    db.executeQuery(sql: sqlText)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                        Text("Run")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blessqlPrimary)
                .controlSize(.small)
                .keyboardShortcut("r", modifiers: .command)
                .disabled(sqlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || db.isExecutingQuery)

                if db.isExecutingQuery {
                    ProgressView()
                        .controlSize(.small)
                }

                Spacer()

                Menu {
                    if db.queryHistory.isEmpty {
                        Text("No history")
                    } else {
                        ForEach(db.queryHistory.prefix(20)) { item in
                            Button {
                                sqlText = item.sql
                            } label: {
                                HStack {
                                    Image(systemName: item.success ? "checkmark.circle" : "xmark.circle")
                                    Text(String(item.sql.prefix(80)) + (item.sql.count > 80 ? "..." : ""))
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 10))
                        Text("History")
                            .font(.system(size: 11))
                    }
                }
                .menuStyle(.borderlessButton)
                .frame(width: 90)

                Button {
                    sqlText = ""
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .help("Clear editor")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color(nsColor: .separatorColor)).frame(height: 1)
            }

            TextEditor(text: $sqlText)
                .font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(4)
        }
    }

    // MARK: - Results Pane

    private var resultsPane: some View {
        VStack(spacing: 0) {
            if let error = db.queryResult.error {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .textSelection(.enabled)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blessqlError.opacity(0.3))
            } else if db.queryResult.columns.isEmpty && db.queryResult == QueryResult.empty {
                Spacer()
                Text("Run a query to see results")
                    .font(.system(size: 13))
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                Spacer()
            } else if db.queryResult.columns.isEmpty {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    Text(db.queryResult.statusMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                queryResultsGrid
            }

            Divider()
            HStack {
                Text(db.queryResult == QueryResult.empty ? "Ready" : db.queryResult.statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    // MARK: - Query Results Grid (Spreadsheet Style)

    private var queryResultsGrid: some View {
        GeometryReader { geo in
            let columns = db.queryResult.columns
            let rows = db.queryResult.rows
            let headerHeight: CGFloat = 30
            let availableHeight = geo.size.height - headerHeight
            let visibleRowCount = max(Int(availableHeight / rowHeight), 1)

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 0) {
                        Text("#")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 44, height: headerHeight)
                            .background(Color(nsColor: .controlBackgroundColor))

                        Rectangle().fill(Color(nsColor: .separatorColor)).frame(width: 1)

                        ForEach(columns, id: \.self) { col in
                            HStack(spacing: 0) {
                                Text(col)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                    .frame(width: resColWidth(col) - 9, alignment: .leading)
                                    .padding(.leading, 8)
                                    .frame(height: headerHeight)

                                Resizer(columnHeight: headerHeight, columnWidth: Binding(
                                    get: { resColWidth(col) },
                                    set: { resultColumnWidths[col] = max($0, 60) }
                                ))
                                .frame(width: 1)
                                .foregroundColor(Color(nsColor: .separatorColor))
                            }
                        }
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color(nsColor: .separatorColor)).frame(height: 1)
                    }

                    // Body
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 0) {
                            ForEach(0..<rows.count, id: \.self) { idx in
                                queryDataRow(row: rows[idx], index: idx, columns: columns)
                            }
                            let emptyStart = rows.count
                            let emptyCount = max(visibleRowCount - rows.count, 0)
                            ForEach(0..<emptyCount, id: \.self) { idx in
                                queryEmptyRow(index: emptyStart + idx, columns: columns)
                            }
                        }
                    }
                }
                .frame(minWidth: 44 + 1 + columns.reduce(0) { $0 + resColWidth($1) })
            }
        }
    }

    private func queryDataRow(row: [String], index: Int, columns: [String]) -> some View {
        HStack(spacing: 0) {
            Text("\(index + 1)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                .frame(width: 44, height: rowHeight)

            Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.5)).frame(width: 1)

            ForEach(Array(zip(columns, row).enumerated()), id: \.offset) { _, pair in
                let (colName, value) = pair
                HStack(spacing: 0) {
                    Group {
                        if value == "NULL" {
                            Text("NULL")
                                .font(.system(size: 11, design: .monospaced))
                                .italic()
                                .foregroundColor(Color(nsColor: .placeholderTextColor))
                        } else {
                            Text(value)
                                .font(.system(size: 11))
                        }
                    }
                    .lineLimit(1)
                    .frame(width: resColWidth(colName) - 17, alignment: .leading)
                    .padding(.leading, 8)
                    .frame(height: rowHeight)

                    Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.3)).frame(width: 1)
                }
            }
        }
        .background(zebraColor(index))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.15)).frame(height: 1)
        }
    }

    private func queryEmptyRow(index: Int, columns: [String]) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 44, height: rowHeight)
            Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.5)).frame(width: 1)
            ForEach(columns, id: \.self) { col in
                HStack(spacing: 0) {
                    Color.clear.frame(width: resColWidth(col) - 1, height: rowHeight)
                    Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.3)).frame(width: 1)
                }
            }
        }
        .background(zebraColor(index))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.15)).frame(height: 1)
        }
    }

    private func resColWidth(_ col: String) -> CGFloat {
        resultColumnWidths[col] ?? defaultColWidth
    }

    private func zebraColor(_ index: Int) -> Color {
        index % 2 == 0
            ? Color(nsColor: .controlBackgroundColor).opacity(0.0)
            : Color(nsColor: .controlBackgroundColor).opacity(0.6)
    }
}
