import Foundation
import SQLite3

enum SQLiteReader {
    static let maxTables = 500
    private static let maxIndexesPerTable = 50
    private static let countDeadline: TimeInterval = 2.0

    static func read(url: URL, fileSize: Int64) -> DocumentLoadResult {
        var connection: OpaquePointer?
        let uri = url.absoluteString + "?mode=ro&immutable=1"
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_URI

        guard sqlite3_open_v2(uri, &connection, flags, nil) == SQLITE_OK,
              let database = connection else {
            let message = connection.map { String(cString: sqlite3_errmsg($0)) }
                ?? "无法打开数据库连接。"
            if let connection {
                sqlite3_close(connection)
            }
            return .failure(PreviewFailure(
                url: url,
                title: "无法读取 SQLite 数据库",
                message: message,
                symbol: "cylinder.split.1x2"
            ))
        }
        defer { sqlite3_close(database) }

        sqlite3_busy_timeout(database, 500)

        guard let objects = readObjects(from: database) else {
            return .failure(PreviewFailure(
                url: url,
                title: "无法解析 SQLite 数据库",
                message: String(cString: sqlite3_errmsg(database)),
                symbol: "cylinder.split.1x2"
            ))
        }

        guard !objects.isEmpty else {
            return .failure(PreviewFailure(
                url: url,
                title: "数据库是空的",
                message: "没有找到用户创建的表或视图。",
                symbol: "cylinder.split.1x2"
            ))
        }

        var warnings: [String] = []
        var nodes: [StructureNode] = []
        var tableCount = 0
        var viewCount = 0
        var columnCount = 0

        if objects.count > maxTables {
            warnings.append("对象较多，仅列出前 \(maxTables) 个。")
        }

        let deadline = CountDeadline(
            deadline: Date().addingTimeInterval(countDeadline)
        )

        for object in objects.prefix(maxTables) {
            let columns = readColumns(
                from: database,
                name: object.name
            )
            columnCount += columns.count

            let isView = object.type == "view"
            if isView {
                viewCount += 1
            } else {
                tableCount += 1
            }

            var rowCount: Int64?
            if !isView, !deadline.expired {
                rowCount = readRowCount(
                    from: database,
                    name: object.name,
                    deadline: deadline
                )
            }

            let detail: String
            if isView {
                detail = "视图 · \(columns.count) 列"
            } else if let rowCount {
                detail = "\(columns.count) 列 · \(rowCount.formatted()) 行"
            } else {
                detail = "\(columns.count) 列 · 行数未知"
            }

            let indexes: [StructureNode]
            if isView || deadline.expired {
                indexes = []
            } else {
                indexes = readIndexes(from: database, table: object.name)
            }

            let tableNode = StructureNode(
                title: object.name,
                detail: detail,
                symbolName: isView ? "eye" : "tablecells",
                children: columns + indexes
            )
            nodes.append(tableNode)
        }

        if deadline.expired {
            warnings.append("行数统计超过 \(Int(countDeadline)) 秒，部分表已跳过。")
        }

        let summaryParts = [
            "\(tableCount) 张表",
            "\(viewCount) 个视图",
            "\(columnCount) 列",
        ].filter { part in
            !part.hasPrefix("0 ")
        }

        return .structure(StructureDocument(
            url: url,
            formatName: "SQLite",
            symbolName: "cylinder.split.1x2",
            byteCount: fileSize,
            summary: summaryParts.joined(separator: " · "),
            nodes: nodes,
            warnings: warnings
        ))
    }

    // MARK: - Schema

    private struct DatabaseObject {
        let name: String
        let type: String
    }

    private static func readObjects(
        from database: OpaquePointer
    ) -> [DatabaseObject]? {
        let sql = """
        SELECT name, type
        FROM sqlite_master
        WHERE type IN ('table', 'view')
          AND name NOT LIKE 'sqlite_%'
        ORDER BY type, name
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            return nil
        }
        defer { sqlite3_finalize(statement) }

        var objects: [DatabaseObject] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let namePointer = sqlite3_column_text(statement, 0),
                  let typePointer = sqlite3_column_text(statement, 1) else {
                continue
            }
            objects.append(DatabaseObject(
                name: String(cString: namePointer),
                type: String(cString: typePointer)
            ))
        }
        return objects
    }

    private static func readColumns(
        from database: OpaquePointer,
        name: String
    ) -> [StructureNode] {
        let sql = "PRAGMA table_info(\(quoteIdentifier(name)))"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var columns: [StructureNode] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let columnName = sqlite3_column_text(statement, 1).map {
                String(cString: $0)
            } ?? "?"
            let declaredType = sqlite3_column_text(statement, 2).map {
                String(cString: $0)
            } ?? ""
            let notNull = sqlite3_column_int(statement, 3) != 0
            let defaultValue = sqlite3_column_text(statement, 4).map {
                String(cString: $0)
            }
            let primaryKey = sqlite3_column_int(statement, 5) != 0

            var flags: [String] = []
            if primaryKey {
                flags.append("PK")
            }
            if notNull {
                flags.append("NOT NULL")
            }
            if let defaultValue, !defaultValue.isEmpty {
                flags.append("= \(truncate(defaultValue, limit: 28))")
            }

            let type = declaredType.isEmpty ? "ANY" : declaredType.uppercased()
            let detail = ([type] + flags).joined(separator: " · ")
            columns.append(StructureNode(
                title: columnName,
                detail: detail,
                symbolName: primaryKey ? "key.fill" : symbolName(for: type)
            ))
        }
        return columns
    }

    private static func readRowCount(
        from database: OpaquePointer,
        name: String,
        deadline: CountDeadline
    ) -> Int64? {
        let sql = "SELECT COUNT(*) FROM \(quoteIdentifier(name))"
        sqlite3_progress_handler(
            database,
            5_000,
            sqliteProgressHandler,
            Unmanaged.passUnretained(deadline).toOpaque()
        )
        defer {
            sqlite3_progress_handler(database, 0, nil, nil)
        }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            return nil
        }
        defer { sqlite3_finalize(statement) }

        let result = sqlite3_step(statement)
        guard result == SQLITE_ROW else {
            if result == SQLITE_INTERRUPT {
                deadline.expired = true
            }
            return nil
        }
        return sqlite3_column_int64(statement, 0)
    }

    private static func readIndexes(
        from database: OpaquePointer,
        table: String
    ) -> [StructureNode] {
        let sql = "PRAGMA index_list(\(quoteIdentifier(table)))"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var indexes: [StructureNode] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let namePointer = sqlite3_column_text(statement, 1) else {
                continue
            }
            let indexName = String(cString: namePointer)
            if indexName.hasPrefix("sqlite_autoindex_") {
                continue
            }
            let isUnique = sqlite3_column_int(statement, 2) != 0
            let isPartial = sqlite3_column_int(statement, 4) != 0
            let columns = readIndexColumns(
                from: database,
                index: indexName
            )

            var flags: [String] = []
            if isUnique {
                flags.append("UNIQUE")
            }
            if isPartial {
                flags.append("PARTIAL")
            }
            let detail = (columns + flags).joined(separator: " · ")
            indexes.append(StructureNode(
                title: indexName,
                detail: detail,
                symbolName: "list.bullet.rectangle"
            ))

            if indexes.count >= maxIndexesPerTable {
                break
            }
        }

        guard !indexes.isEmpty else { return [] }
        return [
            StructureNode(
                title: "索引",
                detail: "\(indexes.count)",
                symbolName: "list.bullet.rectangle",
                children: indexes
            ),
        ]
    }

    private static func readIndexColumns(
        from database: OpaquePointer,
        index: String
    ) -> [String] {
        let sql = "PRAGMA index_info(\(quoteIdentifier(index)))"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var columns: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let namePointer = sqlite3_column_text(statement, 2) {
                columns.append(String(cString: namePointer))
            } else {
                columns.append("表达式")
            }
        }
        return columns
    }

    // MARK: - Helpers

    private final class CountDeadline {
        let deadline: Date
        var expired = false

        init(deadline: Date) {
            self.deadline = deadline
        }
    }

    private static let sqliteProgressHandler: @convention(c) (
        UnsafeMutableRawPointer?
    ) -> Int32 = { context in
        guard let context else { return 0 }
        let deadline = Unmanaged<CountDeadline>
            .fromOpaque(context)
            .takeUnretainedValue()
        if Date() > deadline.deadline {
            deadline.expired = true
            return 1
        }
        return 0
    }

    private static func quoteIdentifier(_ name: String) -> String {
        "\"\(name.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static func truncate(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit)) + "…"
    }

    private static func symbolName(for type: String) -> String {
        if type.contains("INT") {
            return "number"
        }
        if type.contains("REAL") || type.contains("FLOA")
            || type.contains("DOUB") || type.contains("NUM")
            || type.contains("DEC") {
            return "number.circle"
        }
        if type.contains("BLOB") {
            return "shippingbox"
        }
        return "textformat"
    }
}
