//
//  TrackrApp.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI
import SwiftData

@main
struct TrackrApp: App {
    /// The live stopwatch, shared across tabs so a running timer survives navigation.
    @State private var timer = StudyTimer()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudySession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(timer)
        }
        .modelContainer(sharedModelContainer)
    }
}
