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
    @State private var editingEvent: CareEvent?
    @State private var note = ""
    @State private var errorMessage: String?

    private var tasks: [CareTask] { (plant.careTasks ?? []).sorted { $0.dueDate < $1.dueDate } }
    private var events: [CareEvent] { (plant.careEvents ?? []).sorted { $0.completedAt > $1.completedAt } }

    private func isLatestForTask(_ event: CareEvent) -> Bool {
        events.first { $0.taskID == event.taskID }?.id == event.id
    }

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
            Section("Routine review") {
                NavigationLink {
                    CareRoutineReviewView(plant: plant)
                } label: {
                    Label("Review this plant's care routine", systemImage: "calendar.badge.clock")
                }
                .accessibilityIdentifier("care.routineReview")
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
                    Button { editingEvent = event } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.taskTitle).font(.headline)
                            Text(event.completedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption)
                            if !event.note.isEmpty { Text(event.note) }
                        }
                    }
                    .buttonStyle(FeedGoodPressStyle())
                    .accessibilityIdentifier("care.eventEdit.\(event.taskTitle)")
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
        .sheet(item: $editingEvent) { event in
            CareEventEditor(event: event, isLatestForTask: isLatestForTask(event))
        }
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
    @State private var confirmingSave = false
    @State private var isSaving = false
    @State private var isDeleting = false

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
                    Button("Save") { confirmingSave = true }
                        .disabled(isSaving || (kind == .custom && customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                        .accessibilityIdentifier("care.taskSave")
                }
            }
            .onAppear {
                if let task { kind = task.kind; customTitle = task.customTitle; interval = task.intervalDays; dueDate = task.dueDate; enabled = task.isEnabled }
            }
            .task { reminders = task?.reminderEnabled ?? false }
            .alert("Review care changes", isPresented: $confirmingSave) {
                Button("Save changes") { save() }
                    .disabled(isSaving)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(saveImpactSummary)
            }
            .confirmationDialog("Remove this task? Its care history will stay.", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Remove task", role: .destructive) {
                    guard let task, isDeleting == false else { return }
                    isDeleting = true
                    Task { @MainActor in
                        do {
                            try await CareTaskEditorPersistence.deleteAndReconcile(
                                plantID: plant.id,
                                taskID: task.id,
                                in: context.container,
                                scheduler: scheduler
                            )
                            dismiss()
                        } catch {
                            isDeleting = false
                            errorMessage = "Couldn't remove this task. Your task and care history are unchanged. Try again."
                        }
                    }
                }
                .disabled(isDeleting)
            }
        }
    }

    private var saveImpactSummary: String {
        let date = dueDate.formatted(date: .complete, time: .shortened)
        let routine = enabled ? "The routine will be active." : "The routine will be paused."
        let reminder: String
        if enabled && reminders && dueDate > .now {
            reminder = "If notifications are allowed, one local reminder is eligible for this future care date."
        } else if !reminders {
            reminder = "No reminder will be scheduled."
        } else if !enabled {
            reminder = "No reminder will be scheduled while the routine is paused."
        } else {
            reminder = "No reminder will be scheduled because the next care date is not in the future."
        }
        return "Next care: \(date). Repeat every \(interval) days. \(routine) \(reminder)"
    }

    private func save() {
        guard isSaving == false else { return }
        isSaving = true
        Task { @MainActor in
            do {
                try await CareTaskEditorPersistence.saveAndReconcile(
                    plantID: plant.id,
                    taskID: task?.id,
                    kind: kind,
                    customTitle: customTitle,
                    intervalDays: interval,
                    dueDate: dueDate,
                    isEnabled: enabled,
                    reminderEnabled: reminders,
                    in: context.container,
                    scheduler: scheduler
                )
                dismiss()
            } catch {
                isSaving = false
                errorMessage = "Couldn't save this routine. Your existing routine and reminders are unchanged. Try again."
            }
        }
    }
}


struct CareEventEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let event: CareEvent
    let isLatestForTask: Bool
    @State private var completedAt = Date.now
    @State private var note = ""
    @State private var errorMessage: String?
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Completed", selection: $completedAt)
                        .accessibilityIdentifier("care.eventCompletedAt")
                    TextField("Optional note", text: $note).accessibilityIdentifier("care.eventNote")
                } footer: {
                    Text("Correcting changes only this history record. Your active routine is never changed here.")
                }
                if isLatestForTask {
                    Section {
                        Text("This is the latest record for \(event.taskTitle). The active routine stays unchanged; edit the routine to move the next care date.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button("Delete this record", role: .destructive) { confirmingDelete = true }
                        .accessibilityIdentifier("care.eventDelete")
                } footer: {
                    Text("Deleting removes this record from the on-device history permanently. Exported archives are unchanged.")
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .feedGoodHeader("Correct care record")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try CareRecorder.update(event, completedAt: completedAt, note: note, in: context)
                            dismiss()
                        } catch {
                            errorMessage = "Couldn't save this correction. The original record is unchanged. Try again."
                        }
                    }.accessibilityIdentifier("care.eventSave")
                }
            }
            .onAppear { completedAt = event.completedAt; note = event.note }
            .confirmationDialog("Delete this care record? This cannot be undone on this device.", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete record", role: .destructive) {
                    do { try CareRecorder.delete(event, in: context); dismiss() }
                    catch { errorMessage = "Couldn't delete this record. Nothing was removed. Try again." }
                }
            }
        }
    }
}
