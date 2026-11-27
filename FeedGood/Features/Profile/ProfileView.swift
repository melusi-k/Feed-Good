import SwiftUI
import SwiftData

/// Shared by all tab roots. Personal identity, streaks and account dates are not
/// invented: this first profile reads only the garden records already on device.
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Plant.createdAt) private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @Query private var journalEntries: [JournalEntry]
    @Query(sort: \CareOpportunity.effectiveDueAt) private var careOpportunities: [CareOpportunity]
    @Query private var quietPeriods: [QuietPeriod]
    @ScaledMetric(relativeTo: .largeTitle) private var portraitSize = 84
    let openSettings: () -> Void

    private var summary: GardenProfileSummary {
        GardenProfileSummary(plants: plants, careEvents: careEvents, journalEntries: journalEntries)
    }

    /// Garden-wide streak scope: every opportunity belonging to a live
    /// plant. Deleted plants' records leave the scope with them.
    private var gardenOpportunitySnapshots: [ScheduledCareOpportunitySnapshot] {
        let livePlantIDs = Set(plants.map(\.id))
        return careOpportunities
            .filter { livePlantIDs.contains($0.plantID) }
            .map(ScheduledCareOpportunitySnapshot.init)
    }

    private var gardenEventSnapshots: [ScheduledCareEventSnapshot] {
        careEvents.map(ScheduledCareEventSnapshot.init)
    }

    private var gardenQuietPeriods: [ScheduledCareQuietPeriodSnapshot] {
        ScheduledCareAnalyticsFetch.activeMemberships(in: quietPeriods)
            .compactMap(ScheduledCareQuietPeriodSnapshot.init)
    }

    private func gardenStreak(now: Date) -> GardenCareStreakSummary? {
        try? GardenCareStreaks.calculate(
            now: now,
            calendar: .current,
            opportunities: gardenOpportunitySnapshots,
            events: gardenEventSnapshots,
            quietPeriods: gardenQuietPeriods,
            archivedPlantIDs: Set(plants.filter { $0.archivedAt != nil }.map(\.id))
        )
    }

    /// Re-evaluate the streak exactly when a displayed outcome can change:
    /// opportunity transitions plus the next local midnight, when the
    /// candidate day rolls over.
    private var gardenStreakRefreshTransitions: [Date] {
        var transitions = ScheduledCareRefreshSchedule.transitions(
            after: .now,
            opportunities: gardenOpportunitySnapshots,
            events: gardenEventSnapshots
        )
        if let nextMidnight = Calendar.current.dateInterval(of: .day, for: .now)?.end {
            transitions.append(nextMidnight)
        }
        return transitions.sorted()
    }

    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = info["CFBundleVersion"] as? String ?? "Unknown"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            TimelineView(.explicit(gardenStreakRefreshTransitions)) { context in
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: portraitSize, weight: .regular))
                            .foregroundStyle(FeedGoodTheme.leaf)
                            .accessibilityHidden(true)
                        Text("Your garden")
                            .font(.largeTitle.bold())
                            .fontDesign(.serif)
                            .accessibilityAddTraits(.isHeader)
                        Text("Your plants and the care you give them.")
                            .font(.subheadline)
                            .foregroundStyle(FeedGoodTheme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                        stat(summary.plantCount, title: "Plants", id: "plants")
                        stat(summary.careEventCount, title: "Care records", id: "care")
                        stat(summary.journalEntryCount, title: "Journal entries", id: "journal")
                    }

                    gardenCareStreakSection(now: context.date)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("ABOUT YOUR GARDEN")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FeedGoodTheme.muted)
                            .accessibilityAddTraits(.isHeader)
                        VStack(alignment: .leading, spacing: 16) {
                            NavigationLink {
                                growingContext
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Growing context").font(.headline)
                                        Text("Notes from your plant profiles")
                                            .font(.subheadline)
                                            .foregroundStyle(FeedGoodTheme.muted)
                                    }
                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.right").accessibilityHidden(true)
                                }
                            }
                            .accessibilityIdentifier("profile.context")
                            Divider()
                            Button(action: openSettings) {
                                HStack {
                                    Label("App settings", systemImage: "slider.horizontal.3")
                                    Spacer(minLength: 8)
                                    Image(systemName: "arrow.up.forward").accessibilityHidden(true)
                                }
                                .font(.headline)
                            }
                            .accessibilityIdentifier("profile.settings")
                            Text("Appearance and journal archive tools stay in Settings. Care reminders are managed in each plant's care routine.")
                                .font(.footnote)
                                .foregroundStyle(FeedGoodTheme.muted)
                        }
                        .padding(20)
                        .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))
                    }

                    VStack(spacing: 6) {
                        Text("Feed Good").font(.headline)
                        Text(version).font(.caption)
                        Text("Profile uses your existing garden records. It doesn't create an account.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(FeedGoodTheme.muted)
                    .frame(maxWidth: .infinity)
                }
                .padding(FeedGoodTheme.contentPadding)
            }
            }
            .background(FeedGoodTheme.background)
            .feedGoodHeader("Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("profile.done")
                }
            }
        }
        .tint(FeedGoodTheme.leaf)
        .presentationDragIndicator(.visible)
    }

    /// Garden-wide scheduled-care days, kept separate from the per-task
    /// Plant Care Streaks on each plant's analytics screen. Descriptive
    /// only: no rewards, targets or nudges, and no claim that care is owed
    /// every calendar day.
    @ViewBuilder
    private func gardenCareStreakSection(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("GARDEN CARE STREAK")
                .font(.caption.weight(.semibold))
                .foregroundStyle(FeedGoodTheme.muted)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 12) {
                if let streak = gardenStreak(now: now), let coverageStart = streak.coverageStart {
                    Text("Garden Care Streak")
                        .font(.headline)
                    if streak.currentRun > 0, let start = streak.currentRunStart {
                        Text("Current run: \(streak.currentRun) qualifying \(streak.currentRun == 1 ? "day" : "days") · since \(start.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .accessibilityIdentifier("profile.gardenStreak.current")
                    } else {
                        Text("No current run")
                            .font(.subheadline)
                            .accessibilityIdentifier("profile.gardenStreak.current")
                    }
                    if streak.longestRun > 0, let longestStart = streak.longestRunStart, let longestEnd = streak.longestRunEnd {
                        Text("Longest run: \(streak.longestRun) · \(longestStart.formatted(date: .abbreviated, time: .omitted)) – \(longestEnd.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(FeedGoodTheme.muted)
                            .accessibilityIdentifier("profile.gardenStreak.longest")
                    }
                    if let pending = streak.pendingDay {
                        let todayStart = Calendar.current.dateInterval(of: .day, for: now)?.start
                        let dayLabel = pending.dayStart == todayStart
                            ? "Today"
                            : pending.dayStart.formatted(date: .abbreviated, time: .omitted)
                        Text("\(dayLabel) is still open: \(pending.opportunityIDs.count) scheduled care \(pending.opportunityIDs.count == 1 ? "opportunity is" : "opportunities are") waiting inside their 24-hour windows.")
                            .font(.caption)
                            .foregroundStyle(FeedGoodTheme.muted)
                            .accessibilityIdentifier("profile.gardenStreak.pending")
                    }
                    Divider()
                    Text("A day qualifies when every scheduled care opportunity due that day is completed within its own 24-hour window. Days with no scheduled care are neutral and do not count for or against a run. This is a record of your saved care, not a daily-care target.")
                        .font(.footnote)
                        .foregroundStyle(FeedGoodTheme.muted)
                    Text("Counted in your local time zone (\(TimeZone.current.identifier)) since \(coverageStart.formatted(date: .abbreviated, time: .omitted)).")
                        .font(.footnote)
                        .foregroundStyle(FeedGoodTheme.muted)
                        .accessibilityIdentifier("profile.gardenStreak.coverage")
                } else {
                    Text("Garden Care Streak")
                        .font(.headline)
                    Text("Your garden-wide run of qualifying scheduled-care days appears here once a scheduled care opportunity is recorded.")
                        .font(.footnote)
                        .foregroundStyle(FeedGoodTheme.muted)
                        .accessibilityIdentifier("profile.gardenStreak.empty")
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))
            .accessibilityIdentifier("profile.gardenStreak")
        }
    }

    private func stat(_ value: Int, title: String, id: String) -> some View {
        VStack(spacing: 4) {
            Text(value, format: .number)
                .font(.title.bold())
                .fontDesign(.serif)
                .foregroundStyle(FeedGoodTheme.leaf)
            Text(title)
                .font(.caption)
                .foregroundStyle(FeedGoodTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .padding(8)
        .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(title)")
        .accessibilityIdentifier("profile.stats.\(id)")
    }

    private var growingContext: some View {
        Group {
            if plants.isEmpty {
                ContentUnavailableView("No plants yet", systemImage: "leaf", description: Text("Add a plant in My Plants to start saving its growing context."))
            } else {
                List(plants) { plant in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plant.name).font(.headline)
                        if !plant.species.isEmpty { Text(plant.species).font(.subheadline) }
                        Text(plant.notes.isEmpty ? "No notes saved for this plant." : plant.notes)
                            .font(.body)
                            .foregroundStyle(FeedGoodTheme.muted)
                    }
                    .padding(.vertical, 6)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(FeedGoodTheme.background)
        .feedGoodHeader("Growing context")
    }
}
