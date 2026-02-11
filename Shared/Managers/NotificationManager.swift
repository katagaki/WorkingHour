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
        static let clockInReminder = "com.tsubuzaki.WorkingHour.clockInReminder"
        static let clockOutReminder = "com.tsubuzaki.WorkingHour.clockOutReminder"
    }

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Clock In Reminder

    func scheduleClockInReminder(at dateComponents: DateComponents) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Notification.ClockIn.Title")
        content.body = String(localized: "Notification.ClockIn.Body")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.clockInReminder,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func cancelClockInReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.clockInReminder])
    }

    // MARK: - Clock Out Reminder

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
}
