import SwiftUI

//
//  ContentView.swift
//  PomoTimerDev
//
//  Created by 田中悠元 on 2025/08/14.
//

import SwiftUI
import Combine

// タイマーのモードを定義する列挙型
enum TimerMode {
    case pomodoro
    case shortBreak
    case longBreak
}

struct ContentView: View {
    // MARK: - Properties

    // タイマーの残り時間（秒）
    @State private var timerRemaining: TimeInterval = 25 * 60
    // タイマーが動作中かどうか
    @State private var isTimerRunning = false
    // 現在のタイマーモード
    @State private var timerMode: TimerMode = .pomodoro
    // ポモドーロの完了回数
    @State private var pomodoroCount = 0

    // 1秒ごとにイベントを発行するタイマー
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー：現在のモードを表示
            Text(modeText)
                .font(.largeTitle)
                .fontWeight(.bold)

            // 残り時間を表示するテキスト
            Text(formattedTime)
                .font(.system(size: 80, weight: .bold, design: .monospaced))
                .padding(.vertical, 40)

            // 操作ボタン
            HStack(spacing: 15) {
                // 開始・停止ボタン
                Button(action: toggleTimer) {
                    Text(isTimerRunning ? "停止" : "開始")
                        .font(.title2)
                        .frame(width: 100, height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(isTimerRunning ? .red : .green)

                // リセットボタン
                Button(action: resetTimer) {
                    Text("リセット")
                        .font(.title2)
                        .frame(width: 100, height: 50)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 350)
        .onReceive(timer) { _ in
            // タイマーが動作中の場合のみ時間を減らす
            guard isTimerRunning else { return }

            if timerRemaining > 0 {
                timerRemaining -= 1
            } else {
                // 時間が0になったらタイマーを停止し、モードを切り替える
                isTimerRunning = false
                switchMode()
            }
        }
    }

    // MARK: - Computed Properties

    // 現在のモードに応じたテキスト
    private var modeText: String {
        switch timerMode {
        case .pomodoro:
            return "ポモドーロ"
        case .shortBreak:
            return "短い休憩"
        case .longBreak:
            return "長い休憩"
        }
    }

    // 残り時間を "mm:ss" 形式の文字列にフォーマット
    private var formattedTime: String {
        let minutes = Int(timerRemaining) / 60
        let seconds = Int(timerRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Methods

    // 開始・停止ボタンのアクション
    private func toggleTimer() {
        isTimerRunning.toggle()
    }

    // リセットボタンのアクション
    private func resetTimer() {
        isTimerRunning = false
        timerMode = .pomodoro
        timerRemaining = 25 * 60
        pomodoroCount = 0
    }

    // モードを切り替える
    private func switchMode() {
        if timerMode == .pomodoro {
            pomodoroCount += 1
            // 4回目のポモドーロ後は長い休憩
            if pomodoroCount % 4 == 0 {
                timerMode = .longBreak
                timerRemaining = 15 * 60
            } else {
                // それ以外は短い休憩
                timerMode = .shortBreak
                timerRemaining = 5 * 60
            }
        } else {
            // 休憩後はポモドーロに戻る
            timerMode = .pomodoro
            timerRemaining = 25 * 60
        }
        // モードが切り替わったら自動でタイマーを開始する
        isTimerRunning = true
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}