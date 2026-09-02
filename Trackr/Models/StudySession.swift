//
//  StudySession.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import Foundation
import SwiftData

/// A single logged block of study time.
@Model
final class StudySession {
    var id: UUID
    /// Raw value of `ActivityKind`. Stored as a string so `#Predicate` filtering stays reliable.
    var kindRaw: String
    var language: String
    var startDate: Date
    /// Length of the session in seconds.
    var duration: TimeInterval
    /// Optional material name or free-form note, e.g. "Genki 1 – Ch. 3".
    var note: String

    init(
        id: UUID = UUID(),
        kind: ActivityKind,
        language: String,
        startDate: Date,
        duration: TimeInterval,
        note: String = ""
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.language = language
        self.startDate = startDate
        self.duration = duration
        self.note = note
    }

    /// Typed accessor for the stored activity kind.
    var kind: ActivityKind {
        get { ActivityKind(rawValue: kindRaw) ?? .immersion }
        set { kindRaw = newValue.rawValue }
    }
}
