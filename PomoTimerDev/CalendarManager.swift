import Foundation
import EventKit
import SwiftUI

/// タスクごとの統計データを表す構造体
struct TaskStat: Identifiable {
    let id = UUID()
    let taskTitle: String
    let totalDuration: TimeInterval
}

@MainActor
class CalendarManager: ObservableObject {
    let eventStore = EKEventStore()
    
    // ユーザーによって選択されたカレンダー
    @Published var selectedCalendar: EKCalendar?

    // MARK: - Public Methods

    /// イベントへのアクセス許可を要求する
    func requestAccess() async -> Bool {
        do {
            // macOS 14以降、.eventへのアクセス許可はリマインダーも含む
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            print("Error requesting calendar access: \(error.localizedDescription)")
            return false
        }
    }

    /// 書き込み可能なカレンダーのリストを取得する
    func fetchWritableCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    }
    
    /// 識別子に一致するカレンダーを取得する
    func calendar(withIdentifier identifier: String) -> EKCalendar? {
        return eventStore.calendar(withIdentifier: identifier)
    }

    /// ポモドーロセッションの開始を記録する
    func startPomodoroSession(for task: Task) async -> String? {
        guard let calendar = self.selectedCalendar else {
            print("Cannot start session: No calendar selected.")
            return nil
        }

        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.calendar = calendar
        newEvent.title = task.title
        newEvent.startDate = Date()
        newEvent.endDate = Date().addingTimeInterval(60) // Placeholder end date

        return await SwiftUI.Task.detached {
            do {
                try self.eventStore.save(newEvent, span: .thisEvent, commit: true)
                print("Saved new event with ID: \(newEvent.eventIdentifier ?? "N/A")")
                return newEvent.eventIdentifier
            } catch {
                print("Error saving new event: \(error.localizedDescription)")
                return nil
            }
        }.value
    }

    /// ポモドーロセッションの終了を記録する
    func endPomodoroSession(with eventIdentifier: String, duration: TimeInterval) async {
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            print("Event with ID \(eventIdentifier) not found.")
            return
        }

        event.endDate = event.startDate.addingTimeInterval(duration)

        SwiftUI.Task.detached {
            do {
                try self.eventStore.save(event, span: .thisEvent, commit: true)
                print("Updated event \(event.title ?? "") to end at \(event.endDate ?? Date())")
            } catch {
                print("Error updating event: \(error.localizedDescription)")
            }
        }
    }
    
    /// 指定された期間のポモドーロ統計を取得する
    func fetchStats(for interval: DateInterval) async -> [TaskStat] {
        guard let calendar = self.selectedCalendar else {
            print("Cannot fetch stats: No calendar selected.")
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: interval.start, end: interval.end, calendars: [calendar])
        
        do {
            let events = try await eventStore.events(matching: predicate)
            
            let statsDictionary = Dictionary(grouping: events, by: { $0.title ?? "Untitled" })
                .mapValues { events in
                    events.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                }
            
            return statsDictionary.map { (title, duration) in
                TaskStat(taskTitle: title, totalDuration: duration)
            }.sorted { $0.totalDuration > $1.totalDuration }
            
        } catch {
            print("Error fetching events for stats: \(error.localizedDescription)")
            return []
        }
    }
}
