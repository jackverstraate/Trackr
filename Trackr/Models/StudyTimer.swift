//
//  StudyTimer.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import Foundation

/// Drives the live start/pause/stop stopwatch on the Today screen.
///
/// The timer holds only in-progress state; it never touches SwiftData. The Today
/// screen reads `elapsed(asOf:)` for display and creates a `StudySession` when the
/// user stops. It's injected once from the app so a running timer survives tab switches.
@Observable
@MainActor
final class StudyTimer {
    /// When the current running segment began, or `nil` while paused/stopped.
    private(set) var startDate: Date?
    /// Time accumulated from previous running segments before the current pause.
    private(set) var accumulated: TimeInterval = 0

    /// The activity being timed. Editable while the timer is stopped.
    var selectedKind: ActivityKind = .immersion
    /// The immersion sub-type, used only when `selectedKind` is `.immersion`.
    var selectedImmersionStyle: ImmersionStyle = .active
    /// The language being studied. Editable while the timer is stopped.
    var selectedLanguage: String = ""

    /// Whether the stopwatch is actively counting.
    var isRunning: Bool { startDate != nil }

    /// Whether any time has been recorded (running or paused with accumulated time).
    var isActive: Bool { isRunning || accumulated > 0 }

    /// Total elapsed time as of the given moment.
    func elapsed(asOf now: Date = .now) -> TimeInterval {
        guard let startDate else { return accumulated }
        return accumulated + now.timeIntervalSince(startDate)
    }

    /// Begins counting from zero.
    func start() {
        accumulated = 0
        startDate = .now
    }

    /// Pauses counting, banking the elapsed time.
    func pause() {
        guard let startDate else { return }
        accumulated += Date.now.timeIntervalSince(startDate)
        self.startDate = nil
    }

    /// Resumes counting after a pause.
    func resume() {
        guard startDate == nil else { return }
        startDate = .now
    }

    /// Toggles between running and paused.
    func toggle() {
        if isRunning {
            pause()
        } else if isActive {
            resume()
        } else {
            start()
        }
    }

    /// Clears all recorded time.
    func reset() {
        startDate = nil
        accumulated = 0
    }
}
