//
//  NotificationManager.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/11.
//

import Foundation
import SwiftData
import UserNotifications

// swiftlint:disable type_body_length file_length
@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private enum Identifier {
        static let clockInReminderPrefix = "com.tsubuzaki.WorkingHour.clockInReminder"
        static let clockInConfirmation = "com.tsubuzaki.WorkingHour.clockInConfirmation"
        static let clockOutReminder = "com.tsubuzaki.WorkingHour.clockOutReminder"
        static let clockOutSnoozeReminder = "com.tsubuzaki.WorkingHour.clockOutSnoozeReminder"
        static let breakStartedConfirmation = "com.tsubuzaki.WorkingHour.breakStartedConfirmation"
        static let breakEndedConfirmation = "com.tsubuzaki.WorkingHour.breakEndedConfirmation"
        static let confirmClockIn = "com.tsubuzaki.WorkingHour.confirmClockInRequest"
        static let confirmClockOut = "com.tsubuzaki.WorkingHour.confirmClockOutRequest"
        static let confirmBreakStart = "com.tsubuzaki.WorkingHour.confirmBreakStartRequest"
        static let confirmBreakEnd = "com.tsubuzaki.WorkingHour.confirmBreakEndRequest"
        static let breakStartReminderPrefix = "com.tsubuzaki.WorkingHour.breakStartReminder"
        static let breakEndReminderPrefix = "com.tsubuzaki.WorkingHour.breakEndReminder"

        static let allConfirmationRequests = [
            confirmClockIn, confirmClockOut, confirmBreakStart, confirmBreakEnd
        ]
    }

    private enum Action {
        static let snooze = "com.tsubuzaki.WorkingHour.action.snooze"
        static let clockIn = "com.tsubuzaki.WorkingHour.action.clockIn"
        static let clockOut = "com.tsubuzaki.WorkingHour.action.clockOut"
        static let startBreak = "com.tsubuzaki.WorkingHour.action.startBreak"
        static let endBreak = "com.tsubuzaki.WorkingHour.action.endBreak"
    }

    private enum Category {
        static let clockOutReminder = "com.tsubuzaki.WorkingHour.category.clockOutReminder"
        static let confirmClockIn = "com.tsubuzaki.WorkingHour.category.confirmClockIn"
        static let confirmClockOut = "com.tsubuzaki.WorkingHour.category.confirmClockOut"
        static let confirmBreakStart = "com.tsubuzaki.WorkingHour.category.confirmBreakStart"
        static let confirmBreakEnd = "com.tsubuzaki.WorkingHour.category.confirmBreakEnd"
    }

    private enum UserInfoKey {
        static let hintDate = "hintDate"
    }

    /// A request for the user to confirm a clock action that geofencing could
    /// not verify automatically (e.g. because GPS was weak).
    enum ConfirmationRequest {
        case clockIn
        case clockOut
        case breakStart
        case breakEnd
    }

    // Number of days into the future to schedule weekday reminders.
    private let schedulingWindowDays = 30

    private override init() {
        super.init()
        center.delegate = self
        registerCategories()
    }

    private func registerCategories() {
        let clockInAction = makeAction(Action.clockIn, titled: "Notification.Action.ClockIn")
        let clockOutAction = makeAction(Action.clockOut, titled: "Notification.Action.ClockOut")
        let startBreakAction = makeAction(Action.startBreak, titled: "Notification.Action.StartBreak")
        let endBreakAction = makeAction(Action.endBreak, titled: "Notification.Action.EndBreak")
        let snoozeAction = makeAction(Action.snooze, titled: "Notification.Snooze")

        center.setNotificationCategories([
            makeCategory(Category.clockOutReminder, actions: [snoozeAction]),
            makeCategory(Category.confirmClockIn, actions: [clockInAction]),
            makeCategory(Category.confirmClockOut, actions: [clockOutAction]),
            makeCategory(Category.confirmBreakStart, actions: [startBreakAction, clockOutAction]),
            makeCategory(Category.confirmBreakEnd, actions: [endBreakAction])
        ])
    }

    private func makeAction(_ identifier: String, titled titleKey: String.LocalizationValue) -> UNNotificationAction {
        UNNotificationAction(
            identifier: identifier,
            title: String(localized: titleKey),
            options: []
        )
    }

    private func makeCategory(_ identifier: String, actions: [UNNotificationAction]) -> UNNotificationCategory {
        UNNotificationCategory(
            identifier: identifier,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    func sendClockInConfirmation(at clockInTime: Date) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.ClockedIn.Title")
        content.body = String(localized: "Notification.ClockedIn.Body \(timeFormatter.string(from: clockInTime))")
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: Identifier.clockInConfirmation,
            content: content,
            trigger: nil
        )

        try? await center.add(request)
    }

    func sendBreakStartedConfirmation(at time: Date) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.BreakStarted.Title")
        content.body = String(localized: "Notification.BreakStarted.Body \(timeFormatter.string(from: time))")
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: Identifier.breakStartedConfirmation,
            content: content,
            trigger: nil
        )

        try? await center.add(request)
    }

    func sendBreakEndedConfirmation(at time: Date) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.BreakEnded.Title")
        content.body = String(localized: "Notification.BreakEnded.Body \(timeFormatter.string(from: time))")
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: Identifier.breakEndedConfirmation,
            content: content,
            trigger: nil
        )

        try? await center.add(request)
    }

    // MARK: - Confirmation Requests

    /// Asks the user to confirm a clock action that automatic geofencing could
    /// not verify (e.g. weak GPS at the fence boundary). Acting on the
    /// notification records the action at `hintDate` — the time the region
    /// event actually happened.
    func sendConfirmationRequest(_ kind: ConfirmationRequest, hintDate: Date) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: hintDate)

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = [UserInfoKey.hintDate: hintDate.timeIntervalSince1970]

        let identifier: String
        switch kind {
        case .clockIn:
            content.title = String(localized: "Notification.ConfirmClockIn.Title")
            content.body = String(localized: "Notification.ConfirmClockIn.Body \(timeString)")
            content.categoryIdentifier = Category.confirmClockIn
            identifier = Identifier.confirmClockIn
        case .clockOut:
            content.title = String(localized: "Notification.ConfirmClockOut.Title")
            content.body = String(localized: "Notification.ConfirmClockOut.Body \(timeString)")
            content.categoryIdentifier = Category.confirmClockOut
            identifier = Identifier.confirmClockOut
        case .breakStart:
            content.title = String(localized: "Notification.ConfirmBreakStart.Title")
            content.body = String(localized: "Notification.ConfirmBreakStart.Body \(timeString)")
            content.categoryIdentifier = Category.confirmBreakStart
            identifier = Identifier.confirmBreakStart
        case .breakEnd:
            content.title = String(localized: "Notification.ConfirmBreakEnd.Title")
            content.body = String(localized: "Notification.ConfirmBreakEnd.Body \(timeString)")
            content.categoryIdentifier = Category.confirmBreakEnd
            identifier = Identifier.confirmBreakEnd
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        try? await center.add(request)
    }

    /// Removes any outstanding confirmation requests. Called whenever the
    /// clock state changes so the user is never asked about a stale event.
    func clearConfirmationRequests() {
        center.removePendingNotificationRequests(withIdentifiers: Identifier.allConfirmationRequests)
        center.removeDeliveredNotifications(withIdentifiers: Identifier.allConfirmationRequests)
    }

    // MARK: - Break Window Reminders

    /// Re-schedules the "break about to start/end" reminders to match the
    /// current settings and enabled break windows. Reminders fire 15 minutes
    /// before a window boundary on weekdays, using weekly repeating triggers
    /// (one per weekday) so they never decay and stay far below the system's
    /// 64 pending notification limit.
    func refreshBreakReminders() async {
        await cancelBreakReminders()

        let settings = SettingsManager.shared
        guard settings.breakStartReminderEnabled || settings.breakEndReminderEnabled else { return }

        let authorized = await requestAuthorization()
        guard authorized else { return }

        let context = SharedModelContainer.shared.container.mainContext
        let descriptor = FetchDescriptor<BreakWindow>(
            predicate: #Predicate { $0.isEnabled }
        )
        guard let windows = try? context.fetch(descriptor), !windows.isEmpty else { return }

        for window in windows {
            if settings.breakStartReminderEnabled {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "Notification.BreakStartingSoon.Title")
                content.body = String(
                    localized: "Notification.BreakStartingSoon.Body \(timeString(secondsSinceMidnight: window.startSeconds))"
                )
                content.sound = .default
                content.interruptionLevel = .timeSensitive
                await scheduleWeekdayReminders(
                    identifierPrefix: Identifier.breakStartReminderPrefix,
                    windowId: window.id,
                    boundarySeconds: window.startSeconds,
                    content: content
                )
            }
            if settings.breakEndReminderEnabled {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "Notification.BreakEndingSoon.Title")
                content.body = String(
                    localized: "Notification.BreakEndingSoon.Body \(timeString(secondsSinceMidnight: window.endSeconds))"
                )
                content.sound = .default
                content.interruptionLevel = .timeSensitive
                await scheduleWeekdayReminders(
                    identifierPrefix: Identifier.breakEndReminderPrefix,
                    windowId: window.id,
                    boundarySeconds: window.endSeconds,
                    content: content
                )
            }
        }
    }

    func cancelBreakReminders() async {
        let pendingRequests = await center.pendingNotificationRequests()
        let identifiers = pendingRequests
            .map(\.identifier)
            .filter {
                $0.hasPrefix(Identifier.breakStartReminderPrefix)
                || $0.hasPrefix(Identifier.breakEndReminderPrefix)
            }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Schedules a weekly repeating reminder for every weekday, firing
    /// 15 minutes before `boundarySeconds` (seconds since midnight).
    private func scheduleWeekdayReminders(
        identifierPrefix: String,
        windowId: String,
        boundarySeconds: Int,
        content: UNNotificationContent
    ) async {
        let reminderSeconds = boundarySeconds - 15 * 60
        // Wrap boundaries within the first 15 minutes of the day into the
        // previous evening.
        let normalized = ((reminderSeconds % 86400) + 86400) % 86400

        var components = DateComponents()
        components.hour = normalized / 3600
        components.minute = (normalized % 3600) / 60

        // Weekdays only: 2 = Monday ... 6 = Friday.
        for weekday in 2...6 {
            components.weekday = weekday
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(identifierPrefix).\(windowId).w\(weekday)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private func timeString(secondsSinceMidnight seconds: Int) -> String {
        var components = DateComponents()
        components.hour = seconds / 3600
        components.minute = (seconds % 3600) / 60
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // Schedules clock-in reminders for every weekday in the next 30 days.
    func scheduleClockInReminders(at dateComponents: DateComponents) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        await cancelClockInReminders()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.ClockIn.Title")
        content.body = String(localized: "Notification.ClockIn.Body")
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        for dayOffset in 0..<schedulingWindowDays {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            let weekday = calendar.component(.weekday, from: targetDate)
            // Skip weekends: 1 = Sunday, 7 = Saturday
            guard weekday >= 2 && weekday <= 6 else { continue }

            var triggerComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
            triggerComponents.hour = dateComponents.hour
            triggerComponents.minute = dateComponents.minute

            // Skip if the trigger time is already in the past
            if let triggerDate = calendar.date(from: triggerComponents), triggerDate <= Date() {
                continue
            }

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            let dateString = formatDateForIdentifier(targetDate)
            let identifier = "\(Identifier.clockInReminderPrefix).\(dateString)"

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    func cancelClockInReminders() async {
        let pendingRequests = await center.pendingNotificationRequests()
        let clockInIdentifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(Identifier.clockInReminderPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: clockInIdentifiers)
    }

    // Schedules clock-out reminders for every weekday in the next 30 days.
    func scheduleClockOutReminder(at dateComponents: DateComponents) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        await cancelClockOutReminder()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.ClockOut.Title")
        content.body = String(localized: "Notification.ClockOut.Body")
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = Category.clockOutReminder

        for dayOffset in 0..<schedulingWindowDays {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            let weekday = calendar.component(.weekday, from: targetDate)
            // Skip weekends: 1 = Sunday, 7 = Saturday
            guard weekday >= 2 && weekday <= 6 else { continue }

            var triggerComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
            triggerComponents.hour = dateComponents.hour
            triggerComponents.minute = dateComponents.minute

            // Skip if the trigger time is already in the past
            if let triggerDate = calendar.date(from: triggerComponents), triggerDate <= Date() {
                continue
            }

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            let dateString = formatDateForIdentifier(targetDate)
            let identifier = "\(Identifier.clockOutReminder).\(dateString)"

            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    func cancelClockOutReminder() async {
        let pendingRequests = await center.pendingNotificationRequests()
        let clockOutIdentifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(Identifier.clockOutReminder) }
        center.removePendingNotificationRequests(withIdentifiers: clockOutIdentifiers)
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        let hintTimestamp = userInfo[UserInfoKey.hintDate] as? TimeInterval
        Task { @MainActor in
            // Record the action at the time the region event happened, unless
            // the notification sat unactioned for so long that backdating
            // would be misleading.
            var actionDate = Date.now
            if let hintTimestamp {
                let hintDate = Date(timeIntervalSince1970: hintTimestamp)
                if Date.now.timeIntervalSince(hintDate) < 4 * 3600 {
                    actionDate = hintDate
                }
            }

            switch actionIdentifier {
            case Action.snooze:
                await self.scheduleSnoozeReminder()
            case Action.clockIn:
                await ClockService.shared.clockIn(at: actionDate, source: .notificationAction)?.value
            case Action.clockOut:
                await ClockService.shared.clockOut(at: actionDate, source: .notificationAction)?.value
            case Action.startBreak:
                await ClockService.shared.startBreak(at: actionDate, source: .notificationAction)?.value
            case Action.endBreak:
                await ClockService.shared.endBreak(at: actionDate, source: .notificationAction)?.value
            default:
                break
            }
            completionHandler()
        }
    }

    private func scheduleSnoozeReminder() async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.ClockOut.Title")
        content.body = String(localized: "Notification.ClockOut.Body")
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = Category.clockOutReminder

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifier.clockOutSnoozeReminder,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    private func formatDateForIdentifier(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
// swiftlint:enable type_body_length file_length
