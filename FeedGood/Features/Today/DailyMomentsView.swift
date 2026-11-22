import SwiftUI

struct DailyMomentsView: View {
    @State private var showingSource = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let reflection = DailyMoments.reflection(for: context.date)
            let tip = DailyMoments.tip(for: context.date)
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("A THOUGHT FOR TODAY", systemImage: "leaf")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                    Text(reflection.text)
                        .font(.system(size: 21, weight: .medium, design: .serif))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("today.dailyThought")
                    Text("A reflection, not a care instruction.")
                        .font(.caption)
                        .foregroundStyle(FeedGoodTheme.muted)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(FeedGoodTheme.leaf)
                .background(FeedGoodTheme.mist.opacity(0.82), in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))

                VStack(alignment: .leading, spacing: 12) {
                    Text("A GENERAL CARE TIP")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(FeedGoodTheme.leaf)
                    Text(tip.text)
                        .font(.system(size: 15))
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(FeedGoodTheme.soil)
                        .accessibilityIdentifier("today.careTip")
                    Text("General houseplant education. Check your plant's own needs.")
                        .font(.caption)
                        .foregroundStyle(FeedGoodTheme.muted)
                    Button { showingSource = true } label: {
                        Label("Source and review", systemImage: "info.circle")
                            .font(.caption.weight(.medium))
                            .frame(minHeight: 44, alignment: .leading)
                    }
                    .accessibilityIdentifier("today.tipSource")
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))
            }
            .sheet(isPresented: $showingSource) {
                NavigationStack {
                    List {
                        Section("General care tip") {
                            Text(tip.text)
                            Text(tip.sourceTitle)
                                .accessibilityIdentifier("today.sourceTitle")
                            Text("Source section: \(tip.sourceSection)")
                            Text("Source checked, not expert reviewed")
                                .accessibilityIdentifier("today.reviewStatus")
                            Text("Checked \(tip.reviewedOn). \(tip.reviewedBy).")
                            if let url = tip.sourceURL { Link("Read the source (internet required)", destination: url) }
                        }
                        Section("About daily content") {
                            Text("Reflections are original Feed Good copy, checked for tone. They are not factual care advice.")
                            Text("This content is bundled and works offline. Each library repeats after seven local days. Your local date selects the item; it refreshes within a minute while Today is open.")
                            Text("Content version \(DailyMoments.contentVersion). Source checks compare these general tips with the cited guidance. They do not replace expert horticultural review or advice for a particular plant.")
                        }
                    }
                    .feedGoodHeader("Source and review")
                    .toolbar { Button("Done") { showingSource = false }.accessibilityIdentifier("today.sourceDone") }
                }
            }
        }
    }
}
