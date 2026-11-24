import SwiftUI
import SwiftData

/// User-facing controls for creating and managing a plant's explicit Quiet Period.
struct QuietPeriodView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var scheduler: CareReminderScheduler
    @Environment(\.dismiss) private var dismiss

    let plant: Plant

    @State private var startDate = Date.now
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var reason = ""
    @State private var selectedTaskIDs: Set<UUID>
    @State private var isSaving = false
    @State private var isEnding = false
    @State private var isEditingPeriod = false
    @State private var editStartDate = Date.now
    @State private var editHasEndDate = false
    @State private var editEndDate = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var editReason = ""
    @State private var errorMessage: String?

    private var tasks: [CareTask] {
        (plant.careTasks ?? []).sorted {
            $0.dueDate == $1.dueDate ? $0.id.uuidString < $1.id.uuidString : $0.dueDate < $1.dueDate
        }
    }

    private var currentPeriod: QuietPeriod? {
        (plant.quietPeriods ?? []).first {
            $0.statusRaw == QuietPeriodStatus.active.rawValue ||
            $0.statusRaw == QuietPeriodStatus.scheduled.rawValue
        }
    }

    init(plant: Plant) {
        self.plant = plant
        _selectedTaskIDs = State(initialValue: Set((plant.careTasks ?? []).filter(\.isEnabled).map(\.id)))
    }

    var body: some View {
        Form {
            if let currentPeriod {
                currentPeriodSection(currentPeriod)
            } else {
                creationSections
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("quietPeriod.error")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .feedGoodHeader("Quiet Period")
        .onChange(of: startDate) { _, newStart in
            guard hasEndDate else { return }
            let earliestEnd = max(newStart, Date.now)
            if endDate <= earliestEnd {
                endDate = Calendar.current.date(byAdding: .minute, value: 1, to: earliestEnd) ?? earliestEnd.addingTimeInterval(60)
            }
        }
        .onChange(of: editStartDate) { _, newStart in
            guard editHasEndDate else { return }
            let earliestEnd = max(newStart, Date.now)
            if editEndDate <= earliestEnd {
                editEndDate = Calendar.current.date(byAdding: .minute, value: 1, to: earliestEnd) ?? earliestEnd.addingTimeInterval(60)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            if currentPeriod == nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") { createPeriod() }
                        .disabled(isSaving || selectedTaskIDs.isEmpty || (hasEndDate && endDate <= startDate))
                        .accessibilityIdentifier("quietPeriod.confirm")
                }
            }
        }
    }

    private var creationSections: some View {
        Group {
            Section {
                Text("Choose when care should pause. Feed Good will never start or end a Quiet Period automatically based on seasons, weather or location.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                DatePicker("Start date", selection: $startDate, in: Date.now..., displayedComponents: .date)
                    .accessibilityIdentifier("quietPeriod.startDate")
                Toggle("Set an end date", isOn: $hasEndDate)
                    .accessibilityIdentifier("quietPeriod.hasEndDate")
                if hasEndDate {
                    DatePicker("Care resumes", selection: $endDate, in: max(startDate, Date.now)..., displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("quietPeriod.endDate")
                } else {
                    Text("This period stays open until you end it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                TextField("Optional reason or label", text: $reason)
                    .accessibilityIdentifier("quietPeriod.reason")
            } header: {
                Text("Schedule")
            }

            Section {
                if tasks.filter(\.isEnabled).isEmpty {
                    Text("There are no enabled care tasks to pause. Enable a routine first.")
                        .foregroundStyle(.secondary)
                }
                ForEach(tasks.filter(\.isEnabled)) { task in
                    Toggle(isOn: selectionBinding(for: task)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.title)
                            Text("Next care: \(task.dueDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selectedTaskIDs.contains(task.id) ? impactDescription(for: task) : "This task will continue as normal.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("quietPeriod.task.\(task.id.uuidString)")
                }
            } header: {
                Text("Affected care tasks")
            } footer: {
                Text("Enabled tasks start selected. Disabled tasks are excluded. New tasks added later won't be included.")
            }

            Section("Before you confirm") {
                LabeledContent("Tasks affected", value: "\(selectedTaskIDs.count)")
                Text("The remaining time on each selected task is frozen using calendar days. Its stored due date is preserved, it is hidden from Today, and its local reminder is withheld while the period is active. Care resumes using your saved routine.")
                    .font(.callout)
                Text(hasEndDate
                     ? "Care resumes at \(endDate.formatted(date: .complete, time: .shortened))."
                     : "Care resumes only when you choose End Quiet Period.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("Your care history, journal entries and photos are not changed. Journal observations remain available.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func currentPeriodSection(_ period: QuietPeriod) -> some View {
        Group {
            Section("Current Quiet Period") {
                LabeledContent("Status", value: period.statusRaw.capitalized)
                LabeledContent("Starts", value: period.startAt.formatted(date: .complete, time: .shortened))
                if let endAt = period.endAt {
                    LabeledContent("Care resumes", value: endAt.formatted(date: .complete, time: .shortened))
                } else {
                    LabeledContent("Care resumes", value: "When you end it")
                }
                if let reason = period.reason, !reason.isEmpty {
                    LabeledContent("Reason", value: reason)
                }
                Text("\((period.taskSnapshots ?? []).filter { $0.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue }.count) care tasks are currently included.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if isEditingPeriod {
                    if period.statusRaw == QuietPeriodStatus.scheduled.rawValue {
                        DatePicker("Start date", selection: $editStartDate, in: Date.now..., displayedComponents: .date)
                            .accessibilityIdentifier("quietPeriod.editStartDate")
                    }
                    Toggle("Set an end date", isOn: $editHasEndDate)
                        .accessibilityIdentifier("quietPeriod.editHasEndDate")
                    if editHasEndDate {
                        DatePicker(
                            "Care resumes",
                            selection: $editEndDate,
                            in: max(editStartDate, Date.now)...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .accessibilityIdentifier("quietPeriod.editEndDate")
                    }
                    TextField("Optional reason or label", text: $editReason)
                        .accessibilityIdentifier("quietPeriod.editReason")
                    Button("Save changes") { updatePeriod(period) }
                        .disabled(isSaving || (editHasEndDate && editEndDate <= max(period.statusRaw == QuietPeriodStatus.scheduled.rawValue ? editStartDate : Date.now, Date.now)))
                        .accessibilityIdentifier("quietPeriod.saveEdit")
                    Button("Cancel editing", role: .cancel) { isEditingPeriod = false }
                        .accessibilityIdentifier("quietPeriod.cancelEdit")
                } else {
                    Button("Edit schedule") { beginEditing(period) }
                        .accessibilityIdentifier("quietPeriod.edit")
                }
            }

            if !isEditingPeriod {
                Section {
                    if period.statusRaw == QuietPeriodStatus.active.rawValue {
                        Button("End Quiet Period", role: .destructive) {
                            finishPeriod(period, cancel: false)
                        }
                        .disabled(isEnding)
                        .accessibilityIdentifier("quietPeriod.end")
                    } else {
                        Button("Cancel scheduled period", role: .destructive) {
                            finishPeriod(period, cancel: true)
                        }
                        .disabled(isEnding)
                        .accessibilityIdentifier("quietPeriod.cancel")
                    }
                } footer: {
                    Text(period.statusRaw == QuietPeriodStatus.active.rawValue
                         ? "Care resumes using the saved task schedules and current reminder settings. Existing care and journal history is preserved."
                         : "Cancelling removes the scheduled pause. Your normal care routine continues until then.")
                }
            }
        }
    }

    private func impactDescription(for task: CareTask) -> String {
        let appearsOnToday = TodayCare.items(from: tasks).contains { $0.task.id == task.id }
        let todayImpact = appearsOnToday ? "Today item will be hidden" : "Not currently on Today"
        let reminderImpact = task.reminderEnabled ? "reminder will be paused" : "no reminder is enabled"
        return "\(todayImpact) · \(reminderImpact)"
    }

    private func selectionBinding(for task: CareTask) -> Binding<Bool> {
        Binding(
            get: { selectedTaskIDs.contains(task.id) },
            set: { selected in
                if selected { selectedTaskIDs.insert(task.id) }
                else { selectedTaskIDs.remove(task.id) }
            }
        )
    }

    private func createPeriod() {
        guard !isSaving else { return }
        isSaving = true
        do {
            _ = try QuietPeriodLifecycle.create(
                for: plant,
                selectedTaskIDs: Array(selectedTaskIDs),
                startAt: startDate,
                endAt: hasEndDate ? endDate : nil,
                reason: reason,
                in: context
            )
            Task { @MainActor in
                await scheduler.reconcile(CareReminderScheduler.reminders(for: tasks))
                dismiss()
            }
        } catch {
            isSaving = false
            errorMessage = "Couldn't save this Quiet Period. Your care routines and history are unchanged. Check the selected tasks and dates, then try again."
        }
    }

    private func beginEditing(_ period: QuietPeriod) {
        editStartDate = period.startAt
        editHasEndDate = period.endAt != nil
        editEndDate = period.endAt ?? Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
        editReason = period.reason ?? ""
        isEditingPeriod = true
    }

    private func updatePeriod(_ period: QuietPeriod) {
        guard !isSaving else { return }
        isSaving = true
        do {
            try QuietPeriodLifecycle.updateSchedule(
                period,
                startAt: period.statusRaw == QuietPeriodStatus.scheduled.rawValue ? editStartDate : nil,
                endAt: editHasEndDate ? editEndDate : nil,
                reason: editReason,
                in: context
            )
            isEditingPeriod = false
            Task { @MainActor in
                await scheduler.reconcile(CareReminderScheduler.reminders(for: tasks))
                isSaving = false
            }
        } catch {
            isSaving = false
            errorMessage = "Couldn't update this Quiet Period. Its current schedule and affected tasks are unchanged. Check the dates and try again."
        }
    }

    private func finishPeriod(_ period: QuietPeriod, cancel: Bool) {
        guard !isEnding else { return }
        isEnding = true
        do {
            if cancel {
                try QuietPeriodLifecycle.cancelScheduled(period, in: context)
            } else {
                try QuietPeriodLifecycle.end(period, in: context)
            }
            Task { @MainActor in
                await scheduler.reconcile(CareReminderScheduler.reminders(for: tasks))
                dismiss()
            }
        } catch {
            isEnding = false
            errorMessage = "Couldn't update this Quiet Period. Your saved schedule is unchanged. Try again."
        }
    }
}
