import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: UpkeepStore

    var body: some View {
        Group {
            if store.homes.isEmpty {
                WelcomeView()
            } else {
                TabView {
                    OccurrenceList(kind: .due)
                        .tabItem { Label("Due", systemImage: "calendar.badge.exclamationmark") }
                    OccurrenceList(kind: .upcoming)
                        .tabItem { Label("Upcoming", systemImage: "calendar") }
                    HistoryView()
                        .tabItem { Label("Completed", systemImage: "clock.arrow.circlepath") }
                    SetupView()
                        .tabItem { Label("Setup", systemImage: "slider.horizontal.3") }
                    DataView()
                        .tabItem { Label("Data", systemImage: "lock.shield") }
                }
            }
        }
        .alert("Upkeep Log", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

private struct WelcomeView: View {
    @EnvironmentObject private var store: UpkeepStore
    @State private var showingHome = false

    var body: some View {
        NavigationStack {
            EmptyStateView(
                title: "Start your local upkeep log",
                systemImage: "house.and.flag",
                message: "Create a home profile, then add rooms, assets, and upkeep tasks. No account or network connection is required."
            ) {
                Button("Create home profile") { showingHome = true }
                    .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Upkeep Log")
            .sheet(isPresented: $showingHome) {
                HomeForm { store.addHome(name: $0, address: $1) }
            }
        }
    }
}

private enum OccurrenceListKind {
    case due, upcoming
}

private struct OccurrenceList: View {
    @EnvironmentObject private var store: UpkeepStore
    let kind: OccurrenceListKind
    @State private var completing: ScheduledOccurrence?
    @State private var snoozing: ScheduledOccurrence?

    private var occurrences: [ScheduledOccurrence] {
        let today = LocalDay.today
        switch kind {
        case .due:
            return store.occurrences(
                from: .distantPast,
                through: today
            )
        case .upcoming:
            return store.occurrences(
                from: today.adding(.day, value: 1),
                through: today.adding(.year, value: 1)
            )
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if occurrences.isEmpty {
                    EmptyStateView(
                        title: kind == .due ? "No upkeep due" : "Nothing upcoming",
                        systemImage: "checkmark.circle",
                        message: "Create or review tasks in Setup."
                    ) {}
                } else {
                    List(occurrences) { occurrence in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(occurrence.task.name).font(.headline)
                            Text(status(for: occurrence))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Button("Complete") { completing = occurrence }
                                    .buttonStyle(.borderedProminent)
                                Button("Snooze") { snoozing = occurrence }
                                    .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .navigationTitle(kind == .due ? "Due" : "Upcoming")
            .sheet(item: $completing) { CompletionForm(occurrence: $0) }
            .sheet(item: $snoozing) { SnoozeForm(occurrence: $0) }
        }
    }

    private func status(for occurrence: ScheduledOccurrence) -> String {
        if occurrence.visibleDay != occurrence.scheduledDay {
            return "Snoozed until \(occurrence.visibleDay)"
        }
        if occurrence.visibleDay < .today {
            return "Overdue · scheduled \(occurrence.scheduledDay)"
        }
        return "Scheduled \(occurrence.scheduledDay)"
    }
}

private struct CompletionForm: View {
    @EnvironmentObject private var store: UpkeepStore
    @Environment(\.dismiss) private var dismiss
    let occurrence: ScheduledOccurrence
    @State private var actualDate = Date()
    @State private var notes = ""
    @State private var parts = ""
    @State private var cost = ""
    @State private var currency = Locale.current.currency?.identifier ?? "USD"

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Completed", selection: $actualDate, displayedComponents: .date)
                TextField("Notes", text: $notes, axis: .vertical)
                TextField("Parts used", text: $parts, axis: .vertical)
                TextField("Cost", text: $cost).keyboardType(.decimalPad)
                if !cost.isEmpty && UpkeepStore.minorUnits(from: cost) == nil {
                    Text("Enter a valid cost for your current region.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                TextField("Currency", text: $currency)
                    .textInputAutocapitalization(.characters)
            }
            .navigationTitle("Complete \(occurrence.task.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.complete(
                            occurrence,
                            actualDay: LocalDay(date: actualDate),
                            notes: notes,
                            parts: parts,
                            costText: cost,
                            currency: currency
                        )
                        dismiss()
                    }
                    .disabled(!cost.isEmpty && UpkeepStore.minorUnits(from: cost) == nil)
                }
            }
        }
    }
}

private struct SnoozeForm: View {
    @EnvironmentObject private var store: UpkeepStore
    @Environment(\.dismiss) private var dismiss
    let occurrence: ScheduledOccurrence
    @State private var date: Date

    init(occurrence: ScheduledOccurrence) {
        self.occurrence = occurrence
        _date = State(initialValue: occurrence.visibleDay.adding(.day, value: 1).localDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Remind me on",
                    selection: $date,
                    in: occurrence.scheduledDay.localDate...,
                    displayedComponents: .date
                )
            }
            .navigationTitle("Snooze")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.snooze(occurrence, until: LocalDay(date: date))
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct HistoryView: View {
    @EnvironmentObject private var store: UpkeepStore
    @State private var search = ""

    private var completions: [CompletionRecord] {
        store.completions
            .filter {
                search.isEmpty ||
                store.taskName(for: $0.taskID).localizedCaseInsensitiveContains(search) ||
                $0.latest.notes.localizedCaseInsensitiveContains(search)
            }
            .sorted { $0.latest.actualDay > $1.latest.actualDay }
    }

    var body: some View {
        NavigationStack {
            Group {
                if completions.isEmpty {
                    EmptyStateView(
                        title: "No completed upkeep",
                        systemImage: "clock",
                        message: "Completed tasks create an append-only history here."
                    ) {}
                } else {
                    List(completions) { completion in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(store.taskName(for: completion.taskID)).font(.headline)
                            Text("Completed \(completion.latest.actualDay)")
                            if !completion.latest.notes.isEmpty {
                                Text(completion.latest.notes).foregroundStyle(.secondary)
                            }
                            if completion.revisions.count > 1 {
                                Text("\(completion.revisions.count) revisions")
                                    .font(.caption)
                            }
                        }
                    }
                    .searchable(text: $search, prompt: "Search history")
                }
            }
            .navigationTitle("Completed")
        }
    }
}

private struct SetupView: View {
    @EnvironmentObject private var store: UpkeepStore
    @State private var form: SetupForm?

    var body: some View {
        NavigationStack {
            List {
                Section("Homes") {
                    ForEach(store.homes) { Text($0.name) }
                    Button("Add home") { form = .home }
                }
                Section("Rooms") {
                    ForEach(store.rooms) { Text($0.name) }
                    Button("Add room") { form = .room }
                        .disabled(store.homes.isEmpty)
                }
                Section("Assets") {
                    ForEach(store.assets) { Text($0.name) }
                    Button("Add asset") { form = .asset }
                        .disabled(store.homes.isEmpty)
                }
                Section("Tasks") {
                    ForEach(store.tasks) { task in
                        Toggle(isOn: Binding(
                            get: { !task.isPaused },
                            set: { store.setTaskPaused(task.id, paused: !$0) }
                        )) {
                            VStack(alignment: .leading) {
                                Text(task.name)
                                Text(task.startDay.rawValue).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Add task") { form = .task }
                        .disabled(store.homes.isEmpty)
                }
            }
            .navigationTitle("Setup")
            .sheet(item: $form) { form in
                switch form {
                case .home:
                    HomeForm { store.addHome(name: $0, address: $1) }
                case .room:
                    RoomForm()
                case .asset:
                    AssetForm()
                case .task:
                    TaskForm()
                }
            }
        }
    }
}

private enum SetupForm: String, Identifiable {
    case home, room, asset, task
    var id: String { rawValue }
}

private struct HomeForm: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var address = ""
    let save: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Home name", text: $name)
                TextField("Address label (optional)", text: $address)
            }
            .navigationTitle("Home profile")
            .formToolbar(canSave: !name.trimmed.isEmpty, dismiss: dismiss) {
                save(name, address)
            }
        }
    }
}

private struct RoomForm: View {
    @EnvironmentObject private var store: UpkeepStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var homeID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Home", selection: $homeID) {
                    ForEach(store.homes) { Text($0.name).tag(Optional($0.id)) }
                }
                TextField("Room name", text: $name)
            }
            .onAppear { homeID = homeID ?? store.homes.first?.id }
            .navigationTitle("Room")
            .formToolbar(canSave: homeID != nil && !name.trimmed.isEmpty, dismiss: dismiss) {
                if let homeID { store.addRoom(homeID: homeID, name: name) }
            }
        }
    }
}

private struct AssetForm: View {
    @EnvironmentObject private var store: UpkeepStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var homeID: UUID?
    @State private var roomID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Home", selection: $homeID) {
                    ForEach(store.homes) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("Room", selection: $roomID) {
                    Text("None").tag(UUID?.none)
                    ForEach(store.rooms.filter { $0.homeID == homeID }) {
                        Text($0.name).tag(Optional($0.id))
                    }
                }
                TextField("Asset name", text: $name)
            }
            .onAppear { homeID = homeID ?? store.homes.first?.id }
            .navigationTitle("Asset")
            .formToolbar(canSave: homeID != nil && !name.trimmed.isEmpty, dismiss: dismiss) {
                if let homeID { store.addAsset(homeID: homeID, roomID: roomID, name: name) }
            }
        }
    }
}

private struct TaskForm: View {
    @EnvironmentObject private var store: UpkeepStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var homeID: UUID?
    @State private var roomID: UUID?
    @State private var assetID: UUID?
    @State private var startDate = Date()
    @State private var recurrence = RecurrenceKind.oneTime
    @State private var interval = 1
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task name", text: $name)
                Picker("Home", selection: $homeID) {
                    ForEach(store.homes) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("Room", selection: $roomID) {
                    Text("None").tag(UUID?.none)
                    ForEach(store.rooms.filter { $0.homeID == homeID }) {
                        Text($0.name).tag(Optional($0.id))
                    }
                }
                Picker("Asset", selection: $assetID) {
                    Text("None").tag(UUID?.none)
                    ForEach(store.assets.filter { $0.homeID == homeID }) {
                        Text($0.name).tag(Optional($0.id))
                    }
                }
                DatePicker("Starts", selection: $startDate, displayedComponents: .date)
                Picker("Repeat", selection: $recurrence) {
                    ForEach(RecurrenceKind.allCases) { Text($0.title).tag($0) }
                }
                if recurrence != .oneTime {
                    Stepper("Every \(interval) \(recurrence.title.lowercased())", value: $interval, in: 1...365)
                }
                Toggle("Reminder", isOn: $reminderEnabled)
                if reminderEnabled {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            .onAppear { homeID = homeID ?? store.homes.first?.id }
            .navigationTitle("Upkeep task")
            .formToolbar(canSave: homeID != nil && !name.trimmed.isEmpty, dismiss: dismiss) {
                guard let homeID else { return }
                let time = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                store.addTask(TaskRecord(
                    homeID: homeID,
                    roomID: roomID,
                    assetID: assetID,
                    name: name,
                    startDay: LocalDay(date: startDate),
                    recurrence: recurrence,
                    interval: interval,
                    reminderHour: reminderEnabled ? time.hour : nil,
                    reminderMinute: reminderEnabled ? time.minute : nil
                ))
                if reminderEnabled {
                    Task { await store.requestReminderPermission() }
                }
            }
        }
    }
}

private struct DataView: View {
    @EnvironmentObject private var store: UpkeepStore
    @State private var exportURL: URL?
    @State private var importing = false
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    Label("All data stays on this iPhone unless you export it.", systemImage: "iphone.gen3")
                    Label("No account, analytics, or advertising SDK.", systemImage: "hand.raised")
                }
                Section("Portable data") {
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Share backup", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button {
                        do { exportURL = try store.exportURL() }
                        catch { store.errorMessage = error.localizedDescription }
                    } label: {
                        Label("Prepare JSON backup", systemImage: "archivebox")
                    }
                    Button {
                        importing = true
                    } label: {
                        Label("Restore JSON backup", systemImage: "square.and.arrow.down")
                    }
                }
                Section {
                    Button("Delete all local data", role: .destructive) { confirmReset = true }
                }
            }
            .navigationTitle("Privacy & Data")
            .fileImporter(
                isPresented: $importing,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let url = try result.get().first else { return }
                    try store.importData(from: url)
                } catch {
                    store.errorMessage = error.localizedDescription
                }
            }
            .confirmationDialog(
                "Delete every home, task, and history entry from this iPhone?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Delete all data", role: .destructive) { store.deleteAllData() }
            }
        }
    }
}

private extension View {
    func formToolbar(
        canSave: Bool,
        dismiss: DismissAction,
        save: @escaping () -> Void
    ) -> some View {
        toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .disabled(!canSave)
            }
        }
    }
}

private struct EmptyStateView<Actions: View>: View {
    let title: String
    let systemImage: String
    let message: String
    @ViewBuilder let actions: Actions

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            actions
        }
        .padding(32)
    }
}
