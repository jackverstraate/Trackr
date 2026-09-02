//
//  DurationFormat.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import Foundation

enum DurationFormat {
    /// Compact label such as "1h 23m", "45m", or "0m" for totals and rows.
    static func short(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int((seconds / 60).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    /// Stopwatch style "H:MM:SS" (or "MM:SS" under an hour) for the live timer readout.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
