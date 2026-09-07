//
//  ActivityKind.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI

/// The kind of language-learning activity a session represents.
enum ActivityKind: String, Codable, CaseIterable, Identifiable {
    case immersion
    case flashcards
    case written

    var id: String { rawValue }

    /// Human-readable name shown throughout the UI.
    var displayName: String {
        switch self {
        case .immersion: "Immersion"
        case .flashcards: "Flashcards"
        case .written: "Written"
        }
    }

    /// A short description clarifying what the activity covers.
    var subtitle: String {
        switch self {
        case .immersion: "Listening & watching native content"
        case .flashcards: "Anki / SRS review"
        case .written: "Textbooks like RTK or Genki"
        }
    }

    /// SF Symbol used to represent the activity.
    var systemImage: String {
        switch self {
        case .immersion: "headphones"
        case .flashcards: "rectangle.on.rectangle.angled"
        case .written: "book"
        }
    }

    /// Accent color used for badges, charts, and progress.
    var tint: Color {
        switch self {
        case .immersion: .blue
        case .flashcards: .orange
        case .written: .green
        }
    }
}

/// A sub-type of immersion, tracked separately within the Immersion activity.
enum ImmersionStyle: String, Codable, CaseIterable, Identifiable {
    case active
    case passive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: "Active"
        case .passive: "Passive"
        }
    }
}

/// A leaf category used for insights, where immersion splits into its two styles.
/// Everything else maps one-to-one from `ActivityKind`.
enum StudyCategory: String, CaseIterable, Identifiable {
    case activeImmersion
    case passiveImmersion
    case flashcards
    case written

    var id: String { rawValue }

    /// Short label used in the chart legend.
    var shortName: String {
        switch self {
        case .activeImmersion: "Active"
        case .passiveImmersion: "Passive"
        case .flashcards: "Flashcards"
        case .written: "Written"
        }
    }

    /// Full label used in the breakdown rows.
    var displayName: String {
        switch self {
        case .activeImmersion: "Active Immersion"
        case .passiveImmersion: "Passive Immersion"
        case .flashcards: "Flashcards"
        case .written: "Written"
        }
    }

    var systemImage: String {
        switch self {
        case .activeImmersion: "headphones"
        case .passiveImmersion: "headphones"
        case .flashcards: "rectangle.on.rectangle.angled"
        case .written: "book"
        }
    }

    var tint: Color {
        switch self {
        case .activeImmersion: .blue
        case .passiveImmersion: .teal
        case .flashcards: .orange
        case .written: .green
        }
    }

    /// Maps a session to its leaf category. Legacy immersion sessions without a
    /// stored style are treated as Active.
    static func of(_ session: StudySession) -> StudyCategory {
        switch session.kind {
        case .immersion:
            let style = ImmersionStyle(rawValue: session.immersionStyleRaw) ?? .active
            return style == .active ? .activeImmersion : .passiveImmersion
        case .flashcards: return .flashcards
        case .written: return .written
        }
    }
}
