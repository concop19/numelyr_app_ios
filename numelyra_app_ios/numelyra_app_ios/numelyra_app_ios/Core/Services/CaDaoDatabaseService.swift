import Foundation
import SQLite3

/// Dịch vụ truy vấn cơ sở dữ liệu SQLite `cadao.db` cho tính năng Ca dao Tục ngữ (Blốc Lịch)
/// và dùng chung helper định vị file SQLite trong Bundle.
/// Tương ứng với `src/db/cadaoService.ts` trong dự án React Native.
public nonisolated enum CaDaoDatabaseService {

    /// Định vị đường dẫn file `cadao.db` trong Bundle hoặc trong cây thư mục dự án (khi chạy test/CLI).
    public static func locateDatabasePath(customPath: String? = nil) -> String? {
        if let customPath, FileManager.default.fileExists(atPath: customPath) {
            return customPath
        }
        if let bundlePath = Bundle.main.path(forResource: "cadao", ofType: "db") {
            return bundlePath
        }

        // Fallback cho môi trường test / CLI
        let sourceURL = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceURL
            .deletingLastPathComponent() // Services
            .deletingLastPathComponent() // Core
            .deletingLastPathComponent() // numelyra_app_ios (inner)
            .deletingLastPathComponent() // numelyra_app_ios (outer)
            .deletingLastPathComponent() // numelyra_app_ios root
            .deletingLastPathComponent() // workspace root

        let candidates = [
            sourceURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/cadao.db")
                .path,
            repoRoot
                .appendingPathComponent("numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Resources/cadao.db")
                .path,
            repoRoot
                .appendingPathComponent("numelyra_app/assets/cadao.db")
                .path
        ]

        for path in candidates where FileManager.default.fileExists(atPath: path) {
            return path
        }
        return nil
    }

    /// Mở kết nối SQLite ở chế độ chỉ đọc (`SQLITE_OPEN_READONLY`).
    public static func openDatabase(customPath: String? = nil) -> OpaquePointer? {
        guard let path = locateDatabasePath(customPath: customPath) else {
            return nil
        }
        var db: OpaquePointer?
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK {
            return db
        }
        if let db {
            sqlite3_close(db)
        }
        return nil
    }

    // MARK: - Ca Dao Queries

    public static let emptyDBFallback = CaDaoRecord(
        id: 0,
        title: "",
        content: "Tốt gỗ hơn tốt nước sơn",
        category: "Ca dao dân gian",
        url: ""
    )

    public static let missingRowFallback = CaDaoRecord(
        id: 0,
        title: "",
        content: "Đi một ngày đàng, học một sàng khôn",
        category: "Ca dao dân gian",
        url: ""
    )

    public static let errorFallback = CaDaoRecord(
        id: 0,
        title: "",
        content: "Uống nước nhớ nguồn",
        category: "Ca dao dân gian",
        url: ""
    )

    /// Lấy tổng số bài ca dao trong bảng `cadao`.
    public static func getCaDaoCount(customPath: String? = nil) -> Int {
        guard let db = openDatabase(customPath: customPath) else {
            return 0
        }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = "SELECT COUNT(*) FROM cadao;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return 0
        }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return 0
    }

    /// Lấy 1 câu ca dao theo ngày — seed cố định theo ngày để cùng một ngày luôn trả về cùng câu.
    /// Công thức seed khớp 100% với `cadaoService.ts`: `(day * 31 + month * 37 + year * 7) % total`.
    public static func getDailyCaDao(
        for date: Date,
        calendar: Calendar = LunarService.defaultCalendar,
        customPath: String? = nil
    ) -> CaDaoRecord {
        guard let db = openDatabase(customPath: customPath) else {
            return errorFallback
        }
        defer { sqlite3_close(db) }

        let total = getCaDaoCount(customPath: customPath)
        guard total > 0 else {
            return emptyDBFallback
        }

        let components = calendar.dateComponents([.day, .month, .year], from: date)
        let day = components.day ?? 1
        let month = components.month ?? 1
        let year = components.year ?? 2026

        let seed = day * 31 + month * 37 + year * 7
        let targetOffset = abs(seed) % total

        var stmt: OpaquePointer?
        let sql = "SELECT id, title, content, category, url FROM cadao ORDER BY id LIMIT 1 OFFSET ?;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return errorFallback
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(targetOffset))

        if sqlite3_step(stmt) == SQLITE_ROW {
            return readCaDaoRow(stmt)
        }
        return missingRowFallback
    }

    /// Lấy 1 câu ca dao ngẫu nhiên.
    public static func getRandomCaDao(customPath: String? = nil) -> CaDaoRecord? {
        guard let db = openDatabase(customPath: customPath) else {
            return nil
        }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = "SELECT id, title, content, category, url FROM cadao ORDER BY RANDOM() LIMIT 1;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            return readCaDaoRow(stmt)
        }
        return nil
    }

    /// Tìm các câu ca dao theo danh mục (`category`).
    public static func getCaDaoByCategory(
        _ category: String,
        limit: Int = 10,
        customPath: String? = nil
    ) -> [CaDaoRecord] {
        guard let db = openDatabase(customPath: customPath) else {
            return []
        }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = "SELECT id, title, content, category, url FROM cadao WHERE category LIKE ? ORDER BY RANDOM() LIMIT ?;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(stmt) }

        let pattern = "%\(category)%"
        sqlite3_bind_text(stmt, 1, (pattern as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 2, Int32(max(1, limit)))

        var results: [CaDaoRecord] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            results.append(readCaDaoRow(stmt))
        }
        return results
    }

    private static func readCaDaoRow(_ stmt: OpaquePointer?) -> CaDaoRecord {
        let id = Int(sqlite3_column_int(stmt, 0))
        let title = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
        let content = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? ""
        let category = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
        let url = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? ""
        return CaDaoRecord(id: id, title: title, content: content, category: category, url: url)
    }
}
