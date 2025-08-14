import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @AppStorage("selectedCalendarIdentifier") private var selectedCalendarIdentifier: String = ""

    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
            
            // NavigationViewはStatisticsView内部のNavigationSplitViewに任せる
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar.xaxis")
                }
            
            // NavigationViewはSettingsView内部のNavigationSplitViewに任せる
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .task {
            // アプリ起動時にカレンダーへのアクセス許可を要求し、選択を復元する
            let granted = await calendarManager.requestAccess()
            if granted && !selectedCalendarIdentifier.isEmpty {
                calendarManager.selectedCalendar = calendarManager.calendar(withIdentifier: selectedCalendarIdentifier)
            }
        }
    }
}

struct TimerView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    // MARK: - Properties
    @AppStorage("timerRemaining") private var timerRemaining: TimeInterval = 25 * 60
    @AppStorage("isTimerRunning") private var isTimerRunning = false
    @AppStorage("timerMode") private var timerMode: TimerMode = .pomodoro
    @AppStorage("pomodoroCount") private var pomodoroCount = 0
    
    @State private var selectedTask: Task? = nil
    @State private var currentEventIdentifier: String? = nil

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body
    var body: some View {
        HSplitView {
            TaskListView(selectedTask: $selectedTask)
                .frame(minWidth: 200, maxWidth: .infinity)
            
            VStack(spacing: 20) {
                Text(modeText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let selectedTask {
                    Text("Current Task: \(selectedTask.title)")
                        .font(.title2)
                }

                Text(formattedTime)
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .padding(.vertical, 40)

                HStack(spacing: 15) {
                    Button(action: toggleTimer) {
                        Text(isTimerRunning ? "Stop" : "Start")
                            .font(.title2)
                            .frame(width: 100, height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isTimerRunning ? .red : .green)
                    .disabled(timerMode == .pomodoro && (selectedTask == nil || calendarManager.selectedCalendar == nil))

                    Button(action: resetTimer) {
                        Text("Reset")
                            .font(.title2)
                            .frame(width: 100, height: 50)
                    }
                    .buttonStyle(.bordered)
                }
                
                if timerMode == .pomodoro && calendarManager.selectedCalendar == nil {
                    Text("Please select a calendar in Settings to start.")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .frame(minWidth: 400, minHeight: 350)
            .onReceive(timer) { _ in
                guard isTimerRunning else { return }

                if timerRemaining > 0 {
                    timerRemaining -= 1
                } else {
                    isTimerRunning = false
                    switchMode()
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var modeText: String {
        switch timerMode {
        case .pomodoro: return "Pomodoro"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    private var formattedTime: String {
        let minutes = Int(timerRemaining) / 60
        let seconds = Int(timerRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Methods
    private func toggleTimer() {
        isTimerRunning.toggle()

        if isTimerRunning {
            if timerMode == .pomodoro, let task = selectedTask {
                SwiftUI.Task {
                    currentEventIdentifier = await calendarManager.startPomodoroSession(for: task)
                }
            }
        } else {
            if let eventId = currentEventIdentifier {
                let elapsedTime = (25 * 60) - timerRemaining
                SwiftUI.Task {
                    await calendarManager.endPomodoroSession(with: eventId, duration: elapsedTime)
                }
                currentEventIdentifier = nil
            }
        }
    }

    private func resetTimer() {
        if let eventId = currentEventIdentifier {
            let elapsedTime = (25 * 60) - timerRemaining
            SwiftUI.Task {
                await calendarManager.endPomodoroSession(with: eventId, duration: elapsedTime)
            }
            currentEventIdentifier = nil
        }
        
        isTimerRunning = false
        timerMode = .pomodoro
        timerRemaining = 25 * 60
        pomodoroCount = 0
    }

    private func switchMode() {
        if timerMode == .pomodoro, let eventId = currentEventIdentifier {
            let elapsedTime = 25 * 60.0
            SwiftUI.Task {
                await calendarManager.endPomodoroSession(with: eventId, duration: elapsedTime)
            }
            currentEventIdentifier = nil
        }

        if timerMode == .pomodoro {
            pomodoroCount += 1
            timerMode = (pomodoroCount % 4 == 0) ? .longBreak : .shortBreak
            timerRemaining = (timerMode == .longBreak) ? 15 * 60 : 5 * 60
        } else {
            timerMode = .pomodoro
            timerRemaining = 25 * 60
        }
    }
}

// タイマーのモードを定義する列挙型
enum TimerMode: String {
    case pomodoro
    case shortBreak
    case longBreak
}


#Preview {
    ContentView()
        .environmentObject(CalendarManager())
}
