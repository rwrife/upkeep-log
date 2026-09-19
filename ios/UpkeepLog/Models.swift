import Foundation

struct LocalDay: Codable, Hashable, Comparable, Identifiable, CustomStringConvertible {
    let rawValue: String

    var id: String { rawValue }
    var description: String { rawValue }

    init(_ rawValue: String) {
        precondition(Self.isValid(rawValue), "LocalDay requires a valid yyyy-MM-dd value")
        self.rawValue = rawValue
    }

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        rawValue = String(
            format: "%04d-%02d-%02d",
            components.year ?? 1970,
            components.month ?? 1,
            components.day ?? 1
        )
    }

    static var today: LocalDay { LocalDay(date: Date()) }

    static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        guard Self.isValid(value) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Expected a valid yyyy-MM-dd date"
            ))
        }
        rawValue = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var date: Date {
        Self.formatter.date(from: rawValue) ?? Date(timeIntervalSince1970: 0)
    }

    var dateComponents: DateComponents {
        let values = rawValue.split(separator: "-").compactMap { Int($0) }
        guard values.count == 3 else { return DateComponents() }
        return DateComponents(year: values[0], month: values[1], day: values[2])
    }

    func adding(_ component: Calendar.Component, value: Int) -> LocalDay {
        LocalDay(date: Self.utcCalendar.date(
            byAdding: component,
            value: value,
            to: date
        ) ?? date, calendar: Self.utcCalendar)
    }

    func addingMonths(_ value: Int) -> LocalDay {
        let source = Self.utcCalendar.dateComponents([.year, .month, .day], from: date)
        guard
            let firstOfMonth = Self.utcCalendar.date(from: DateComponents(
                year: source.year,
                month: source.month,
                day: 1
            )),
            let targetMonth = Self.utcCalendar.date(byAdding: .month, value: value, to: firstOfMonth),
            let dayRange = Self.utcCalendar.range(of: .day, in: .month, for: targetMonth)
        else { return self }
        var target = Self.utcCalendar.dateComponents([.year, .month], from: targetMonth)
        target.day = min(source.day ?? 1, dayRange.count)
        return LocalDay(
            date: Self.utcCalendar.date(from: target) ?? targetMonth,
            calendar: Self.utcCalendar
        )
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }()

    private static func isValid(_ value: String) -> Bool {
        guard value.count == 10, let date = formatter.date(from: value) else { return false }
        return formatter.string(from: date) == value
    }

    private static var utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
}

struct HomeProfile: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var address: String
}

struct RoomRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var homeID: UUID
    var name: String
}

struct AssetRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var homeID: UUID
    var roomID: UUID?
    var name: String
}

enum RecurrenceKind: String, Codable, CaseIterable, Identifiable {
    case oneTime
    case days
    case weeks
    case months
    case years

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneTime: "One time"
        case .days: "Days"
        case .weeks: "Weeks"
        case .months: "Months"
        case .years: "Years"
        }
    }
}

struct TaskRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var homeID: UUID
    var roomID: UUID?
    var assetID: UUID?
    var name: String
    var startDay: LocalDay
    var recurrence: RecurrenceKind
    var interval: Int
    var reminderHour: Int?
    var reminderMinute: Int?
    var isPaused = false

    init(
        id: UUID = UUID(),
        homeID: UUID,
        roomID: UUID? = nil,
        assetID: UUID? = nil,
        name: String,
        startDay: LocalDay,
        recurrence: RecurrenceKind,
        interval: Int,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil,
        isPaused: Bool = false
    ) {
        self.id = id
        self.homeID = homeID
        self.roomID = roomID
        self.assetID = assetID
        self.name = name
        self.startDay = startDay
        self.recurrence = recurrence
        self.interval = interval
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.isPaused = isPaused
    }
}

struct CompletionRevision: Codable, Identifiable, Hashable {
    var id = UUID()
    var revisedAt = Date()
    var actualDay: LocalDay
    var notes: String
    var parts: String
    var costMinorUnits: Int?
    var currency: String
}

struct CompletionRecord: Codable, Identifiable, Hashable {
    var id = UUID()
    var taskID: UUID
    var scheduledDay: LocalDay
    var revisions: [CompletionRevision]

    var latest: CompletionRevision {
        revisions.last ?? CompletionRevision(actualDay: scheduledDay, notes: "", parts: "", currency: "USD")
    }
}

struct ScheduledOccurrence: Identifiable, Hashable {
    let task: TaskRecord
    let scheduledDay: LocalDay
    let visibleDay: LocalDay

    var id: String { "\(task.id.uuidString)-\(scheduledDay.rawValue)" }
}

struct UpkeepState: Codable {
    var homes: [HomeProfile] = []
    var rooms: [RoomRecord] = []
    var assets: [AssetRecord] = []
    var tasks: [TaskRecord] = []
    var completions: [CompletionRecord] = []
    var snoozes: [String: LocalDay] = [:]
}
