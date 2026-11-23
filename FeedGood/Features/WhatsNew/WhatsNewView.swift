import SwiftUI

/// "What's New" sheet shown once per app version on the first launch after an
/// update, as part of the onboarding implementation. Content comes entirely
/// from its `ReleaseNotesEntry`.
struct WhatsNewView: View {
    let entry: ReleaseNotesEntry
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("What's New")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(FeedGoodTheme.soil)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("whatsNew.title")
                    .accessibilityAddTraits(.isHeader)
                Text("Version \(entry.version)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FeedGoodTheme.leaf)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(FeedGoodTheme.mist, in: Capsule())
                    .accessibilityIdentifier("whatsNew.versionPill")
            }

            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(entry.highlights.enumerated()), id: \.offset) { index, highlight in
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
                    .accessibilityIdentifier("whatsNew.highlight.\(index)")
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 10) {
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

                Text("Shown once after each update.")
                    .font(.caption)
                    .foregroundStyle(FeedGoodTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(FeedGoodTheme.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FeedGoodTheme.surface.ignoresSafeArea())
    }
}
