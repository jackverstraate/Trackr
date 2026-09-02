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
