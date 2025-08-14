import SwiftUI
import EventKit

// 設定項目のカテゴリを定義
private enum SettingsCategory: String, CaseIterable, Hashable, Identifiable {
    case calendar = "Calendar"
    // 将来的に他の設定項目をここに追加
    // case appearance = "Appearance"
    
    var id: Self { self }
    
    @ViewBuilder
    var destination: some View {
        switch self {
        case .calendar:
            CalendarSettingsView()
        }
    }
    
    var label: some View {
        switch self {
        case .calendar:
            Label("Calendar", systemImage: "calendar")
        }
    }
}

// メインの設定画面
struct SettingsView: View {
    @State private var selectedCategory: SettingsCategory? = .calendar
    
    var body: some View {
        NavigationSplitView {
            List(SettingsCategory.allCases, selection: $selectedCategory) {
                category in
                NavigationLink(value: category) {
                    category.label
                }
            }
            .navigationTitle("Settings")
        } detail: {
            if let category = selectedCategory {
                category.destination
            } else {
                Text("Select a category")
            }
        }
    }
}

// カレンダー設定の詳細ビュー
private struct CalendarSettingsView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @AppStorage("selectedCalendarIdentifier") private var selectedCalendarIdentifier: String = ""
    
    @State private var calendars: [EKCalendar] = []
    
    var body: some View {
        Form {
            Section(header: Text("Recording Calendar")) {
                if calendars.isEmpty {
                    Text("No writable calendars found.")
                } else {
                    Picker("Select Calendar", selection: $selectedCalendarIdentifier) {
                        ForEach(calendars, id: \.calendarIdentifier) { calendar in
                            HStack {
                                Circle()
                                    .fill(Color(calendar.cgColor))
                                    .frame(width: 10, height: 10)
                                Text(calendar.title)
                            }
                            .tag(calendar.calendarIdentifier)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding()
        .navigationTitle(SettingsCategory.calendar.rawValue)
        .onAppear(perform: loadCalendars)
        .onChange(of: selectedCalendarIdentifier, perform: updateCalendarSelection)
    }
    
    private func loadCalendars() {
        calendars = calendarManager.fetchWritableCalendars()
        if selectedCalendarIdentifier.isEmpty, let firstCalendar = calendars.first {
            selectedCalendarIdentifier = firstCalendar.calendarIdentifier
        }
        updateCalendarSelection(identifier: selectedCalendarIdentifier)
    }
    
    private func updateCalendarSelection(identifier: String) {
        if !identifier.isEmpty {
            calendarManager.selectedCalendar = calendarManager.calendar(withIdentifier: identifier)
        }
    }
}


#Preview {
    SettingsView()
        .environmentObject(CalendarManager())
}