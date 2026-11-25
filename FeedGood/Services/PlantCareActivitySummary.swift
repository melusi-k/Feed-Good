import Foundation

/// Plant-scoped activity derived exclusively from existing CareEvent history.
/// The period is half-open [start, end), so adjacent periods cannot double-count
/// an event on their shared boundary.
struct PlantCareActivitySummary: Equatable {
    let plantID: UUID
    let period: DateInterval
    let records: [PlantCareActivityRecord]

    var eventCount: Int { records.count }
    var earliestRecordedAt: Date? { records.last?.completedAt }
    var latestRecordedAt: Date? { records.first?.completedAt }

    @MainActor
    init(plantID: UUID, period: DateInterval, events: [CareEvent]) {
        self.plantID = plantID
        self.period = period
        records = events
            .filter { event in
                event.plant?.id == plantID &&
                event.completedAt >= period.start &&
                event.completedAt < period.end
            }
            .map(PlantCareActivityRecord.init(event:))
            .sorted {
                if $0.completedAt != $1.completedAt {
                    return $0.completedAt > $1.completedAt
                }
                return $0.id.uuidString < $1.id.uuidString
            }
    }

    /// Uses the caller's calendar/time zone rather than assuming a week start.
    static func week(containing date: Date, calendar: Calendar) -> DateInterval? {
        calendar.dateInterval(of: .weekOfYear, for: date)
    }
}
