import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var stats: [TaskStat] = []
    @State private var selectedTimeframe: Timeframe = .today
    @State private var selectedTaskTitle: String? = nil

    // 期間選択の定義
    enum Timeframe: String, CaseIterable, Identifiable {
        case today = "Today"
        case week = "Past 7 Days"
        case month = "Past 30 Days"
        case allTime = "All Time"
        var id: Self { self }
    }

    var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar (Task List)
            VStack {
                timeframePicker
                taskList
            }
            .navigationTitle("Tasks")
        } detail: {
            // MARK: - Detail (Chart)
            VStack {
                if stats.isEmpty {
                    Text("No data for the selected period.")
                        .font(.title)
                        .foregroundColor(.secondary)
                } else {
                    chartView
                }
            }
            .navigationTitle("Time Spent")
        }
        .task(id: selectedTimeframe, loadStats) // 期間が変更されたら統計を再読み込み
    }

    // MARK: - Subviews
    
    private var timeframePicker: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases) { timeframe in
                Text(timeframe.rawValue).tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private var taskList: some View {
        List(stats, selection: $selectedTaskTitle) {
            stat in
            HStack {
                Text(stat.taskTitle)
                Spacer()
                Text(formatDuration(stat.totalDuration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var chartView: some View {
        Chart(stats) {
            stat in
            BarMark(
                x: .value("Minutes", stat.totalDuration / 60),
                y: .value("Task", stat.taskTitle)
            )
            .foregroundStyle(by: .value("Task", stat.taskTitle))
            // 選択されたタスク以外を半透明にする
            .opacity(selectedTaskTitle == nil || stat.taskTitle == selectedTaskTitle ? 1.0 : 0.3)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks {
                value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let minutes = value.as(Double.self) {
                        Text("\(Int(minutes)) min")
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Methods

    @Sendable
    private func loadStats() {
        SwiftUI.Task {
            let interval = selectedTimeframe.dateInterval
            stats = await calendarManager.fetchStats(for: interval)
            // 統計をリロードしたら選択を解除
            selectedTaskTitle = nil
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Timeframe Extension

extension StatisticsView.Timeframe {
    var dateInterval: DateInterval {
        let now = Date()
        let calendar = Calendar.current
        switch self {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return DateInterval(start: startOfDay, end: now)
        case .week:
            return DateInterval(start: calendar.date(byAdding: .day, value: -7, to: now)!, end: now)
        case .month:
            return DateInterval(start: calendar.date(byAdding: .day, value: -30, to: now)!, end: now)
        case .allTime:
            return DateInterval(start: .distantPast, end: now)
        }
    }
}

// MARK: - Preview

#Preview {
    StatisticsView()
        .environmentObject(CalendarManager())
}
