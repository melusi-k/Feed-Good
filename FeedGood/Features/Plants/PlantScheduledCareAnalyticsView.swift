import SwiftUI
import SwiftData

/// A plant-scoped, read-only view over scheduled-care source records.
struct PlantScheduledCareAnalyticsView: View {
    let plant: Plant

    @Environment(\.calendar) private var calendar
    @State private var selectedRange: ScheduledCareAnalyticsRange = .last30Days

    var body: some View {
        PlantScheduledCareAnalyticsContent(
            plant: plant,
            selectedRange: $selectedRange,
            periodStart: selectedRange.period(now: .now, calendar: calendar)?.start ?? .distantPast
        )
    }
}

/// Fetches and renders one range's summary. A range change rebuilds this
/// view with a newly scoped fetch. Outcomes refresh on the exact due/grace
/// transition instants via `TimelineView(.explicit)` instead of polling, so
/// a screen left open crosses from due to overdue deterministically.
private struct PlantScheduledCareAnalyticsContent: View {
    let plant: Plant
    @Binding var selectedRange: ScheduledCareAnalyticsRange
    let periodStart: Date

    @Environment(\.calendar) private var calendar
    @Query private var opportunities: [CareOpportunity]
    @Query private var events: [CareEvent]
    @Query private var quietMemberships: [QuietPeriodTaskSnapshot]
    @Query private var tasks: [CareTask]

    init(
        plant: Plant,
        selectedRange: Binding<ScheduledCareAnalyticsRange>,
        periodStart: Date
    ) {
        self.plant = plant
        self._selectedRange = selectedRange
        self.periodStart = periodStart
        let plantID = plant.id
        _opportunities = Query(
            filter: ScheduledCareAnalyticsFetch.opportunitiesPredicate(
                plantID: plantID,
                periodStart: periodStart
            ),
            sort: \CareOpportunity.effectiveDueAt
        )
        _events = Query(
            filter: ScheduledCareAnalyticsFetch.eventsPredicate(plantID: plantID),
            sort: \CareEvent.completedAt
        )
        _quietMemberships = Query(
            filter: ScheduledCareAnalyticsFetch.activeQuietMembershipsPredicate(),
            sort: \QuietPeriodTaskSnapshot.capturedAt
        )
        _tasks = Query(
            filter: ScheduledCareAnalyticsFetch.tasksPredicate(plantID: plantID),
            sort: \CareTask.dueDate
        )
    }

    private func calculation(now: Date) -> Result<PlantScheduledCareAnalyticsSummary, ScheduledCareAnalyticsError> {
        guard let period = selectedRange.period(
            now: now,
            calendar: calendar
        ) else {
            return .failure(.invalidPeriod)
        }

        let quietPeriods = quietMemberships.compactMap {
            ScheduledCareQuietPeriodSnapshot(membership: $0)
        }

        do {
            let summary = try PlantScheduledCareAnalyticsSummary.calculate(
                plantID: plant.id,
                period: period,
                now: now,
                calendar: calendar,
                opportunities: opportunities.map(ScheduledCareOpportunitySnapshot.init),
                events: events.map(ScheduledCareEventSnapshot.init),
                quietPeriods: quietPeriods,
                isArchived: plant.archivedAt != nil
            )
            return .success(summary)
        } catch let error as ScheduledCareAnalyticsError {
            return .failure(error)
        } catch {
            return .failure(.invalidPeriod)
        }
    }

    /// The exact instants at which a displayed outcome can change while
    /// source records stay static: due instants, grace deadlines and
    /// future-dated completion instants among the fetched records.
    private var refreshTransitions: [Date] {
        ScheduledCareRefreshSchedule.transitions(
            after: .now,
            opportunities: opportunities.map(ScheduledCareOpportunitySnapshot.init),
            events: events.map(ScheduledCareEventSnapshot.init)
        )
    }

    var body: some View {
        TimelineView(.explicit(refreshTransitions)) { context in
            list(now: context.date)
        }
    }

    private func list(now: Date) -> some View {
        List {
            Section {
                Text("A record of scheduled care for this plant. These figures describe your saved records; they are not a plant-health or habit score.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if plant.archivedAt != nil {
                    Label("Archived plant · history is read-only", systemImage: "archivebox")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            switch calculation(now: now) {
            case .success(let summary):
                Section {
                    Picker("Date range", selection: $selectedRange) {
                        ForEach(ScheduledCareAnalyticsRange.allCases) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("scheduledCareAnalytics.range")

                    LabeledContent("Completed", value: "\(summary.completedCount)")
                    LabeledContent("Completed within 24 hours", value: "\(summary.completedOnTimeCount)")
                    LabeledContent("Completed late", value: "\(summary.completedLateCount)")
                    if summary.completedOutsideWindowCount > 0 {
                        LabeledContent("Completion date outside due window", value: "\(summary.completedOutsideWindowCount)")
                    }
                    LabeledContent("Due · within 24-hour window", value: "\(summary.unresolvedCount)")
                    LabeledContent("Overdue · window expired", value: "\(summary.overdueCount)")
                } header: {
                    Text("Scheduled outcomes · \(selectedRange.title)")
                } footer: {
                    Text(periodDescription(summary))
                }

                Section {
                    if let rate = summary.completionRate {
                        LabeledContent("Completion rate", value: "\(Int((rate * 100).rounded()))%")
                        Text("\(summary.completedCount) completed of \(summary.completedCount + summary.overdueCount) completed or overdue opportunities.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("A completion rate will appear when this period has completed or definitively overdue opportunities.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Completion rate")
                } footer: {
                    Text("Late linked care remains completed and is shown separately. Open opportunities enter the denominator only after the 24-hour window expires. Cancelled and not-yet-due opportunities are excluded.")
                }

                PlantCareConsistencySection(
                    plant: plant,
                    now: now,
                    events: events.map(ScheduledCareEventSnapshot.init),
                    quietPeriods: quietMemberships.compactMap {
                        ScheduledCareQuietPeriodSnapshot(membership: $0)
                    },
                    tasks: tasks
                )

                Section("Opportunity history") {
                    if summary.records.isEmpty {
                        ContentUnavailableView(
                            "No scheduled outcomes yet",
                            systemImage: "calendar",
                            description: Text("Eligible scheduled opportunities for this period will appear here. Manually recorded care remains in care history.")
                        )
                        .accessibilityIdentifier("scheduledCareAnalytics.emptyHistory")
                    } else {
                        ForEach(summary.records) { record in
                            if plant.archivedAt == nil {
                                NavigationLink {
                                    PlantCareView(plant: plant)
                                } label: {
                                    recordRow(record)
                                }
                                .accessibilityIdentifier("scheduledCareAnalytics.record.\(record.id.uuidString)")
                            } else {
                                recordRow(record)
                                    .accessibilityIdentifier("scheduledCareAnalytics.record.\(record.id.uuidString)")
                            }
                        }
                    }
                }

            case .failure:
                Section {
                    ContentUnavailableView(
                        "Scheduled care summary unavailable",
                        systemImage: "exclamationmark.circle",
                        description: Text("A source record could not be validated. Your care history has not been changed.")
                    )
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .feedGoodHeader("Scheduled care")
    }

    private func recordRow(_ record: ScheduledCareAnalyticsRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tasks.first { $0.id == record.taskID }?.title ?? "Removed care task")
                    .font(.headline)
                Spacer()
                Text(outcomeTitle(record.outcome))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text("Due \(record.effectiveDueAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let completedAt = record.completedAt {
                Text("Recorded \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Opportunity \(record.id.uuidString)")
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
            if let eventID = record.careEventID {
                Text("Care record \(eventID.uuidString)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 3)
    }

    private func periodDescription(_ summary: PlantScheduledCareAnalyticsSummary) -> String {
        let inclusiveEnd = summary.period.end.addingTimeInterval(-1)
        return "\(summary.period.start.formatted(date: .abbreviated, time: .omitted)) – \(inclusiveEnd.formatted(date: .abbreviated, time: .omitted)) · \(summary.timeZoneIdentifier)"
    }

    private func outcomeTitle(_ outcome: ScheduledCareOutcome) -> String {
        switch outcome {
        case .completedOnTime: "Completed"
        case .completedLate: "Completed late"
        case .completedOutsideWindow: "Completed · date corrected"
        case .unresolved: "Due"
        case .overdue: "Overdue"
        }
    }
}

/// Per-task consistency history. Runs span any window, so this section
/// keeps its own plant-scoped full-history opportunity fetch while reusing
/// the parent's already-scoped events, quiet periods and tasks.
private struct PlantCareConsistencySection: View {
    let plant: Plant
    let now: Date
    let events: [ScheduledCareEventSnapshot]
    let quietPeriods: [ScheduledCareQuietPeriodSnapshot]
    let tasks: [CareTask]

    @Query private var opportunityHistory: [CareOpportunity]

    init(
        plant: Plant,
        now: Date,
        events: [ScheduledCareEventSnapshot],
        quietPeriods: [ScheduledCareQuietPeriodSnapshot],
        tasks: [CareTask]
    ) {
        self.plant = plant
        self.now = now
        self.events = events
        self.quietPeriods = quietPeriods
        self.tasks = tasks
        _opportunityHistory = Query(
            filter: ScheduledCareAnalyticsFetch.opportunityHistoryPredicate(plantID: plant.id),
            sort: \CareOpportunity.effectiveDueAt
        )
    }

    private var streakSummaries: [CareTaskStreakSummary] {
        let opportunitySnapshots = opportunityHistory.map(ScheduledCareOpportunitySnapshot.init)
        // Task identity comes from the retained opportunities, so a deleted
        // task's consistency history stays visible alongside live tasks.
        let taskIDs = Set(opportunitySnapshots.filter { $0.plantID == plant.id }.map(\.taskID))
        return taskIDs
            .compactMap { taskID in
                guard let summary = try? CareTaskStreaks.calculate(
                    taskID: taskID,
                    now: now,
                    opportunities: opportunitySnapshots,
                    events: events,
                    quietPeriods: quietPeriods,
                    isArchived: plant.archivedAt != nil
                ), summary.longestStreak > 0 else { return nil }
                return summary
            }
            .sorted {
                taskTitle(for: $0.taskID).localizedCaseInsensitiveCompare(taskTitle(for: $1.taskID)) == .orderedAscending
            }
    }

    var body: some View {
        Section {
            if streakSummaries.isEmpty {
                Text("Consistency history appears here once scheduled opportunities are completed within their 24-hour window.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("scheduledCareAnalytics.consistency.empty")
            } else {
                ForEach(streakSummaries, id: \.taskID) { streak in
                    streakRow(streak)
                }
            }
        } header: {
            Text("Care consistency")
        } footer: {
            Text("Consecutive scheduled opportunities completed within their 24-hour window, counted separately for each care task. Cancelled, paused and archived periods are neutral. Late completions remain completed care but do not extend a run.")
        }
    }

    private func streakRow(_ streak: CareTaskStreakSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(taskTitle(for: streak.taskID))
                .font(.headline)
            Text("Completed in a row: \(streak.currentStreak)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let start = streak.currentRunStart {
                Text("Current run since \(start.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let longestStart = streak.longestRunStart, let longestEnd = streak.longestRunEnd {
                Text("Longest run: \(streak.longestStreak) · \(longestStart.formatted(date: .abbreviated, time: .omitted)) – \(longestEnd.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("scheduledCareAnalytics.consistency.\(streak.taskID.uuidString)")
    }

    private func taskTitle(for taskID: UUID) -> String {
        tasks.first { $0.id == taskID }?.title ?? "Removed care task"
    }
}
