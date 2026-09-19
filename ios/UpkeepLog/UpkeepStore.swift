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

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let support = (try? fileManager.url(
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
        let amount = Decimal(string: costText)
        let minorUnits = amount.map {
            NSDecimalNumber(decimal: $0 * 100).intValue
        }
        let revision = CompletionRevision(
            actualDay: actualDay,
            notes: notes.trimmed,
            parts: parts.trimmed,
            costMinorUnits: minorUnits,
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
        let amount = Decimal(string: costText)
        state.completions[index].revisions.append(CompletionRevision(
            actualDay: actualDay,
            notes: notes.trimmed,
            parts: parts.trimmed,
            costMinorUnits: amount.map { NSDecimalNumber(decimal: $0 * 100).intValue },
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
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func occurrences(from: LocalDay, through: LocalDay) -> [ScheduledOccurrence] {
        state.tasks
            .filter { !$0.isPaused }
            .flatMap { task in scheduledDays(for: task, through: through).compactMap { day in
                let key = "\(task.id.uuidString)-\(day.rawValue)"
                guard !state.completions.contains(where: {
                    $0.taskID == task.id && $0.scheduledDay == day
                }) else { return nil }
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

    private func scheduledDays(for task: TaskRecord, through end: LocalDay) -> [LocalDay] {
        var result: [LocalDay] = []
        var day = task.startDay
        var safety = 0
        while day <= end, safety < 4_000 {
            result.append(day)
            guard task.recurrence != .oneTime else { break }
            switch task.recurrence {
            case .oneTime: break
            case .days: day = day.adding(.day, value: task.interval)
            case .weeks: day = day.adding(.day, value: task.interval * 7)
            case .months: day = day.adding(.month, value: task.interval)
            case .years: day = day.adding(.year, value: task.interval)
            }
            safety += 1
        }
        return result
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
        for occurrence in occurrences(from: LocalDay.today, through: end).prefix(60) {
            guard
                let hour = occurrence.task.reminderHour,
                let minute = occurrence.task.reminderMinute
            else { continue }
            var components = Calendar.current.dateComponents(
                [.year, .month, .day],
                from: occurrence.visibleDay.date
            )
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

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
