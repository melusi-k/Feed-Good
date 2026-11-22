import SwiftUI
import SwiftData

/// A read-only projection of the selected plant's existing care tasks.
enum CareRoutineReviewProjection {
    static func tasks(for plantID: UUID, from tasks: [CareTask]) -> [CareTask] {
        tasks
            .filter { $0.plant?.id == plantID }
            .sorted {
                if $0.dueDate != $1.dueDate { return $0.dueDate < $1.dueDate }
                return $0.id.uuidString < $1.id.uuidString
            }
    }
}

struct CareRoutineReviewView: View {
    let plant: Plant

    @Query private var allTasks: [CareTask]
    @State private var editingTask: CareTask?
    @State private var addingTask = false
    @State private var editingPlant = false

    private var tasks: [CareTask] {
        CareRoutineReviewProjection.tasks(for: plant.id, from: allTasks)
    }

    var body: some View {
        List {
            Section {
                Text("Review the routine you chose for \(plant.name). Nothing changes unless you choose to edit and save a task.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Growing context") {
                LabeledContent("Environment", value: plant.growingEnvironment.title)
                LabeledContent("Light", value: plant.lightCondition.title)
                Text("This context comes from your plant profile. It does not automatically change your care routine.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Edit growing context") { editingPlant = true }
                    .accessibilityIdentifier("careReview.editGrowingContext")
            }

            Section("Care routines") {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "No care routines yet",
                        systemImage: "calendar",
                        description: Text("Add a routine that suits \(plant.name). You choose the task, interval and next care date.")
                    )
                    Button("Add a care routine") { addingTask = true }
                        .accessibilityIdentifier("careReview.addTask")
                } else {
                    ForEach(tasks) { task in
                        Button { editingTask = task } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(task.title).font(.headline)
                                    Spacer()
                                    Text(task.isEnabled ? "Active" : "Paused")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(task.isEnabled ? FeedGoodTheme.leaf : FeedGoodTheme.muted)
                                }
                                Text("Every \(task.intervalDays) days · Next care \(task.dueDate.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(task.reminderEnabled ? "Reminder enabled" : "No reminder")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("careReview.task.\(task.id.uuidString)")
                    }
                    Button("Add another care routine", systemImage: "plus") { addingTask = true }
                        .accessibilityIdentifier("careReview.addTask")
                }
            } footer: {
                Text("These are your own settings, not recommended care frequencies. Review your plant's condition before deciding what it needs.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .feedGoodHeader("Review care routine")
        .sheet(item: $editingTask) { task in
            CareTaskEditor(plant: plant, task: task)
        }
        .sheet(isPresented: $addingTask) {
            CareTaskEditor(plant: plant)
        }
        .sheet(isPresented: $editingPlant) {
            EditPlantView(plant: plant)
        }
    }
}
