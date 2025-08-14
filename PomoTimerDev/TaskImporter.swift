
import Foundation
import EventKit

class TaskImporter: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var tasks: [Task] = []

    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestFullAccessToReminders { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting access to reminders: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(granted)
            }
        }
    }

    func fetchReminders(from calendar: EKCalendar) async throws -> [Task] {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [calendar])

        let reminders = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EKReminder], Error>) in
            eventStore.fetchReminders(matching: predicate) { ekReminders in
                if let reminders = ekReminders {
                    continuation.resume(returning: reminders)
                } else {
                    struct FetchError: Error, LocalizedError {
                        var errorDescription: String? = "Failed to fetch reminders."
                    }
                    continuation.resume(throwing: FetchError())
                }
            }
        }
        
        return reminders.map { reminder in
            Task(id: reminder.calendarItemIdentifier, title: reminder.title, notes: reminder.notes)
        }
    }
    
    func fetchReminderLists() async throws -> [EKCalendar] {
        return eventStore.calendars(for: .reminder)
    }
}
