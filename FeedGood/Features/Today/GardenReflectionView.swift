import SwiftUI
import SwiftData

/// The weekly Garden reflection on Today. Content is derived from current
/// records on every render, so edits and deletions are respected. No streaks,
/// no scores, no pressure: a small look-back over real moments.
struct GardenReflectionView: View {
    @Query(sort: \CareEvent.completedAt, order: .reverse) private var careEvents: [CareEvent]
    @Query(sort: \JournalEntry.date, order: .reverse) private var journalEntries: [JournalEntry]
    @State private var showingMoments = false
    @State private var dismissal = GardenReflectionDismissal()

    /// Opens the source plant for a moment. Wired by the parent, which owns
    /// the navigation path.
    var onOpenPlant: (UUID) -> Void = { _ in }

    private var reflection: WeeklyGardenReflection {
        GardenReflectionBuilder.reflection(for: .now, calendar: .current, careEvents: careEvents, journalEntries: journalEntries)
    }

    var body: some View {
        if dismissal.isDismissed(weekStart: reflection.weekStart) {
            dismissedRow
        } else {
            card
        }
    }

    private var dismissedRow: some View {
        HStack(spacing: 10) {
            Text("Your week is tucked away.")
                .font(.system(size: 13))
                .foregroundStyle(FeedGoodTheme.muted)
            Spacer(minLength: 0)
            Button("Show again") { dismissal.reopen() }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FeedGoodTheme.leaf)
                .frame(minHeight: 44)
                .accessibilityIdentifier("reflection.reopen")
        }
        .padding(.horizontal, 4)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeading("Your week so far", eyebrow: "GARDEN REFLECTION")

            if reflection.isEmpty {
                Text("A quiet week so far. Nothing recorded yet, and that is fine.")
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundStyle(FeedGoodTheme.soil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("reflection.empty")
            } else {
                Text(summaryLine)
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundStyle(FeedGoodTheme.soil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("reflection.summary")
            }

            Text(reflection.prompt)
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundStyle(FeedGoodTheme.leaf)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("reflection.prompt")

            HStack(spacing: 10) {
                if !reflection.moments.isEmpty {
                    Button { showingMoments = true } label: {
                        HStack(spacing: 8) {
                            Text("Look back")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FeedGoodTheme.surface)
                        .padding(.horizontal, 17)
                        .frame(height: 45)
                        .background(FeedGoodTheme.leaf, in: Capsule())
                    }
                    .accessibilityIdentifier("reflection.lookBack")
                }
                Spacer(minLength: 0)
                Button("Tuck away") { dismissal.dismiss(weekStart: reflection.weekStart) }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FeedGoodTheme.muted)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("reflection.dismiss")
            }
        }
        .padding(19)
        .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius, style: .continuous))
        // Keep the card a container: without .contain the identifier promotes
        // the whole card to one accessibility element and hides its children.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("reflection.card")
        .sheet(isPresented: $showingMoments) {
            GardenReflectionMomentsSheet(reflection: reflection) { plantID in
                showingMoments = false
                onOpenPlant(plantID)
            }
        }
    }

    private var summaryLine: String {
        var parts: [String] = []
        if reflection.careCount > 0 {
            parts.append(reflection.careCount == 1 ? "1 moment of care" : "\(reflection.careCount) moments of care")
        }
        if reflection.journalCount > 0 {
            parts.append(reflection.journalCount == 1 ? "1 journal note" : "\(reflection.journalCount) journal notes")
        }
        let counts = parts.joined(separator: " and ")
        switch reflection.plantNames.count {
        case 0: return "\(counts) this week."
        case 1: return "\(counts) this week, all for \(reflection.plantNames[0])."
        default: return "\(counts) this week across \(reflection.plantNames.joined(separator: ", "))."
        }
    }

    private func sectionHeading(_ title: String, eyebrow: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(FeedGoodTheme.leaf)
            Text(title)
                .font(.system(size: 21, weight: .semibold, design: .serif))
                .foregroundStyle(FeedGoodTheme.soil)
        }
    }
}

/// The look-back sheet: up to three real moments, each routing to its source
/// plant. Records stay in their home surfaces; this sheet only points.
private struct GardenReflectionMomentsSheet: View {
    let reflection: WeeklyGardenReflection
    let onOpenPlant: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("The week of \(reflection.weekStart.formatted(.dateTime.weekday(.wide).day().month(.wide)))")
                        .font(.system(size: 15))
                        .foregroundStyle(FeedGoodTheme.muted)
                        .accessibilityIdentifier("reflection.sheet.week")

                    VStack(spacing: 12) {
                        ForEach(Array(reflection.moments.enumerated()), id: \.element.id) { index, moment in
                            momentRow(moment, index: index)
                        }
                    }

                    Text("Every moment here comes from your own records. Nothing is graded and nothing is kept score of.")
                        .font(.caption)
                        .foregroundStyle(FeedGoodTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, FeedGoodTheme.contentPadding)
                .padding(.top, 14)
                .padding(.bottom, 34)
            }
            .background(FeedGoodTheme.background.ignoresSafeArea())
            .feedGoodHeader("Your week")
            .toolbar {
                Button("Done") { dismiss() }
                    .accessibilityIdentifier("reflection.sheet.done")
            }
        }
    }

    private func momentRow(_ moment: GardenReflectionMoment, index: Int) -> some View {
        Button {
            onOpenPlant(moment.plantID)
        } label: {
            HStack(spacing: 13) {
                Image(systemName: symbol(for: moment.kind))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(FeedGoodTheme.leaf)
                    .frame(width: 42, height: 42)
                    .background(FeedGoodTheme.mist, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text(moment.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FeedGoodTheme.soil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(moment.date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                        .font(.system(size: 12))
                        .foregroundStyle(FeedGoodTheme.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(FeedGoodTheme.muted)
            }
            .padding(14)
            .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(FeedGoodPressStyle())
        .accessibilityIdentifier("reflection.moment.\(index)")
    }

    private func symbol(for kind: GardenReflectionMoment.Kind) -> String {
        switch kind {
        case .milestone: return "sparkles"
        case .journal: return "book.closed"
        case .care: return "drop"
        }
    }
}
