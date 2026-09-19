import Foundation
import UserNotifications

@MainActor
final class UpkeepStore: ObservableObject {
    @Published private(set) var state = UpkeepState()
    @Published var errorMessage: String?

    private let fileManager: FileManager
    private let stateURL: URL
    private let encoder: JSONEncoder
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default, supportURL: URL? = nil) {
        self.fileManager = fileManager
        let support = supportURL ?? (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory
        stateURL = support.appendingPathComponent("upkeep-log.json")
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    var homes: [HomeProfile] { state.homes }
    var rooms: [RoomRecord] { state.rooms }
    var assets: [AssetRecord] { state.assets }
    var tasks: [TaskRecord] { state.tasks }
    var completions: [CompletionRecord] { state.completions }

    func addHome(name: String, address: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        state.homes.append(HomeProfile(name: name.trimmed, address: address.trimmed))
        save()
    }

    func addRoom(homeID: UUID, name: String) {
        guard !name.trimmed.isEmpty else { return }
        state.rooms.append(RoomRecord(homeID: homeID, name: name.trimmed))
        save()
    }

    func addAsset(homeID: UUID, roomID: UUID?, name: String) {
        guard !name.trimmed.isEmpty else { return }
        state.assets.append(AssetRecord(homeID: homeID, roomID: roomID, name: name.trimmed))
        save()
    }

    func addTask(_ task: TaskRecord) {
        guard !task.name.trimmed.isEmpty else { return }
        var task = task
        task.name = task.name.trimmed
        task.interval = max(1, task.interval)
        state.tasks.append(task)
        save()
        Task { await rebuildReminders() }
    }

    func setTaskPaused(_ taskID: UUID, paused: Bool) {
        guard let index = state.tasks.firstIndex(where: { $0.id == taskID }) else { return }
        state.tasks[index].isPaused = paused
        save()
        Task { await rebuildReminders() }
    }

    func complete(
        _ occurrence: ScheduledOccurrence,
        actualDay: LocalDay,
        notes: String,
        parts: String,
        costText: String,
        currency: String
    ) {
        let revision = CompletionRevision(
            actualDay: actualDay,
            notes: notes.trimmed,
            parts: parts.trimmed,
            costMinorUnits: Self.minorUnits(from: costText),
            currency: currency.uppercased()
        )
        state.completions.append(CompletionRecord(
            taskID: occurrence.task.id,
            scheduledDay: occurrence.scheduledDay,
            revisions: [revision]
        ))
        state.snoozes.removeValue(forKey: occurrence.id)
        save()
        Task { await rebuildReminders() }
    }

    func revise(
        _ completionID: UUID,
        actualDay: LocalDay,
        notes: String,
        parts: String,
        costText: String,
        currency: String
    ) {
        guard let index = state.completions.firstIndex(where: { $0.id == completionID }) else { return }
        state.completions[index].revisions.append(CompletionRevision(
            actualDay: actualDay,
            notes: notes.trimmed,
            parts: parts.trimmed,
            costMinorUnits: Self.minorUnits(from: costText),
            currency: currency.uppercased()
        ))
        save()
    }

    func snooze(_ occurrence: ScheduledOccurrence, until day: LocalDay) {
        guard day >= occurrence.scheduledDay else { return }
        state.snoozes[occurrence.id] = day
        save()
        Task { await rebuildReminders() }
    }

    func deleteAllData() {
        state = UpkeepState()
        save()
        Task {
            let center = UNUserNotificationCenter.current()
            let upkeepIDs = await center.pendingNotificationRequests()
                .map(\.identifier)
                .filter { $0.hasPrefix("upkeep.") }
            center.removePendingNotificationRequests(withIdentifiers: upkeepIDs)
        }
    }

    func occurrences(from: LocalDay, through: LocalDay) -> [ScheduledOccurrence] {
        let completedKeys = Set(state.completions.map {
            "\($0.taskID.uuidString)-\($0.scheduledDay.rawValue)"
        })
        return state.tasks
            .filter { !$0.isPaused }
            .flatMap { task in
                let snoozedScheduledDays = state.snoozes.compactMap { key, visibleDay -> LocalDay? in
                    guard
                        key.hasPrefix("\(task.id.uuidString)-"),
                        visibleDay >= from,
                        visibleDay <= through
                    else { return nil }
                    return LocalDay(String(key.suffix(10)))
                }
                let lowerBound = min(snoozedScheduledDays.min() ?? from, from)
                return scheduledDays(
                    for: task,
                    startingAt: lowerBound,
                    through: through
                ).compactMap { day -> ScheduledOccurrence? in
                let key = "\(task.id.uuidString)-\(day.rawValue)"
                guard !completedKeys.contains(key) else { return nil }
                let visible = state.snoozes[key] ?? day
                guard visible >= from && visible <= through else { return nil }
                return ScheduledOccurrence(task: task, scheduledDay: day, visibleDay: visible)
            }}
            .sorted {
                if $0.visibleDay != $1.visibleDay { return $0.visibleDay < $1.visibleDay }
                return $0.task.name.localizedCaseInsensitiveCompare($1.task.name) == .orderedAscending
            }
    }

    func taskName(for taskID: UUID) -> String {
        state.tasks.first(where: { $0.id == taskID })?.name ?? "Removed task"
    }

    func exportURL() throws -> URL {
        let data = try encoder.encode(state)
        let url = fileManager.temporaryDirectory
            .appendingPathComponent("upkeep-log-\(LocalDay.today.rawValue).json")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    func importData(from url: URL) throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true, (values.fileSize ?? 0) <= 16 * 1024 * 1024 else {
            throw CocoaError(.fileReadTooLarge)
        }
        let imported = try decoder.decode(UpkeepState.self, from: Data(contentsOf: url))
        guard imported.tasks.allSatisfy({ $0.interval > 0 }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        state = imported
        save()
        Task { await rebuildReminders() }
    }

    func requestReminderPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            await rebuildReminders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scheduledDays(
        for task: TaskRecord,
        startingAt lowerBound: LocalDay,
        through end: LocalDay
    ) -> [LocalDay] {
        var result: [LocalDay] = []
        let maxOccurrences = 4_000
        let interval = max(1, task.interval)
        var occurrenceIndex = 0
        var generatedCount = 0
        if task.recurrence == .days || task.recurrence == .weeks {
            let stride = interval * (task.recurrence == .weeks ? 7 : 1)
            let elapsed = max(0, Calendar(identifier: .gregorian).dateComponents(
                [.day],
                from: task.startDay.date,
                to: lowerBound.date
            ).day ?? 0)
            occurrenceIndex = (elapsed + stride - 1) / stride
        }
        var day = task.startDay
        while day <= end, generatedCount < maxOccurrences {
            switch task.recurrence {
            case .oneTime:
                day = task.startDay
            case .days:
                day = task.startDay.adding(.day, value: interval * occurrenceIndex)
            case .weeks:
                day = task.startDay.adding(.day, value: interval * 7 * occurrenceIndex)
            case .months:
                day = task.startDay.addingMonths(interval * occurrenceIndex)
            case .years:
                day = task.startDay.addingMonths(interval * 12 * occurrenceIndex)
            }
            guard day <= end else { break }
            if day >= lowerBound { result.append(day) }
            generatedCount += 1
            switch task.recurrence {
            case .oneTime:
                return result
            default:
                occurrenceIndex += 1
            }
        }
        return result
    }

    static func minorUnits(from text: String, locale: Locale = .current) -> Int? {
        guard let value = Decimal(string: text, locale: locale) else { return nil }
        var scaled = value * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }

    private func load() {
        guard fileManager.fileExists(atPath: stateURL.path) else { return }
        do {
            state = try decoder.decode(UpkeepState.self, from: Data(contentsOf: stateURL))
        } catch {
            errorMessage = "Your local data could not be opened: \(error.localizedDescription)"
        }
    }

    private func save() {
        do {
            try encoder.encode(state).write(
                to: stateURL,
                options: [.atomic, .completeFileProtection]
            )
        } catch {
            errorMessage = "Your changes could not be saved: \(error.localizedDescription)"
        }
    }

    private func rebuildReminders() async {
        let center = UNUserNotificationCenter.current()
        let existing = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: existing.map(\.identifier).filter { $0.hasPrefix("upkeep.") }
        )
        let end = LocalDay.today.adding(.year, value: 1)
        let reminders = occurrences(from: LocalDay.today, through: end)
            .filter { $0.task.reminderHour != nil && $0.task.reminderMinute != nil }
            .prefix(60)
        for occurrence in reminders {
            guard let hour = occurrence.task.reminderHour,
                  let minute = occurrence.task.reminderMinute else { continue }
            var components = occurrence.visibleDay.dateComponents
            components.calendar = Calendar.current
            components.timeZone = .current
            components.hour = hour
            components.minute = minute
            let content = UNMutableNotificationContent()
            content.title = occurrence.task.name
            content.body = "Upkeep is due. Open Upkeep Log for current status."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "upkeep.\(occurrence.id)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            try? await center.add(request)
        }
    }
}
