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
    /// Raw value of `ImmersionStyle` for immersion sessions; empty otherwise.
    /// Has a default so SwiftData can lightweight-migrate stores created before this property existed.
    var immersionStyleRaw: String = ""

    init(
        id: UUID = UUID(),
        kind: ActivityKind,
        language: String,
        startDate: Date,
        duration: TimeInterval,
        note: String = "",
        immersionStyle: ImmersionStyle? = nil
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.language = language
        self.startDate = startDate
        self.duration = duration
        self.note = note
        self.immersionStyleRaw = kind == .immersion ? (immersionStyle ?? .active).rawValue : ""
    }

    /// Typed accessor for the stored activity kind.
    var kind: ActivityKind {
        get { ActivityKind(rawValue: kindRaw) ?? .immersion }
        set { kindRaw = newValue.rawValue }
    }

    /// The immersion sub-type, or `nil` for non-immersion sessions.
    var immersionStyle: ImmersionStyle? {
        guard kind == .immersion else { return nil }
        return ImmersionStyle(rawValue: immersionStyleRaw) ?? .active
    }
}
