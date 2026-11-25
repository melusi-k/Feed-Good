import SwiftUI
import SwiftData

/// A plant-scoped, read-only view over scheduled-care source records.
struct PlantScheduledCareAnalyticsView: View {
    let plant: Plant

    @Environment(\.calendar) private var calendar
    @Query private var opportunities: [CareOpportunity]
    @Query private var events: [CareEvent]
    @Query private var quietMemberships: [QuietPeriodTaskSnapshot]
    @Query private var tasks: [CareTask]

    private var calculation: Result<PlantScheduledCareAnalyticsSummary, ScheduledCareAnalyticsError> {
        let now = Date.now
        guard let period = PlantScheduledCareAnalyticsSummary.recent30Days(
            now: now,
            calendar: calendar
        ) else {
            return .failure(.invalidOpportunityStatus(UUID()))
        }

        let quietPeriods = quietMemberships.compactMap {
            ScheduledCareQuietPeriodSnapshot(membership: $0, now: now)
        }

        do {
            let summary = try PlantScheduledCareAnalyticsSummary.calculate(
                plantID: plant.id,
                period: period,
                now: now,
                calendar: calendar,
                opportunities: opportunities.map(ScheduledCareOpportunitySnapshot.init),
                events: events.map(ScheduledCareEventSnapshot.init),
                quietPeriods: quietPeriods
            )
            return .success(summary)
        } catch let error as ScheduledCareAnalyticsError {
            return .failure(error)
        } catch {
            return .failure(.invalidOpportunityStatus(UUID()))
        }
    }

    var body: some View {
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

            switch calculation {
            case .success(let summary):
                Section {
                    LabeledContent("Completed", value: "\(summary.completedCount)")
                    LabeledContent("Completed within 24 hours", value: "\(summary.completedOnTimeCount)")
                    LabeledContent("Completed late", value: "\(summary.completedLateCount)")
                    if summary.completedOutsideWindowCount > 0 {
                        LabeledContent("Completion date outside due window", value: "\(summary.completedOutsideWindowCount)")
                    }
                    LabeledContent("Due · within 24-hour window", value: "\(summary.unresolvedCount)")
                    LabeledContent("Overdue · window expired", value: "\(summary.overdueCount)")
                } header: {
                    Text("Scheduled outcomes · last 30 days")
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

                Section("Opportunity history") {
                    if summary.records.isEmpty {
                        ContentUnavailableView(
                            "No scheduled outcomes yet",
                            systemImage: "calendar",
                            description: Text("Eligible scheduled opportunities for this period will appear here. Manually recorded care remains in care history.")
                        )
                    } else {
                        ForEach(summary.records) { record in
                            NavigationLink {
                                PlantCareView(plant: plant)
                            } label: {
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
                            .accessibilityIdentifier("scheduledCareAnalytics.record.\(record.id.uuidString)")
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
