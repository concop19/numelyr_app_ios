import Foundation
import XCTest
import SQLite3
@testable import numelyra_app_ios

final class NumerologyDatabaseCoverageTests: XCTestCase {
    
    private func locateDatabasePath() -> String? {
        // 1. Try bundle resources
        if let bundlePath = Bundle.main.path(forResource: "cadao", ofType: "db") {
            return bundlePath
        }
        if let testBundlePath = Bundle(for: Self.self).path(forResource: "cadao", ofType: "db") {
            return testBundlePath
        }
        
        // 2. Try file system path relative to current source file
        let sourceURL = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceURL
            .deletingLastPathComponent() // numelyra_app_iosTests
            .deletingLastPathComponent() // numelyra_app_ios (nested)
            .deletingLastPathComponent() // numelyra_app_ios
            .deletingLastPathComponent() // repo root
        
        let possiblePaths = [
            repoRoot.appendingPathComponent("numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Resources/cadao.db").path,
            repoRoot.appendingPathComponent("numelyra_app/assets/cadao.db").path
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    private func openDatabase() throws -> OpaquePointer {
        guard let path = locateDatabasePath() else {
            XCTFail("Could not locate cadao.db file in bundle or repository.")
            throw NSError(domain: "DatabaseNotFound", code: 404)
        }
        
        var db: OpaquePointer?
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            let errorMsg = String(cString: sqlite3_errmsg(db))
            XCTFail("Failed to open SQLite database at \(path): \(errorMsg)")
            throw NSError(domain: "SQLiteOpenError", code: 500)
        }
        return db!
    }

    func testDatabaseContainsBothTables() throws {
        let db = try openDatabase()
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = "SELECT name FROM sqlite_master WHERE type='table';"
        XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)

        var tables = Set<String>()
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let nameCStr = sqlite3_column_text(stmt, 0) {
                tables.insert(String(cString: nameCStr))
            }
        }
        sqlite3_finalize(stmt)

        XCTAssertTrue(tables.contains("cadao"), "Database must contain table 'cadao'")
        XCTAssertTrue(tables.contains("numerology_knowledge"), "Database must contain table 'numerology_knowledge'")
    }

    func testTotalNumerologyKnowledgeCountIs212() throws {
        let db = try openDatabase()
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = "SELECT count(*) FROM numerology_knowledge;"
        XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)

        XCTAssertEqual(sqlite3_step(stmt), SQLITE_ROW)
        let count = sqlite3_column_int(stmt, 0)
        sqlite3_finalize(stmt)

        XCTAssertEqual(count, 212, "Table numerology_knowledge must contain exactly 212 rows synced from knowledge base.")
    }

    func testAllTwentyFourIndicatorsArePresentInDatabase() throws {
        let db = try openDatabase()
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = "SELECT DISTINCT indicator_key FROM numerology_knowledge;"
        XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)

        var keysInDB = Set<String>()
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let keyCStr = sqlite3_column_text(stmt, 0) {
                keysInDB.insert(String(cString: keyCStr))
            }
        }
        sqlite3_finalize(stmt)

        for key in NumerologyIndicatorKey.allCases {
            XCTAssertTrue(
                keysInDB.contains(key.rawValue),
                "Indicator key '\(key.rawValue)' must be present in numerology_knowledge table."
            )
        }
        XCTAssertEqual(keysInDB.count, 24, "There must be exactly 24 distinct indicator keys in numerology_knowledge.")
    }

    func testHighCoverageForCoreAndPotentialIndicators() throws {
        let db = try openDatabase()
        defer { sqlite3_close(db) }

        // Core single digits 1...9
        let singleDigits = (1...9).map(String.init)
        
        let coreSingleDigitKeys: [NumerologyIndicatorKey] = [
            .walksOfLife,
            .mission,
            .soul,
            .personality,
            .dateOfBirth,
            .mature,
            .balance,
            .rationalThinking,
            .attitude,
            .yearIndividual,
            .monthIndividual,
            .dayIndividual,
            .passion
        ]

        for key in coreSingleDigitKeys {
            for digit in singleDigits {
                var stmt: OpaquePointer?
                let sql = "SELECT count(*) FROM numerology_knowledge WHERE indicator_key = ? AND number_value = ?;"
                XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)
                sqlite3_bind_text(stmt, 1, (key.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 2, (digit as NSString).utf8String, -1, nil)

                XCTAssertEqual(sqlite3_step(stmt), SQLITE_ROW)
                let count = sqlite3_column_int(stmt, 0)
                sqlite3_finalize(stmt)

                XCTAssertGreaterThan(
                    count, 0,
                    "Expected indicator '\(key.rawValue)' with value '\(digit)' to be covered in database."
                )
            }
        }
    }

    func testBridgesAndKarmicDebtsCoverage() throws {
        let db = try openDatabase()
        defer { sqlite3_close(db) }

        // Bridges: values 0...8
        let bridgeKeys: [NumerologyIndicatorKey] = [
            .bridgeLifeMission,
            .bridgeSoulPersonality,
            .bridgeMaturityPassion
        ]

        for key in bridgeKeys {
            for value in 0...8 {
                var stmt: OpaquePointer?
                let sql = "SELECT count(*) FROM numerology_knowledge WHERE indicator_key = ? AND number_value = ?;"
                XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)
                sqlite3_bind_text(stmt, 1, (key.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 2, (String(value) as NSString).utf8String, -1, nil)

                XCTAssertEqual(sqlite3_step(stmt), SQLITE_ROW)
                let count = sqlite3_column_int(stmt, 0)
                sqlite3_finalize(stmt)

                XCTAssertGreaterThan(
                    count, 0,
                    "Expected bridge indicator '\(key.rawValue)' with value '\(value)' to be covered."
                )
            }
        }

        // Karmic debts: 13/4, 14/5, 16/7, 19/1
        let karmicValues = ["13/4", "14/5", "16/7", "19/1"]
        for debt in karmicValues {
            var stmt: OpaquePointer?
            let sql = "SELECT count(*) FROM numerology_knowledge WHERE indicator_key = 'karmicDebts' AND number_value = ?;"
            XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)
            sqlite3_bind_text(stmt, 1, (debt as NSString).utf8String, -1, nil)

            XCTAssertEqual(sqlite3_step(stmt), SQLITE_ROW)
            let count = sqlite3_column_int(stmt, 0)
            sqlite3_finalize(stmt)

            XCTAssertGreaterThan(count, 0, "Karmic debt '\(debt)' must be covered in database.")
        }
    }

    func testArrowsAndChartsCoverage() throws {
        let db = try openDatabase()
        defer { sqlite3_close(db) }

        let expectedArrows = [
            "1-2-3", "1-4-7", "1-5-9", "2-5-8",
            "3-5-7", "3-6-9", "4-5-6", "7-8-9"
        ]

        for arrow in expectedArrows {
            var stmt: OpaquePointer?
            let sql = "SELECT count(*) FROM numerology_knowledge WHERE indicator_key = 'arrows' AND number_value = ?;"
            XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)
            sqlite3_bind_text(stmt, 1, (arrow as NSString).utf8String, -1, nil)

            XCTAssertEqual(sqlite3_step(stmt), SQLITE_ROW)
            let count = sqlite3_column_int(stmt, 0)
            sqlite3_finalize(stmt)

            XCTAssertGreaterThan(count, 0, "Arrow '\(arrow)' must be covered in database.")
        }

        // Charts: nameChart & birthChart with number_value 'matrix'
        for chartKey in ["nameChart", "birthChart"] {
            var stmt: OpaquePointer?
            let sql = "SELECT count(*) FROM numerology_knowledge WHERE indicator_key = ? AND number_value = 'matrix';"
            XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)
            sqlite3_bind_text(stmt, 1, (chartKey as NSString).utf8String, -1, nil)

            XCTAssertEqual(sqlite3_step(stmt), SQLITE_ROW)
            let count = sqlite3_column_int(stmt, 0)
            sqlite3_finalize(stmt)

            XCTAssertGreaterThan(count, 0, "Chart '\(chartKey)' matrix interpretation must be present.")
        }
    }

    func testCaDaoDatabaseServiceQueries() throws {
        let path = locateDatabasePath()
        XCTAssertNotNil(path)

        let total = CaDaoDatabaseService.getCaDaoCount(customPath: path)
        XCTAssertEqual(total, 16521)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        let sampleDate = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12))!

        let daily1 = CaDaoDatabaseService.getDailyCaDao(for: sampleDate, calendar: calendar, customPath: path)
        let daily2 = CaDaoDatabaseService.getDailyCaDao(for: sampleDate, calendar: calendar, customPath: path)
        XCTAssertEqual(daily1, daily2, "Daily ca dao must be deterministic for the same date.")
        XCTAssertFalse(daily1.content.isEmpty)
        XCTAssertGreaterThan(daily1.id, 0)
    }

    func testNumerologyKnowledgeServiceResolvesAllTwentyFourIndicators() throws {
        let path = locateDatabasePath()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        let refDate = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12))!

        let snapshot = NumerologyEngine.calculate24(
            fullName: "Nguyễn Văn An",
            birthDate: "1998-10-20",
            referenceDate: refDate,
            calendar: calendar
        )

        for indicator in snapshot.indicators {
            let reading = NumerologyKnowledgeService.getIndicatorReading(
                key: indicator.key,
                value: indicator.value,
                cardNameVi: indicator.key.rawValue,
                customDBPath: path
            )
            XCTAssertFalse(reading.title.isEmpty, "Title should not be empty for \(indicator.key.rawValue)")
            XCTAssertFalse(reading.overview.isEmpty, "Overview should not be empty for \(indicator.key.rawValue)")
            XCTAssertFalse(reading.advice.isEmpty, "Advice should not be empty for \(indicator.key.rawValue)")
            XCTAssertNotNil(reading.fullContent)
        }

        // Verify walksOfLife Master 22 maps to 22/4 in SQLite
        let master22Reading = NumerologyKnowledgeService.getIndicatorReading(
            indicatorKey: "walksOfLife",
            indicatorValue: "22",
            cardNameVi: "Số Đường Đời",
            customDBPath: path
        )
        XCTAssertEqual(master22Reading.source, .supabase)
        XCTAssertTrue(master22Reading.title.contains("22/4"))
    }
}
