import SwiftUI
import SwiftData

struct PlantCareView: View {
    @EnvironmentObject private var scheduler: CareReminderScheduler
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    let plant: Plant
    @State private var adding = false
    @State private var editing: CareTask?
    @State private var completing: CareTask?
    @State private var note = ""
    @State private var errorMessage: String?

    private var tasks: [CareTask] { (plant.careTasks ?? []).sorted { $0.dueDate < $1.dueDate } }
    private var events: [CareEvent] { (plant.careEvents ?? []).sorted { $0.completedAt > $1.completedAt } }

    var body: some View {
        List {
            Section {
                Text("Your schedule, not plant-care advice. Check the soil and your plant before deciding what it needs.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Section("Optional reminders") {
                Text(scheduler.message).font(.callout).foregroundStyle(.secondary)
                Button("Notification settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
            Section("Care routine") {
                if tasks.isEmpty { Text("No care tasks yet. Add a routine that suits this plant.").foregroundStyle(.secondary) }
                ForEach(tasks) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        Button { editing = task } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title).font(.headline)
                                Text(task.isEnabled ? "\(CareSchedule.state(for: task.dueDate).rawValue.capitalized) · \(task.dueDate.formatted(date: .abbreviated, time: .shortened))" : "Paused")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Text("Every \(task.intervalDays) days · user-defined").font(.caption).foregroundStyle(.secondary)
                            }
                        }.buttonStyle(FeedGoodPressStyle())
                        if task.isEnabled {
                            Button("Record care") { note = ""; completing = task }
                                .accessibilityIdentifier("care.complete.\(task.title)")
                        }
                    }.padding(.vertical, 4)
                }
            }
            Section("Care history") {
                if events.isEmpty { Text("The care you record will appear here.").foregroundStyle(.secondary) }
                ForEach(events) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.taskTitle).font(.headline)
                        Text(event.completedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption)
                        if !event.note.isEmpty { Text(event.note) }
                    }
                }
            }
        }
        .feedGoodCollectionMotion(value: tasks.map { "\($0.id):\($0.dueDate):\($0.isEnabled)" } + events.map { $0.id.uuidString })
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .feedGoodHeader("Care routine")
        .toolbar {
            Button("Add task", systemImage: "plus") { adding = true }.accessibilityIdentifier("care.add")
        }
        .sheet(isPresented: $adding) { CareTaskEditor(plant: plant) }
        .sheet(item: $editing) { CareTaskEditor(plant: plant, task: $0) }
        .sheet(item: $completing) { task in
            NavigationStack {
                Form {
                    Text(task.title)
                    TextField("Optional note", text: $note).accessibilityIdentifier("care.note")
                }
                .feedGoodHeader("Record care")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { completing = nil } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            do { try CareRecorder.complete(task, note: note, in: context); completing = nil }
                            catch { errorMessage = "Couldn't save this care event. Your routine has not changed. Try again." }
                        }.accessibilityIdentifier("care.recordSave")
                    }
                }
                .alert("Care not saved", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                    Button("OK") { errorMessage = nil }
                } message: { Text(errorMessage ?? "") }
            }
        }
    }
}

struct CareTaskEditor: View {
    @EnvironmentObject private var scheduler: CareReminderScheduler
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let plant: Plant
    var task: CareTask?
    @State private var kind: CareKind = .watering
    @State private var customTitle = ""
    @State private var interval = 7
    @State private var dueDate = Date.now
    @State private var enabled = true
    @State private var reminders = false
    @State private var errorMessage: String?
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Task", selection: $kind) { ForEach(CareKind.allCases) { Text($0.title).tag($0) } }
                    if kind == .custom { TextField("Task name", text: $customTitle).accessibilityIdentifier("care.customTitle") }
                    Stepper("Every \(interval) days", value: $interval, in: 1...3650)
                    DatePicker("Next care", selection: $dueDate)
                    Toggle("Routine enabled", isOn: $enabled)
                    Toggle("Remind me", isOn: Binding(get: { reminders }, set: { value in
                        reminders = value
                        if value { Task { await scheduler.requestPermission() } }
                    }))
                        .accessibilityIdentifier("care.remindMe")
                    Text("One alert at the next future care date. Notification text includes this plant and task name. Past-due tasks do not repeat alerts.").font(.caption).foregroundStyle(.secondary)
                } footer: { Text("Choose an interval for this plant. This is your own routine, not a recommended watering frequency.") }
                if task != nil {
                    Section {
                        Button("Remove task", role: .destructive) { confirmingDelete = true }
                    } footer: { Text("Removing a task keeps its recorded care history.") }
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .feedGoodHeader(task == nil ? "Add care task" : "Edit care task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(kind == .custom && customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("care.taskSave")
                }
            }
            .onAppear {
                if let task { kind = task.kind; customTitle = task.customTitle; interval = task.intervalDays; dueDate = task.dueDate; enabled = task.isEnabled }
            }
            .task { reminders = task?.reminderEnabled ?? false }
            .confirmationDialog("Remove this task? Its care history will stay.", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Remove task", role: .destructive) {
                    guard let task else { return }
                    context.delete(task)
                    do { try context.save(); dismiss() }
                    catch { context.rollback(); errorMessage = "Couldn't remove this task. Try again." }
                }
            }
        }
    }

    private func save() {
        let record = task ?? CareTask(kind: kind, intervalDays: interval, dueDate: dueDate, plant: plant)
        if task == nil { context.insert(record) }
        record.kindRaw = kind.rawValue
        record.customTitle = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        record.intervalDays = interval
        record.dueDate = dueDate
        record.isEnabled = enabled
        record.reminderEnabled = reminders
        do { try context.save(); dismiss() }
        catch { context.rollback(); errorMessage = "Couldn't save this routine. Try again." }
    }
}
