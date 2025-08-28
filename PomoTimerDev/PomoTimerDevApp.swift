//
//  PomoTimerDevApp.swift
//  PomoTimerDev
//
//  Created by 田中悠元 on 2025/08/14.
//

import SwiftUI
import UserNotifications

@main
struct PomoTimerDevApp: App {
    @StateObject private var calendarManager = CalendarManager()

    init() {
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarManager)
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}
