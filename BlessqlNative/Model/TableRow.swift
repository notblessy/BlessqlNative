import Foundation

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

extension AnyCodable: CustomStringConvertible {
    var description: String {
        if let intValue = value as? Int {
            return "\(intValue)"
        } else if let doubleValue = value as? Double {
            return "\(doubleValue)"
        } else if let stringValue = value as? String {
            return stringValue
        } else if let boolValue = value as? Bool {
            return "\(boolValue)"
        } else {
            return "Unsupported Type"
        }
    }
}

struct FieldSchema {
    var fieldName: String
    var fieldType: String
    var fieldIndex: Int

    func HasIndex(_ index: Int) -> Bool {
        return fieldIndex == index
    }
}

struct Field: Identifiable, Codable, Hashable {
    var id: Int
    var fieldName: String
    var value: AnyCodable
    var type: String
    var isNull: Bool

    init(id: Int, fieldName: String, value: Any, type: String, isNull: Bool = false) {
        self.id = id
        self.fieldName = fieldName
        self.value = AnyCodable(value)
        self.type = type
        self.isNull = isNull
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        fieldName = try container.decode(String.self, forKey: .fieldName)
        value = try container.decode(AnyCodable.self, forKey: .value)
        type = try container.decode(String.self, forKey: .type)
        isNull = (try? container.decode(Bool.self, forKey: .isNull)) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fieldName, forKey: .fieldName)
        try container.encode(value, forKey: .value)
        try container.encode(type, forKey: .type)
        try container.encode(isNull, forKey: .isNull)
    }

    private enum CodingKeys: String, CodingKey {
        case id, fieldName, value, type, isNull
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(fieldName)
        hasher.combine(type)
    }

    static func == (lhs: Field, rhs: Field) -> Bool {
        lhs.id == rhs.id && lhs.fieldName == rhs.fieldName && lhs.type == rhs.type
    }
}

struct Row: Identifiable, Codable {
    var id: Int
    var fields: [Field]
}

struct TableRow: Codable {
    var name: String
    var rows: [Row]
    var headers: [String]
    var totalCount: Int
    var currentPage: Int
    var pageSize: Int
    var isEstimatedCount: Bool

    init() {
        self.name = ""
        self.rows = []
        self.headers = []
        self.totalCount = 0
        self.currentPage = 0
        self.pageSize = 200
        self.isEstimatedCount = false
    }

    init(name: String, rows: [Row] = [], headers: [String] = [], totalCount: Int = 0, currentPage: Int = 0, pageSize: Int = 200, isEstimatedCount: Bool = false) {
        self.name = name
        self.rows = rows
        self.headers = headers
        self.totalCount = totalCount
        self.currentPage = currentPage
        self.pageSize = pageSize
        self.isEstimatedCount = isEstimatedCount
    }

    var totalPages: Int {
        guard pageSize > 0 else { return 0 }
        return max(1, Int(ceil(Double(totalCount) / Double(pageSize))))
    }

    var rangeStart: Int {
        currentPage * pageSize + 1
    }

    var rangeEnd: Int {
        min(rangeStart + rows.count - 1, totalCount)
    }
}

struct SchemaItem: Identifiable {
    let id = UUID()
    let name: String
    var tables: [String]
    var isExpanded: Bool = false
}

// MARK: - Detail Tab

enum DetailTab: String, CaseIterable, Identifiable {
    case data = "Data"
    case structure = "Structure"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .data: return "tablecells"
        case .structure: return "list.bullet.rectangle"
        }
    }
}

// MARK: - Column Definition (Structure tab)

struct ColumnDefinition: Identifiable {
    let id: Int
    let name: String
    let dataType: String
    let characterMaxLength: Int?
    let numericPrecision: Int?
    let columnDefault: String?
    let isNullable: Bool
    let isPrimaryKey: Bool
    let isForeignKey: Bool
    let foreignKeyRef: String?
    let comment: String?

    var displayType: String {
        if let maxLen = characterMaxLength {
            return "\(dataType)(\(maxLen))"
        }
        if let precision = numericPrecision {
            return "\(dataType)(\(precision))"
        }
        return dataType
    }

    var keyDisplay: String {
        var parts: [String] = []
        if isPrimaryKey { parts.append("PK") }
        if isForeignKey { parts.append("FK") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Query Result (Query tab)

struct QueryResult: Equatable {
    var columns: [String]
    var rows: [[String]]
    var affectedRows: Int
    var executionTime: TimeInterval
    var error: String?

    static let empty = QueryResult(columns: [], rows: [], affectedRows: 0, executionTime: 0, error: nil)

    var statusMessage: String {
        if let error = error {
            return "Error: \(error)"
        }
        if columns.isEmpty && affectedRows > 0 {
            return "Query OK, \(affectedRows) row(s) affected (\(String(format: "%.3f", executionTime))s)"
        }
        if !columns.isEmpty {
            return "\(rows.count) row(s) returned (\(String(format: "%.3f", executionTime))s)"
        }
        return "Query executed (\(String(format: "%.3f", executionTime))s)"
    }
}

struct QueryHistoryItem: Identifiable {
    let id = UUID()
    let sql: String
    let timestamp: Date
    let success: Bool
}
