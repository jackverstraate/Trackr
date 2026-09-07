//
//  SampleData.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

#if DEBUG
import Foundation
import SwiftData

/// In-memory container seeded with sessions, used by SwiftUI previews.
@MainActor
enum SampleData {
    static let container: ModelContainer = {
        let container = try! ModelContainer(
            for: StudySession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        let samples: [(Int, ActivityKind, String, TimeInterval, String, ImmersionStyle?)] = [
            (0, .immersion, "Japanese", 45 * 60, "YouTube – vlog", .active),
            (0, .flashcards, "Japanese", 20 * 60, "Anki reviews", nil),
            (1, .written, "Japanese", 40 * 60, "Genki 1 – Ch. 3", nil),
            (1, .immersion, "Japanese", 30 * 60, "Podcast (background)", .passive),
            (2, .flashcards, "Korean", 15 * 60, "", nil),
            (3, .written, "Japanese", 50 * 60, "RTK", nil),
            (4, .immersion, "Japanese", 60 * 60, "Anime", .active),
            (4, .immersion, "Japanese", 25 * 60, "Music", .passive),
        ]

        for (dayOffset, kind, language, duration, note, style) in samples {
            let date = cal.date(byAdding: .day, value: -dayOffset, to: today.addingTimeInterval(9 * 3600))!
            container.mainContext.insert(
                StudySession(kind: kind, language: language, startDate: date, duration: duration, note: note, immersionStyle: style)
            )
        }
        return container
    }()
}
#endif
