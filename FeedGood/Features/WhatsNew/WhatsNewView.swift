import SwiftUI

struct WhatsNewView: View {
    let entry: ReleaseNotesEntry
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT'S NEW")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(FeedGoodTheme.leaf)

                    Text("A little more for your garden.")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(FeedGoodTheme.soil)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("whatsNew.title")

                    Text("Version \(entry.version)")
                        .font(.subheadline)
                        .foregroundStyle(FeedGoodTheme.muted)
                        .accessibilityIdentifier("whatsNew.version")
                }

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(entry.highlights) { highlight in
                        WhatsNewHighlightRow(highlight: highlight)
                    }
                }

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(FeedGoodPressStyle(surface: .prominent))
                .accessibilityIdentifier("whatsNew.continue")
            }
            .padding(FeedGoodTheme.contentPadding)
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(FeedGoodTheme.background.ignoresSafeArea())
    }
}

private struct WhatsNewHighlightRow: View {
    let highlight: ReleaseNoteHighlight

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: highlight.symbol)
                .font(.title3)
                .foregroundStyle(FeedGoodTheme.leaf)
                .frame(width: 44, height: 44)
                .background(FeedGoodTheme.mist, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(highlight.title)
                    .font(.headline)
                    .foregroundStyle(FeedGoodTheme.soil)
                Text(highlight.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(FeedGoodTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
