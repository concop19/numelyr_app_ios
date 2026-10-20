import Foundation
import SQLite3

public nonisolated enum NumerologyRepresentativeService {
    public static func representative(
        matching triple: RepresentativeTriple,
        customDBPath: String? = nil
    ) throws -> NumerologyRepresentative? {
        guard let db = CaDaoDatabaseService.openDatabase(customPath: customDBPath) else {
            throw RepresentativeLookupError.databaseUnavailable
        }
        defer { sqlite3_close(db) }

        let lifePath = normalize(triple.lifePath)
        let expression = normalize(triple.expression)
        let soulUrge = normalize(triple.soulUrge)

        if let exact = try query(
            db,
            sql: Self.selectColumns + " WHERE life_path = ? AND expression = ? AND soul_urge = ? LIMIT 1;",
            values: [lifePath, expression, soulUrge],
            matchType: .exactThree
        ) {
            return exact
        }
        if let core = try query(
            db,
            sql: Self.selectColumns + " WHERE life_path = ? AND expression = ? ORDER BY sitelinks DESC LIMIT 1;",
            values: [lifePath, expression],
            matchType: .coreTwo
        ) {
            return core
        }
        return try query(
            db,
            sql: Self.selectColumns + " WHERE life_path = ? ORDER BY sitelinks DESC LIMIT 1;",
            values: [lifePath],
            matchType: .lifePathOne
        )
    }

    public static func count(customDBPath: String? = nil) throws -> Int {
        guard let db = CaDaoDatabaseService.openDatabase(customPath: customDBPath) else {
            throw RepresentativeLookupError.databaseUnavailable
        }
        defer { sqlite3_close(db) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM representatives;", -1, &statement, nil) == SQLITE_OK else {
            throw queryError(db)
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else { throw queryError(db) }
        return Int(sqlite3_column_int(statement, 0))
    }

    private static let selectColumns = """
    SELECT id, life_path, expression, soul_urge, name_used, display_name, display_name_vi,
           birth_date, death_date, description, wikidata_url, wikipedia_url, sitelinks,
           image_url, biography, biography_vi, biography_en
    FROM representatives
    """

    private static func query(
        _ db: OpaquePointer,
        sql: String,
        values: [Int],
        matchType: RepresentativeMatchType
    ) throws -> NumerologyRepresentative? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw queryError(db)
        }
        defer { sqlite3_finalize(statement) }

        for (offset, value) in values.enumerated() {
            sqlite3_bind_int(statement, Int32(offset + 1), Int32(value))
        }

        let result = sqlite3_step(statement)
        if result == SQLITE_DONE { return nil }
        guard result == SQLITE_ROW else { throw queryError(db) }

        return NumerologyRepresentative(
            id: Int(sqlite3_column_int(statement, 0)),
            lifePath: Int(sqlite3_column_int(statement, 1)),
            expression: Int(sqlite3_column_int(statement, 2)),
            soulUrge: Int(sqlite3_column_int(statement, 3)),
            nameUsed: text(statement, 4) ?? "",
            displayName: text(statement, 5) ?? "",
            displayNameVi: text(statement, 6),
            birthDate: text(statement, 7) ?? "",
            deathDate: text(statement, 8),
            description: text(statement, 9),
            wikidataURL: text(statement, 10) ?? "",
            wikipediaURL: text(statement, 11),
            sitelinks: Int(sqlite3_column_int(statement, 12)),
            imageURL: text(statement, 13),
            biography: text(statement, 14),
            biographyVi: text(statement, 15),
            biographyEn: text(statement, 16),
            matchType: matchType
        )
    }

    private static func normalize(_ value: Int) -> Int {
        value == 10 ? 1 : value
    }

    private static func text(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL,
              let value = sqlite3_column_text(statement, index)
        else { return nil }
        return String(cString: value)
    }

    private static func queryError(_ db: OpaquePointer) -> RepresentativeLookupError {
        .queryFailed(String(cString: sqlite3_errmsg(db)))
    }
}
