import Foundation

/// Bundled copy is deliberately general, never a diagnosis or a plant-specific schedule.
struct DailyMoment: Identifiable, Equatable {
    enum Kind: String { case reflection, careTip }
    enum Review: String {
        case editorialChecked = "Editorial check"
        case sourceChecked = "Source checked, not expert reviewed"
        case needsReview = "Needs review"
    }
    let id: String
    let kind: Kind
    let text: String
    let sourceTitle: String
    let sourceURL: URL?
    let sourceSection: String
    let review: Review
    let reviewedOn: String
    let reviewedBy: String
}

enum DailyMoments {
    static let contentVersion = 1
    private static let missouri = URL(string: "https://extension.missouri.edu/publications/g6510")!
    private static let wisconsin = URL(string: "https://hort.extension.wisc.edu/articles/houseplant-care/")!

    static let reflections: [DailyMoment] = [
        reflection("notice", "There is no hurry. Notice one small thing today."),
        reflection("begin", "Begin with a moment of attention, not a perfect plan."),
        reflection("quiet", "A quiet check-in can be enough for today."),
        reflection("curiosity", "Make a little room for curiosity."),
        reflection("pace", "You can grow into this at your own pace."),
        reflection("return", "You can always return to a small beginning."),
        reflection("remember", "Some moments are worth pausing to remember.")
    ]

    static let tips: [DailyMoment] = [
        tip("check-first", "Check the soil before watering. Different plants and growing conditions need different watering rhythms.", section: "Watering"),
        tip("drainage", "Check that excess water can leave the pot. A decorative outer pot can hide standing water.", section: "Watering / Drainage"),
        tip("light-change", "Changing a plant's light? Make the move gradually, especially toward direct sun.", section: "Lighting"),
        tip("heat", "Notice nearby heaters and hot air vents. Hot air blowing onto a plant can damage its leaves.", section: "Temperature"),
        tip("fertiliser", "If you use fertiliser, follow its label. More than the recommended amount can harm roots.", section: "Fertilizing"),
        tip("inspect", "Take a look under leaves and around growing tips when you check a plant for pests.", source: "University of Wisconsin Extension", url: wisconsin, section: "Pests and Diseases"),
        tip("observe-light", "A plant struggling in poor light will not be helped by extra water or fertiliser. Check its growing conditions first.", section: "Lighting / Fertilizing")
    ]

    private static func reflection(_ id: String, _ text: String) -> DailyMoment {
        DailyMoment(id: "reflection.\(id)", kind: .reflection, text: text,
                    sourceTitle: "Feed Good original reflection", sourceURL: nil,
                    sourceSection: "Original copy, not horticultural advice", review: .editorialChecked,
                    reviewedOn: "2026-11-21", reviewedBy: "Assistant editorial check")
    }

    private static func tip(_ id: String, _ text: String, source: String = "University of Missouri Extension", url: URL = missouri, section: String) -> DailyMoment {
        DailyMoment(id: "tip.\(id)", kind: .careTip, text: text,
                    sourceTitle: source, sourceURL: url, sourceSection: section,
                    review: .sourceChecked, reviewedOn: "2026-11-21",
                    reviewedBy: "Assistant source check; no horticulturist sign-off")
    }

    static func reflection(for date: Date, calendar: Calendar = .current) -> DailyMoment {
        select(from: reflections, kind: .reflection, for: date, calendar: calendar)
    }

    static func tip(for date: Date, calendar: Calendar = .current) -> DailyMoment {
        select(from: tips, kind: .careTip, for: date, calendar: calendar)
    }

    /// Uses civil days, not elapsed 24-hour periods, so DST does not skip or repeat items.
    /// Gregorian day arithmetic keeps selection independent of the user's calendar identifier.
    /// Local timezone is intentional: travelling across midnight may change today's selection.
    static func select(from library: [DailyMoment], kind: DailyMoment.Kind, for date: Date, calendar: Calendar) -> DailyMoment {
        let eligible = library.filter {
            $0.kind == kind && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            ((kind == .reflection && $0.review == .editorialChecked) ||
             (kind == .careTip && $0.review == .sourceChecked && $0.sourceURL?.scheme == "https"))
        }
        guard !eligible.isEmpty else {
            return kind == .reflection ? reflections[0] : tips[0]
        }
        var civil = Calendar(identifier: .gregorian)
        civil.timeZone = calendar.timeZone
        let anchor = civil.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        let day = civil.dateComponents([.day], from: anchor, to: civil.startOfDay(for: date)).day ?? 0
        let index = ((day % eligible.count) + eligible.count) % eligible.count
        return eligible[index]
    }
}
