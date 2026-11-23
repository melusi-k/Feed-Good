import SwiftUI

/// "What's New" sheet shown once per app version on the first launch after an
/// update. Content comes entirely from its `ReleaseNotesEntry`.
struct WhatsNewView: View {
    let entry: ReleaseNotesEntry
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("WHAT'S NEW")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(FeedGoodTheme.leaf)
                Text(entry.title)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(FeedGoodTheme.soil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("whatsNew.title")
                    .accessibilityAddTraits(.isHeader)
                Text("Version \(entry.version)")
                    .font(.caption)
                    .foregroundStyle(FeedGoodTheme.muted)
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(entry.highlights.enumerated()), id: \.offset) { index, highlight in
                    Label(highlight, systemImage: "sparkles")
                        .font(.body)
                        .foregroundStyle(FeedGoodTheme.soil)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("whatsNew.highlight.\(index)")
                }
            }

            Spacer(minLength: 0)

            Button {
                onContinue()
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(FeedGoodPressStyle(surface: .prominent))
            .accessibilityIdentifier("whatsNew.continue")
        }
        .padding(FeedGoodTheme.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FeedGoodTheme.background.ignoresSafeArea())
    }
}
