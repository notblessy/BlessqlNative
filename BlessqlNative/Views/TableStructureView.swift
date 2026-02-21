import SwiftUI

struct TableStructureView: View {
    @ObservedObject var db: DatabaseManager

    @State private var columnWidths: [String: CGFloat] = [:]

    private let headers = ["Name", "Type", "Default", "Nullable", "Key", "Comment"]
    private let defaultWidths: [String: CGFloat] = [
        "Name": 180, "Type": 140, "Default": 160,
        "Nullable": 70, "Key": 60, "Comment": 200
    ]
    private let rowHeight: CGFloat = 28

    var body: some View {
        VStack(spacing: 0) {
            if db.isLoadingStructure {
                Spacer()
                ProgressView()
                    .controlSize(.small)
                Spacer()
            } else if db.structureData.isEmpty {
                Spacer()
                Text("No columns found")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                structureGrid
            }
        }
        .onChange(of: db.selectedTable) { _ in
            columnWidths = [:]
        }
    }

    // MARK: - Grid

    private var structureGrid: some View {
        GeometryReader { geo in
            let gridWidth = max(totalGridWidth(), geo.size.width)
            let availableHeight = geo.size.height - 28
            let visibleRowCount = max(Int(ceil(availableHeight / rowHeight)), 1)

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    headerRow(gridWidth: gridWidth)
                        .fixedSize(horizontal: false, vertical: true)

                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(db.structureData.enumerated()), id: \.element.id) { idx, col in
                                StructureRowView(
                                    col: col,
                                    index: idx,
                                    headers: headers,
                                    columnWidths: columnWidths,
                                    defaultWidths: defaultWidths,
                                    rowHeight: rowHeight,
                                    gridWidth: gridWidth
                                )
                            }
                            let emptyCount = max(visibleRowCount - db.structureData.count, 0)
                            if emptyCount > 0 {
                                ForEach(0..<emptyCount, id: \.self) { idx in
                                    emptyRow(index: db.structureData.count + idx, gridWidth: gridWidth)
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

    private func headerRow(gridWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(headers, id: \.self) { header in
                HStack(spacing: 0) {
                    Text(header)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
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

    private func emptyRow(index: Int, gridWidth: CGFloat) -> some View {
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
        columnWidths[header] ?? defaultWidths[header] ?? 150
    }

    private func totalGridWidth() -> CGFloat {
        headers.reduce(0) { $0 + colWidth($1) }
    }

    private func zebraColor(_ index: Int) -> Color {
        let colors = NSColor.alternatingContentBackgroundColors
        return Color(nsColor: colors[index % colors.count])
    }
}

// MARK: - Extracted Structure Row

private struct StructureRowView: View, Equatable {
    let col: ColumnDefinition
    let index: Int
    let headers: [String]
    let columnWidths: [String: CGFloat]
    let defaultWidths: [String: CGFloat]
    let rowHeight: CGFloat
    let gridWidth: CGFloat

    static func == (lhs: StructureRowView, rhs: StructureRowView) -> Bool {
        lhs.col.id == rhs.col.id
            && lhs.columnWidths == rhs.columnWidths
            && lhs.gridWidth == rhs.gridWidth
    }

    var body: some View {
        HStack(spacing: 0) {
            // Name
            cell(header: "Name") {
                Text(col.name)
                    .font(.system(size: 11, weight: col.isPrimaryKey ? .semibold : .regular))
                    .foregroundColor(.primary)
            }

            // Type
            cell(header: "Type") {
                Text(col.displayType)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.primary)
            }

            // Default
            cell(header: "Default") {
                if let def = col.columnDefault {
                    Text(def)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.primary)
                } else {
                    Text("--")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Nullable
            cell(header: "Nullable") {
                Image(systemName: col.isNullable ? "checkmark" : "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(col.isNullable ? .green : .red)
            }

            // Key
            cell(header: "Key") {
                Text(col.keyDisplay)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(col.isPrimaryKey ? .orange : .blue)
            }

            // Comment
            cell(header: "Comment") {
                Text(col.comment ?? "")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: gridWidth, alignment: .leading)
        .background(zebraColor(index))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(nsColor: .separatorColor).opacity(0.15)).frame(height: 1)
        }
    }

    @ViewBuilder
    private func cell<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 0) {
            content()
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

    private func colWidth(_ header: String) -> CGFloat {
        columnWidths[header] ?? defaultWidths[header] ?? 150
    }

    private func zebraColor(_ index: Int) -> Color {
        let colors = NSColor.alternatingContentBackgroundColors
        return Color(nsColor: colors[index % colors.count])
    }
}
