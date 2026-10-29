import Foundation
import UserNotifications
struct ReadingReminderService {
    func schedule(hour: Int, minute: Int) async throws {
        let center = UNUserNotificationCenter.current()
        guard try await center.requestAuthorization(options: [.alert, .sound]) else { throw ReminderError.permissionDenied }
        center.removePendingNotificationRequests(withIdentifiers: ["daily-reading-reminder"])
        var date = DateComponents(); date.hour = hour; date.minute = minute
        let content = UNMutableNotificationContent(); content.title = "Time to read"; content.body = "A few pages today keep your reading streak going."; content.sound = .default
        try await center.add(UNNotificationRequest(identifier: "daily-reading-reminder", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: date, repeats: true)))
    }
    func cancel() { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-reading-reminder"]) }
}
enum ReminderError: LocalizedError { case permissionDenied; var errorDescription: String? { "Notifications are disabled. Enable them in Settings to receive reminders." } }
