//
//  PomoTimerDevApp.swift
//  PomoTimerDev
//
//  Created by 田中悠元 on 2025/08/14.
//

import SwiftUI

@main
struct PomoTimerDevApp: App {
    @StateObject private var calendarManager = CalendarManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarManager)
        }
    }
}
