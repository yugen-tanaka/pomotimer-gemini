
import SwiftUI
import EventKit

struct TaskListView: View {
    @StateObject private var taskImporter = TaskImporter()
    @State private var reminderLists: [EKCalendar] = []
    @State private var selectedList: EKCalendar? = nil
    @State private var tasks: [Task] = []
    @Binding var selectedTask: Task?

    var body: some View {
        VStack {
            if reminderLists.isEmpty {
                Button("Request Access to Reminders") {
                    taskImporter.requestAccess { granted in
                        if granted {
                            SwiftUI.Task {
                                reminderLists = try await taskImporter.fetchReminderLists()
                            }
                        }
                    }
                }
            } else {
                Picker("Select Reminder List", selection: $selectedList) {
                    ForEach(reminderLists, id: \.self) { list in
                        Text(list.title).tag(list as EKCalendar?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedList) { newList in
                    guard let newList = newList else { return }
                    SwiftUI.Task {
                        tasks = try await taskImporter.fetchReminders(from: newList)
                    }
                }

                List(tasks, id: \.id) {
                    task in
                    Button(action: {
                        selectedTask = task
                    }) {
                        Text(task.title)
                    }
                }
            }
        }
        .onAppear {
            taskImporter.requestAccess { granted in
                if granted {
                    SwiftUI.Task {
                        reminderLists = try await taskImporter.fetchReminderLists()
                        if let firstList = reminderLists.first {
                            selectedList = firstList
                            tasks = try await taskImporter.fetchReminders(from: firstList)
                        }
                    }
                }
            }
        }
    }
}
