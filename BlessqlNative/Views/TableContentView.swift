import SwiftUI

struct TableContentView: View {
    @ObservedObject var db: DatabaseManager
    @Binding var selectedTab: DetailTab

    @State private var columnWidths: [String: CGFloat] = [:]

    private let rowHeight: CGFloat = 28
    private let defaultColWidth: CGFloat = 150

    var body: some View {
        VStack(spacing: 0) {
            if db.isLoading {
                Spacer()
                ProgressView()
                    .controlSize(.small)
                Spacer()
            } else {
                spreadsheetGrid
            }
        }
        .onChange(of: db.selectedTable) { _ in
            columnWidths = [:]
        }
    }

    // MARK: - Spreadsheet Grid

    private var spreadsheetGrid: some View {
        GeometryReader { geo in
            let headers = db.tableData.headers
            let rows = db.tableData.rows
            let availableHeight = geo.size.height - 28
            let visibleRowCount = max(Int(ceil(availableHeight / rowHeight)), 1)
            let gridWidth = max(totalGridWidth(headers: headers), geo.size.width)

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    headerRow(headers: headers, gridWidth: gridWidth)
                        .fixedSize(horizontal: false, vertical: true)

                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 0) {
                            ForEach(rows, id: \.id) { row in
                                DataRowView(
                                    row: row,
                                    headers: headers,
                                    columnWidths: columnWidths,
                                    defaultColWidth: defaultColWidth,
                                    rowHeight: rowHeight,
                                    gridWidth: gridWidth
                                )
                            }
                            let emptyCount = max(visibleRowCount - rows.count, 0)
                            if emptyCount > 0 {
                                ForEach(0..<emptyCount, id: \.self) { idx in
                                    emptyRow(index: rows.count + idx, headers: headers, gridWidth: gridWidth)
                                        .id("empty-\(idx)")
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: gridWidth, minHeight: geo.size.height, alignment: .top)
            }
        }
    }

    // MARK: - Header

    private func headerRow(headers: [String], gridWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(headers, id: \.self) { header in
                HStack(spacing: 0) {
                    Button {
                        db.toggleSort(column: header)
                    } label: {
                        HStack(spacing: 3) {
                            Text(header)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if db.sortColumn == header {
                                Image(systemName: db.sortDirection == .ascending ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.blessqlPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                    }
                    .buttonStyle(.plain)
                    .frame(width: colWidth(header) - 1, height: 28)

                    Resizer(columnHeight: 28, columnWidth: Binding(
                        get: { colWidth(header) },
                        set: { columnWidths[header] = $0 }
                    ))
                }
            }
        }
        .frame(minWidth: gridWidth, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(nsColor: .separatorColor)).frame(height: 1)
        }
    }

    // MARK: - Empty Row

    private func emptyRow(index: Int, headers: [String], gridWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(headers, id: \.self) { header in
                HStack(spacing: 0) {
                    Color.clear.frame(height: rowHeight)
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor).opacity(0.3))
                        .frame(width: 1)
                }
                .frame(width: colWidth(header))
            }
        }
        .frame(minWidth: gridWidth, alignment: .leading)
        .background(zebraColor(index))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.15)).frame(height: 1)
        }
    }

    // MARK: - Helpers

    private func colWidth(_ header: String) -> CGFloat {
        columnWidths[header] ?? defaultColWidth
    }

    private func totalGridWidth(headers: [String]) -> CGFloat {
        headers.reduce(0) { $0 + colWidth($1) }
    }

    private func zebraColor(_ index: Int) -> Color {
        let colors = NSColor.alternatingContentBackgroundColors
        return Color(nsColor: colors[index % colors.count])
    }
}

// MARK: - Extracted Data Row (Equatable for performance)

private struct DataRowView: View, Equatable {
    let row: Row
    let headers: [String]
    let columnWidths: [String: CGFloat]
    let defaultColWidth: CGFloat
    let rowHeight: CGFloat
    let gridWidth: CGFloat

    static func == (lhs: DataRowView, rhs: DataRowView) -> Bool {
        lhs.row.id == rhs.row.id
            && lhs.columnWidths == rhs.columnWidths
            && lhs.gridWidth == rhs.gridWidth
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(headers, id: \.self) { header in
                let field = row.fields.first(where: { $0.fieldName == header })

                HStack(spacing: 0) {
                    Group {
                        if let field, field.isNull {
                            Text("NULL")
                                .font(.system(size: 11, design: .monospaced))
                                .italic()
                                .foregroundColor(Color(nsColor: .placeholderTextColor))
                        } else if let field {
                            Text(field.value.description)
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                        } else {
                            Text("")
                        }
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                    .frame(height: rowHeight)

                    Rectangle()
                        .fill(Color(nsColor: .separatorColor).opacity(0.3))
                        .frame(width: 1)
                }
                .frame(width: colWidth(header))
            }
        }
        .frame(minWidth: gridWidth, alignment: .leading)
        .background(Color(nsColor: NSColor.alternatingContentBackgroundColors[row.id % NSColor.alternatingContentBackgroundColors.count]))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.15)).frame(height: 1)
        }
    }

    private func colWidth(_ header: String) -> CGFloat {
        columnWidths[header] ?? defaultColWidth
    }
}
