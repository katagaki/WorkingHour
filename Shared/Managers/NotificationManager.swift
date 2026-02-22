//
//  NotificationManager.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/11.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private enum Identifier {
        static let clockInReminderPrefix = "com.tsubuzaki.WorkingHour.clockInReminder"
        static let clockOutReminder = "com.tsubuzaki.WorkingHour.clockOutReminder"
        static let clockOutSnoozeReminder = "com.tsubuzaki.WorkingHour.clockOutSnoozeReminder"
    }

    private enum Action {
        static let snooze = "com.tsubuzaki.WorkingHour.action.snooze"
    }

    private enum Category {
        static let clockOutReminder = "com.tsubuzaki.WorkingHour.category.clockOutReminder"
    }

    // Number of days into the future to schedule weekday reminders.
    private let schedulingWindowDays = 30

    private override init() {
        super.init()
        center.delegate = self
        registerCategories()
    }

    private func registerCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: Action.snooze,
            title: String(localized: "Notification.Snooze"),
            options: []
        )
        let clockOutCategory = UNNotificationCategory(
            identifier: Category.clockOutReminder,
            actions: [snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([clockOutCategory])
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // Schedules clock-in reminders for every weekday in the next 30 days.
    func scheduleClockInReminders(at dateComponents: DateComponents) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        // Cancel any existing clock-in reminders before scheduling new ones
        await cancelClockInReminders()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.ClockIn.Title")
        content.body = String(localized: "Notification.ClockIn.Body")
        content.sound = .default

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

    // Cancels all pending clock-in reminders.
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

        // Cancel any existing clock-out reminders before scheduling new ones
        await cancelClockOutReminder()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.ClockOut.Title")
        content.body = String(localized: "Notification.ClockOut.Body")
        content.sound = .default
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
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == Action.snooze else { return }
        await scheduleSnoozeReminder()
    }

    private func scheduleSnoozeReminder() async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.ClockOut.Title")
        content.body = String(localized: "Notification.ClockOut.Body")
        content.sound = .default
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
