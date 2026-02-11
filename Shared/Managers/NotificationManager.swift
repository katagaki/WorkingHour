//
//  NotificationManager.swift
//  WorkingHour
//
//  Created by Assistant on 2026/02/11.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private enum Identifier {
        static let clockInReminderPrefix = "com.tsubuzaki.WorkingHour.clockInReminder"
        static let clockOutReminder = "com.tsubuzaki.WorkingHour.clockOutReminder"
    }

    // Number of days into the future to schedule weekday reminders.
    private let schedulingWindowDays = 30

    private init() {}

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

    func scheduleClockOutReminder(at dateComponents: DateComponents) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.ClockOut.Title")
        content.body = String(localized: "Notification.ClockOut.Body")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.clockOutReminder,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func cancelClockOutReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.clockOutReminder])
    }

    private func formatDateForIdentifier(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
