import XCTest
@testable import UpkeepLog

final class UpkeepLogTests: XCTestCase {
    func testLocalDayComparisonAndDayAddition() {
        let leapDay = LocalDay("2024-02-29")

        XCTAssertEqual(leapDay.adding(.day, value: 1), LocalDay("2024-03-01"))
        XCTAssertLessThan(LocalDay("2024-02-28"), leapDay)
    }

    @MainActor
    func testOneTimeTaskCreatesOneOccurrence() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let manager = TestFileManager(root: root)
        let store = UpkeepStore(fileManager: manager)
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

private final class TestFileManager: FileManager {
    private let root: URL

    init(root: URL) {
        self.root = root
        super.init()
    }

    override func url(
        for directory: SearchPathDirectory,
        in domain: SearchPathDomainMask,
        appropriateFor url: URL?,
        create shouldCreate: Bool
    ) throws -> URL {
        root
    }
}
