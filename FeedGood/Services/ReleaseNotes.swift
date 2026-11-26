import Foundation

struct ReleaseNoteHighlight: Equatable, Identifiable {
    let symbol: String
    let title: String
    let subtitle: String

    var id: String { title }
}

struct ReleaseNotesEntry: Equatable, Identifiable {
    let version: String
    let highlights: [ReleaseNoteHighlight]

    var id: String { version }
}

enum ReleaseNotes {
    /// Release notes are bundled and available offline. Add one entry for each
    /// marketing version that should present a What's New sheet.
    static let entries: [ReleaseNotesEntry] = [
        ReleaseNotesEntry(
            version: "0.1.46",
            highlights: [
                ReleaseNoteHighlight(
                    symbol: "calendar.badge.clock",
                    title: "Review your care routine",
                    subtitle: "See the impact of a routine change before it is saved."
                ),
                ReleaseNoteHighlight(
                    symbol: "photo.on.rectangle",
                    title: "Richer growth reviews",
                    subtitle: "Compare two journal photos per plant."
                ),
                ReleaseNoteHighlight(
                    symbol: "speaker.wave.2",
                    title: "Clearer VoiceOver feedback",
                    subtitle: "Growth Review selection now speaks clearly."
                )
            ]
        ),
        ReleaseNotesEntry(
            version: "0.1.0",
            highlights: [
                ReleaseNoteHighlight(
                    symbol: "leaf",
                    title: "Track every plant",
                    subtitle: "Your whole garden in one place."
                ),
                ReleaseNoteHighlight(
                    symbol: "drop",
                    title: "Gentle care reminders",
                    subtitle: "On your schedule, at your pace."
                ),
                ReleaseNoteHighlight(
                    symbol: "book.closed",
                    title: "A journal for each plant",
                    subtitle: "Notes and photos that grow into a story."
                )
            ]
        )
    ]

    static func entry(forVersion version: String) -> ReleaseNotesEntry? {
        entries.first { $0.version == version }
    }
}
