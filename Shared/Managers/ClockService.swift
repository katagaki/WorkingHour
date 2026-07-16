//
//  ClockService.swift
//  WorkingHour
//
//  Created by Assistant on 2026/07/16.
//

import Foundation
import SwiftData

/// Single source of truth for clock in/out and break operations.
///
/// Every entry point into the timesheet (manual UI, geofencing, notification
/// actions, app intents) goes through this service so that side effects —
/// saving, Live Activity lifecycle, confirmation notifications and session
/// location upkeep — behave identically regardless of how an action was
/// triggered.
@MainActor
final class ClockService {

    static let shared = ClockService()

    /// Where a clock action originated from.
    enum Source {
        case manual
        case geofence
        case notificationAction
        case intent
    }

    private var modelContext: ModelContext {
        SharedModelContainer.shared.container.mainContext
    }

    private init() {
    }

    // MARK: - Queries

    /// The most recent entry that has not been clocked out yet, if any.
    func activeEntry() -> ClockEntry? {
        let descriptor = FetchDescriptor<ClockEntry>(
            predicate: #Predicate { $0.clockOutTime == nil },
            sortBy: [SortDescriptor(\.clockInTime, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor))?.first
    }

    var hasActiveSession: Bool {
        activeEntry() != nil
    }

    // MARK: - Operations

    /// Starts a new work session. Returns the side-effect task so callers that
    /// must outlive their process (e.g. app intents) can await it, or `nil`
    /// when a session is already active.
    @discardableResult
    func clockIn(at date: Date = .now, source: Source) -> Task<Void, Never>? {
        guard activeEntry() == nil else {
            log("ClockService: Already clocked in, ignoring clock-in from \(source)", prefix: "SHUN")
            return nil
        }

        let newEntry = ClockEntry(date)
        modelContext.insert(newEntry)
        persist()

        log("ClockService: Clocked in at \(date) from \(source)", prefix: "SHUN")

        // Receiving location updates makes the app eligible to start a Live
        // Activity from the background, so pulse before requesting it, and
        // keep the activity fresh for the rest of the session. Geofence and
        // notification-confirmed clock-ins are known to be at the workplace.
        GeofencingManager.shared.beginLocationPulse()
        GeofencingManager.shared.sessionDidStart(
            confirmedAtWorkplace: source == .geofence || source == .notificationAction
        )

        let sessionData = newEntry.toWorkSessionData()
        return Task {
            NotificationManager.shared.clearConfirmationRequests()
            if let sessionData {
                await LiveActivities.startOrUpdateActivity(with: sessionData)
            }
            await NotificationManager.shared.sendClockInConfirmation(at: date)
        }
    }

    /// Ends the active work session, closing any open break first. Returns
    /// `nil` when there is no active session.
    @discardableResult
    func clockOut(
        at date: Date = .now,
        source: Source,
        dismissActivityImmediately: Bool = true
    ) -> Task<Void, Never>? {
        guard let entry = activeEntry() else {
            log("ClockService: No active entry, ignoring clock-out from \(source)", prefix: "SHUN")
            return nil
        }

        // Never clock out before the session began (a backdated location fix
        // or notification could otherwise produce a negative session).
        let date = max(date, entry.clockInTime ?? date)

        // `breakTimes` is an unordered SwiftData relationship, so find the
        // open break explicitly rather than relying on `.last`.
        if entry.isOnBreak,
           let openBreak = (entry.breakTimes ?? []).first(where: { $0.end == nil }) {
            openBreak.end = max(date, openBreak.start)
        }
        entry.isOnBreak = false
        entry.clockOutTime = date
        persist()

        log("ClockService: Clocked out at \(date) from \(source)", prefix: "SHUN")

        GeofencingManager.shared.sessionDidEnd()

        let sessionData = entry.toWorkSessionData()
        return Task {
            NotificationManager.shared.clearConfirmationRequests()
            if let sessionData {
                await LiveActivities.endActivity(with: sessionData, immediately: dismissActivityImmediately)
            }
        }
    }

    /// Starts a break on the active session. Returns `nil` when there is no
    /// active session or a break is already in progress.
    @discardableResult
    func startBreak(at date: Date = .now, source: Source, notify: Bool = false) -> Task<Void, Never>? {
        guard let entry = activeEntry() else {
            log("ClockService: No active entry, ignoring break start from \(source)", prefix: "SHUN")
            return nil
        }
        guard !entry.isOnBreak else {
            log("ClockService: Already on break, ignoring break start from \(source)", prefix: "SHUN")
            return nil
        }

        let newBreak = Break(start: date)
        newBreak.clockEntry = entry
        modelContext.insert(newBreak)
        entry.isOnBreak = true
        persist()

        log("ClockService: Started break at \(date) from \(source)", prefix: "SHUN")

        // Breaks that started because the user left the workplace may be
        // ended automatically when they are detected back inside; manually
        // started breaks must never be.
        GeofencingManager.shared.noteBreakStarted(
            awayFromWorkplace: source == .geofence || source == .notificationAction
        )

        let sessionData = entry.toWorkSessionData()
        return Task {
            NotificationManager.shared.clearConfirmationRequests()
            if let sessionData {
                await LiveActivities.updateActivity(with: sessionData)
            }
            if notify {
                await NotificationManager.shared.sendBreakStartedConfirmation(at: date)
            }
        }
    }

    /// Ends the break in progress on the active session. Returns `nil` when
    /// there is no open break.
    @discardableResult
    func endBreak(at date: Date = .now, source: Source, notify: Bool = false) -> Task<Void, Never>? {
        // `breakTimes` is an unordered SwiftData relationship, so find the
        // open break explicitly rather than relying on `.last`.
        guard let entry = activeEntry(),
              entry.isOnBreak,
              let openBreak = (entry.breakTimes ?? []).first(where: { $0.end == nil }) else {
            log("ClockService: No open break, ignoring break end from \(source)", prefix: "SHUN")
            return nil
        }

        openBreak.end = max(date, openBreak.start)
        entry.isOnBreak = false
        persist()

        log("ClockService: Ended break at \(date) from \(source)", prefix: "SHUN")

        GeofencingManager.shared.noteBreakEnded()

        let sessionData = entry.toWorkSessionData()
        return Task {
            NotificationManager.shared.clearConfirmationRequests()
            if let sessionData {
                await LiveActivities.updateActivity(with: sessionData)
            }
            if notify {
                await NotificationManager.shared.sendBreakEndedConfirmation(at: date)
            }
        }
    }

    // MARK: - Helpers

    private func persist() {
        do {
            try modelContext.save()
        } catch {
            log("ClockService: Error saving: \(error)", prefix: "SHUN")
        }
        modelContext.processPendingChanges()
        DataManager.shared.loadAll()
    }
}
