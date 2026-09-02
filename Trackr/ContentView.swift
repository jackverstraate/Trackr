//
//  ContentView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI
import SwiftData

/// Root tab bar. The system tab bar adopts Liquid Glass automatically on iOS 26.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "timer") {
                TodayView()
            }
            Tab("History", systemImage: "list.bullet") {
                HistoryView()
            }
            Tab("Insights", systemImage: "chart.bar.fill") {
                InsightsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(StudyTimer())
        .modelContainer(for: StudySession.self, inMemory: true)
}
