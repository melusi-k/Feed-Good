import Foundation
import SwiftData

enum QuietPeriodStatus: String {
    case scheduled
    case active
    case ended
    case cancelled
}

enum QuietPeriodMembershipStatus: String {
    case active
    case disabled
    case removed
}

enum QuietPeriodLifecycleError: Error, Equatable {
    case archivedPlant
    case invalidDateRange
    case noTasksSelected
    case taskUnavailable
    case taskNotEnabled
    case activePeriodAlreadyExists
    case taskBelongsToAnotherPlant
    case periodUnavailable
    case periodAlreadyFinished
}

/// Owns Quiet Period creation and lifecycle transitions. CareTask.dueDate is
/// left untouched while a period is active; the snapshot is the pause clock.
@MainActor
enum QuietPeriodLifecycle {
    @discardableResult
    static func create(
        for plant: Plant,
        selectedTaskIDs: [UUID],
        startAt: Date,
        endAt: Date?,
        reason: String? = nil,
        now: Date = .now,
        in context: ModelContext,
        calendar: Calendar = .current,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws -> QuietPeriod {
        guard plant.archivedAt == nil else { throw QuietPeriodLifecycleError.archivedPlant }
        guard !(plant.quietPeriods ?? []).contains(where: {
            $0.statusRaw == QuietPeriodStatus.scheduled.rawValue ||
            $0.statusRaw == QuietPeriodStatus.active.rawValue
        }) else {
            throw QuietPeriodLifecycleError.activePeriodAlreadyExists
        }
        let effectiveStartAt = max(now, calendar.startOfDay(for: startAt))
        guard endAt == nil || endAt! > effectiveStartAt else {
            throw QuietPeriodLifecycleError.invalidDateRange
        }
        let uniqueIDs = Set(selectedTaskIDs)
        guard !uniqueIDs.isEmpty, uniqueIDs.count == selectedTaskIDs.count else {
            throw QuietPeriodLifecycleError.noTasksSelected
        }

        let tasks = plant.careTasks ?? []
        var selected: [CareTask] = []
        for taskID in selectedTaskIDs {
            guard let task = tasks.first(where: { $0.id == taskID }) else {
                throw QuietPeriodLifecycleError.taskUnavailable
            }
            guard task.plant?.id == plant.id else {
                throw QuietPeriodLifecycleError.taskBelongsToAnotherPlant
            }
            guard task.isEnabled else { throw QuietPeriodLifecycleError.taskNotEnabled }
            selected.append(task)
        }

        let status: QuietPeriodStatus = effectiveStartAt > now ? .scheduled : .active
        let period = QuietPeriod(
            createdAt: now,
            startAt: effectiveStartAt,
            endAt: endAt,
            statusRaw: status.rawValue,
            reason: reason?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            activatedAt: status == .active ? now : nil,
            plant: plant
        )
        context.insert(period)

        for task in selected {
            let snapshot = QuietPeriodTaskSnapshot(
                taskID: task.id,
                taskTitleSnapshot: task.title,
                capturedAt: now,
                updatedAt: now,
                quietPeriod: period
            )
            context.insert(snapshot)
        }

        if status == .active {
            captureSchedulingState(for: period, tasks: selected, at: now, calendar: calendar)
        }

        do {
            try save(context)
            return period
        } catch {
            context.delete(period)
            throw error
        }
    }

    /// Advances all persisted periods when the app becomes active. This
    /// provides reliable foreground catch-up for scheduled starts and finite ends.
    static func advanceAll(
        in context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        let periods = try context.fetch(FetchDescriptor<QuietPeriod>())
        for period in periods where
            period.statusRaw == QuietPeriodStatus.scheduled.rawValue ||
            period.statusRaw == QuietPeriodStatus.active.rawValue {
            try advance(period, now: now, in: context, calendar: calendar, save: save)
        }
    }

    /// Activates scheduled periods at their selected local start instant and
    /// ends finite active periods inclusively at endAt.
    static func advance(
        _ period: QuietPeriod,
        now: Date = .now,
        in context: ModelContext,
        calendar: Calendar = .current,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        guard let status = QuietPeriodStatus(rawValue: period.statusRaw) else {
            throw QuietPeriodLifecycleError.periodUnavailable
        }
        switch status {
        case .scheduled where now >= period.startAt:
            guard let plant = period.plant, plant.archivedAt == nil else {
                throw QuietPeriodLifecycleError.archivedPlant
            }
            let taskIDs = Set((period.taskSnapshots ?? []).map(\.taskID))
            let tasks = (plant.careTasks ?? []).filter { taskIDs.contains($0.id) && $0.isEnabled }
            let snapshotState = (period.taskSnapshots ?? []).map {
                ($0, $0.membershipStatusRaw, $0.remainingCalendarDays, $0.originalDueHour,
                 $0.originalDueMinute, $0.originalDueSecond, $0.updatedAt)
            }
            captureSchedulingState(for: period, tasks: tasks, at: period.startAt, calendar: calendar)
            let previousStatus = period.statusRaw
            let previousActivation = period.activatedAt
            period.statusRaw = QuietPeriodStatus.active.rawValue
            period.activatedAt = period.startAt
            do { try save(context) }
            catch {
                for (snapshot, membership, remaining, hour, minute, second, updatedAt) in snapshotState {
                    snapshot.membershipStatusRaw = membership
                    snapshot.remainingCalendarDays = remaining
                    snapshot.originalDueHour = hour
                    snapshot.originalDueMinute = minute
                    snapshot.originalDueSecond = second
                    snapshot.updatedAt = updatedAt
                }
                period.statusRaw = previousStatus
                period.activatedAt = previousActivation
                throw error
            }
            let hasActiveMembers = (period.taskSnapshots ?? []).contains {
                $0.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue
            }
            if !hasActiveMembers {
                try end(period, at: now, in: context, calendar: calendar, save: save)
            } else if let endAt = period.endAt, now >= endAt {
                try end(period, at: endAt, in: context, calendar: calendar, save: save)
            }
        case .active:
            let hasActiveMembers = (period.taskSnapshots ?? []).contains {
                $0.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue
            }
            if !hasActiveMembers {
                try end(period, at: now, in: context, calendar: calendar, save: save)
            } else if let endAt = period.endAt, now >= endAt {
                try end(period, at: endAt, in: context, calendar: calendar, save: save)
            }
        default:
            return
        }
    }

    /// Resumes affected tasks from the frozen calendar-day offset, or from a
    /// full interval after a completion/interval edit. Explicit Next care
    /// overrides remain exact absolute instants.
    static func end(
        _ period: QuietPeriod,
        at date: Date = .now,
        in context: ModelContext,
        calendar: Calendar = .current,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        guard period.statusRaw == QuietPeriodStatus.active.rawValue else {
            throw QuietPeriodLifecycleError.periodAlreadyFinished
        }
        let snapshots = period.taskSnapshots ?? []
        let tasks = period.plant?.careTasks ?? []
        let affectedTasks = snapshots.compactMap { snapshot -> CareTask? in
            guard snapshot.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue,
                  let task = tasks.first(where: { $0.id == snapshot.taskID }),
                  task.isEnabled else { return nil }
            return task
        }
        let previousDueDates = affectedTasks.map { ($0, $0.dueDate) }
        let opportunitySnapshot = try CareOpportunityLifecycle.snapshot(
            for: Set(affectedTasks.map(\.id)),
            in: context
        )

        let previousStatus = period.statusRaw
        let previousEndedAt = period.endedAt
        do {
            for (task, _) in previousDueDates {
                guard let snapshot = snapshots.first(where: { $0.taskID == task.id }) else { continue }
                if let override = snapshot.nextCareOverrideAt {
                    task.dueDate = override
                } else if let interval = snapshot.frozenIntervalDays {
                    task.dueDate = reconstructedDate(
                        from: date,
                        dayOffset: max(1, interval),
                        hour: snapshot.originalDueHour,
                        minute: snapshot.originalDueMinute,
                        second: snapshot.originalDueSecond,
                        calendar: calendar
                    )
                } else if let remaining = snapshot.remainingCalendarDays {
                    task.dueDate = reconstructedDate(
                        from: date,
                        dayOffset: remaining,
                        hour: snapshot.originalDueHour,
                        minute: snapshot.originalDueMinute,
                        second: snapshot.originalDueSecond,
                        calendar: calendar
                    )
                }
            }

            for (task, previousDueDate) in previousDueDates {
                try CareOpportunityLifecycle.resumeAfterQuietPeriod(
                    for: task,
                    previousDueDate: previousDueDate,
                    at: date,
                    in: context
                )
            }

            period.statusRaw = QuietPeriodStatus.ended.rawValue
            period.endedAt = date
            try save(context)
        } catch {
            for (task, dueDate) in previousDueDates { task.dueDate = dueDate }
            period.statusRaw = previousStatus
            period.endedAt = previousEndedAt
            CareOpportunityLifecycle.restore(opportunitySnapshot, in: context)
            throw error
        }
    }

    /// Updates the user-controlled schedule and label without changing the
    /// captured task set. A scheduled period moved to today activates immediately.
    /// Active periods retain their original start and frozen task snapshots.
    static func updateSchedule(
        _ period: QuietPeriod,
        startAt: Date? = nil,
        endAt: Date?,
        reason: String?,
        now: Date = .now,
        in context: ModelContext,
        calendar: Calendar = .current,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        guard period.statusRaw == QuietPeriodStatus.scheduled.rawValue ||
                period.statusRaw == QuietPeriodStatus.active.rawValue else {
            throw QuietPeriodLifecycleError.periodUnavailable
        }

        let wasScheduled = period.statusRaw == QuietPeriodStatus.scheduled.rawValue
        let effectiveStart = wasScheduled
            ? max(now, calendar.startOfDay(for: startAt ?? period.startAt))
            : period.startAt
        if let endAt {
            let minimumEnd = wasScheduled ? effectiveStart : now
            guard endAt > minimumEnd else {
                throw QuietPeriodLifecycleError.invalidDateRange
            }
        }

        let previousStart = period.startAt
        let previousEnd = period.endAt
        let previousReason = period.reason
        let previousStatus = period.statusRaw
        let previousActivation = period.activatedAt
        let previousEndedAt = period.endedAt
        let snapshotState = (period.taskSnapshots ?? []).map {
            ($0, $0.membershipStatusRaw, $0.remainingCalendarDays, $0.originalDueHour,
             $0.originalDueMinute, $0.originalDueSecond, $0.updatedAt)
        }

        period.startAt = effectiveStart
        period.endAt = endAt
        period.reason = reason?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        if wasScheduled && effectiveStart <= now {
            let selectedIDs = Set((period.taskSnapshots ?? []).map(\.taskID))
            let selectedTasks = (period.plant?.careTasks ?? []).filter {
                selectedIDs.contains($0.id) && $0.isEnabled
            }
            captureSchedulingState(for: period, tasks: selectedTasks, at: now, calendar: calendar)
            period.statusRaw = QuietPeriodStatus.active.rawValue
            period.activatedAt = now
            let hasActiveMembers = (period.taskSnapshots ?? []).contains {
                $0.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue
            }
            if !hasActiveMembers {
                period.statusRaw = QuietPeriodStatus.ended.rawValue
                period.endedAt = now
            }
        }

        do {
            try save(context)
        } catch {
            period.startAt = previousStart
            period.endAt = previousEnd
            period.reason = previousReason
            period.statusRaw = previousStatus
            period.activatedAt = previousActivation
            period.endedAt = previousEndedAt
            for (snapshot, membership, remaining, hour, minute, second, updatedAt) in snapshotState {
                snapshot.membershipStatusRaw = membership
                snapshot.remainingCalendarDays = remaining
                snapshot.originalDueHour = hour
                snapshot.originalDueMinute = minute
                snapshot.originalDueSecond = second
                snapshot.updatedAt = updatedAt
            }
            throw error
        }
    }

    /// Cancels a future period without changing any task schedule.
    static func cancelScheduled(
        _ period: QuietPeriod,
        at date: Date = .now,
        in context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        guard period.statusRaw == QuietPeriodStatus.scheduled.rawValue else {
            throw QuietPeriodLifecycleError.periodAlreadyFinished
        }
        let previousStatus = period.statusRaw
        let previousEndedAt = period.endedAt
        period.statusRaw = QuietPeriodStatus.cancelled.rawValue
        period.endedAt = date
        do { try save(context) }
        catch {
            period.statusRaw = previousStatus
            period.endedAt = previousEndedAt
            throw error
        }
    }

    /// Cancels a scheduled period or ends an active one when its plant is
    /// archived. History is retained and restore never reactivates it.
    static func endForArchive(
        _ period: QuietPeriod,
        at date: Date = .now,
        in context: ModelContext,
        calendar: Calendar = .current,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        switch period.statusRaw {
        case QuietPeriodStatus.scheduled.rawValue:
            let previousStatus = period.statusRaw
            let previousEndedAt = period.endedAt
            period.statusRaw = QuietPeriodStatus.cancelled.rawValue
            period.endedAt = date
            do { try save(context) }
            catch {
                period.statusRaw = previousStatus
                period.endedAt = previousEndedAt
                throw error
            }
        case QuietPeriodStatus.active.rawValue:
            try end(period, at: date, in: context, calendar: calendar, save: save)
        default:
            return
        }
    }

    /// Keeps an audit membership row while removing a disabled/deleted task
    /// from the active pause set. The period ends when no active members remain.
    static func removeTaskFromActiveSet(
        taskID: UUID,
        status: QuietPeriodMembershipStatus,
        in period: QuietPeriod,
        at date: Date = .now,
        context: ModelContext,
        calendar: Calendar = .current,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        guard period.statusRaw == QuietPeriodStatus.active.rawValue,
              let snapshot = (period.taskSnapshots ?? []).first(where: { $0.taskID == taskID }),
              snapshot.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue else {
            return
        }
        let oldStatus = snapshot.membershipStatusRaw
        let oldUpdatedAt = snapshot.updatedAt
        snapshot.membershipStatusRaw = status.rawValue
        snapshot.updatedAt = date
        let remaining = (period.taskSnapshots ?? []).contains {
            $0.id != snapshot.id && $0.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue
        }
        do {
            if remaining {
                try save(context)
            } else {
                try end(period, at: date, in: context, calendar: calendar, save: save)
            }
        } catch {
            snapshot.membershipStatusRaw = oldStatus
            snapshot.updatedAt = oldUpdatedAt
            throw error
        }
    }

    private static func captureSchedulingState(
        for period: QuietPeriod,
        tasks: [CareTask],
        at activationDate: Date,
        calendar: Calendar
    ) {
        let startOfActivationDay = calendar.startOfDay(for: activationDate)
        let allPlantTasks = period.plant?.careTasks ?? []
        for snapshot in period.taskSnapshots ?? [] {
            guard let task = allPlantTasks.first(where: { $0.id == snapshot.taskID }) else {
                if snapshot.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue {
                    snapshot.membershipStatusRaw = QuietPeriodMembershipStatus.removed.rawValue
                }
                continue
            }
            guard task.isEnabled, tasks.contains(where: { $0.id == task.id }) else {
                snapshot.membershipStatusRaw = QuietPeriodMembershipStatus.disabled.rawValue
                snapshot.updatedAt = activationDate
                continue
            }
            let dueDay = calendar.startOfDay(for: task.dueDate)
            snapshot.remainingCalendarDays = calendar.dateComponents([.day], from: startOfActivationDay, to: dueDay).day ?? 0
            let components = calendar.dateComponents([.hour, .minute, .second], from: task.dueDate)
            snapshot.originalDueHour = components.hour ?? 9
            snapshot.originalDueMinute = components.minute ?? 0
            snapshot.originalDueSecond = components.second ?? 0
            snapshot.updatedAt = activationDate
        }
    }

    private static func reconstructedDate(
        from resumeDate: Date,
        dayOffset: Int,
        hour: Int?,
        minute: Int?,
        second: Int?,
        calendar: Calendar
    ) -> Date {
        let resumeDay = calendar.startOfDay(for: resumeDate)
        let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: resumeDay) ?? resumeDay
        return calendar.date(
            bySettingHour: hour ?? 9,
            minute: minute ?? 0,
            second: second ?? 0,
            of: targetDay,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        ) ?? targetDay
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
