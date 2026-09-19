import XCTest
@testable import UpkeepLog

final class UpkeepLogTests: XCTestCase {
    func testLocalDayComparisonAndDayAddition() {
        let leapDay = LocalDay("2024-02-29")

        XCTAssertEqual(leapDay.adding(.day, value: 1), LocalDay("2024-03-01"))
        XCTAssertLessThan(LocalDay("2024-02-28"), leapDay)
    }

    func testMonthAdditionClampsWithoutPermanentDrift() {
        let start = LocalDay("2024-01-31")

        XCTAssertEqual(start.addingMonths(1), LocalDay("2024-02-29"))
        XCTAssertEqual(start.addingMonths(2), LocalDay("2024-03-31"))
        XCTAssertEqual(LocalDay("2024-02-29").addingMonths(12), LocalDay("2025-02-28"))
    }

    func testMalformedLocalDayIsRejectedDuringRestore() {
        XCTAssertThrowsError(
            try JSONDecoder().decode(LocalDay.self, from: Data(#""2024-02-31""#.utf8))
        )
    }

    @MainActor
    func testOneTimeTaskCreatesOneOccurrence() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let store = UpkeepStore(supportURL: root)
        store.addHome(name: "Home", address: "")
        let home = try XCTUnwrap(store.homes.first)
        store.addTask(TaskRecord(
            homeID: home.id,
            name: "Inspect roof",
            startDay: LocalDay("2026-01-15"),
            recurrence: .oneTime,
            interval: 1
        ))

        XCTAssertEqual(
            store.occurrences(
                from: LocalDay("2026-01-01"),
                through: LocalDay("2027-01-01")
            ).map(\.scheduledDay),
            [LocalDay("2026-01-15")]
        )
    }
}
