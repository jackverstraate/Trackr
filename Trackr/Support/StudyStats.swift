//
//  StudyStats.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import Foundation

/// One day's total study time for a single activity, used by the Insights charts.
struct DailyActivityTotal: Identifiable {
    var id: String { "\(day.timeIntervalSince1970)-\(kind.rawValue)" }
    let day: Date
    let kind: ActivityKind
    let total: TimeInterval
}

/// Aggregate time for a single activity across a range, used for the breakdown.
struct ActivityTotal: Identifiable {
    var id: String { kind.rawValue }
    let kind: ActivityKind
    let total: TimeInterval
}

/// Pure aggregation helpers over collections of `StudySession`. Kept free of SwiftUI
/// and SwiftData so they stay simple and unit-testable.
enum StudyStats {
    /// Sum of all session durations.
    static func total(_ sessions: [StudySession]) -> TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    /// Sum of durations for sessions occurring on the given calendar day.
    static func total(on day: Date, in sessions: [StudySession], calendar: Calendar = .current) -> TimeInterval {
        total(sessions.filter { calendar.isDate($0.startDate, inSameDayAs: day) })
    }

    /// Totals per activity kind, always covering all three kinds (zero-filled).
    static func byActivity(_ sessions: [StudySession]) -> [ActivityTotal] {
        ActivityKind.allCases.map { kind in
            ActivityTotal(kind: kind, total: total(sessions.filter { $0.kind == kind }))
        }
    }

    /// Per-day, per-activity totals for the last `days` days ending on `endDay`.
    /// Every day in the window is represented so charts render a continuous axis.
    static func perDay(
        _ sessions: [StudySession],
        days: Int,
        endingOn endDay: Date = .now,
        calendar: Calendar = .current
    ) -> [DailyActivityTotal] {
        let end = calendar.startOfDay(for: endDay)
        var result: [DailyActivityTotal] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: end) else { continue }
            let daySessions = sessions.filter { calendar.isDate($0.startDate, inSameDayAs: day) }
            for kind in ActivityKind.allCases {
                let dayTotal = total(daySessions.filter { $0.kind == kind })
                result.append(DailyActivityTotal(day: day, kind: kind, total: dayTotal))
            }
        }
        return result
    }

    /// Sessions whose start date falls within the last `days` days ending on `endDay`.
    static func sessions(
        _ sessions: [StudySession],
        inLast days: Int,
        endingOn endDay: Date = .now,
        calendar: Calendar = .current
    ) -> [StudySession] {
        let end = calendar.startOfDay(for: endDay)
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) else { return sessions }
        return sessions.filter { $0.startDate >= start }
    }

    /// First moment of the month containing `date`.
    static func startOfMonth(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? calendar.startOfDay(for: date)
    }

    /// Per-month, per-activity totals for the last `months` months ending in the current month.
    /// Each bucket's `day` is the first of that month, so charts can plot by `.month`.
    static func perMonth(
        _ sessions: [StudySession],
        months: Int,
        endingOn endDay: Date = .now,
        calendar: Calendar = .current
    ) -> [DailyActivityTotal] {
        guard months > 0 else { return [] }
        let currentMonth = startOfMonth(endDay, calendar: calendar)
        var result: [DailyActivityTotal] = []
        for offset in stride(from: months - 1, through: 0, by: -1) {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: currentMonth) else { continue }
            let monthSessions = sessions.filter { calendar.isDate($0.startDate, equalTo: monthStart, toGranularity: .month) }
            for kind in ActivityKind.allCases {
                let monthTotal = total(monthSessions.filter { $0.kind == kind })
                result.append(DailyActivityTotal(day: monthStart, kind: kind, total: monthTotal))
            }
        }
        return result
    }

    /// Sessions whose start date falls within the last `months` calendar months.
    static func sessions(
        _ sessions: [StudySession],
        inLastMonths months: Int,
        endingOn endDay: Date = .now,
        calendar: Calendar = .current
    ) -> [StudySession] {
        let currentMonth = startOfMonth(endDay, calendar: calendar)
        guard let start = calendar.date(byAdding: .month, value: -(months - 1), to: currentMonth) else { return sessions }
        return sessions.filter { $0.startDate >= start }
    }

    /// Number of calendar months from the earliest session's month through the current month (minimum 1).
    static func monthSpan(
        _ sessions: [StudySession],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        guard let earliest = sessions.map(\.startDate).min() else { return 1 }
        let from = startOfMonth(earliest, calendar: calendar)
        let to = startOfMonth(now, calendar: calendar)
        let months = calendar.dateComponents([.month], from: from, to: to).month ?? 0
        return max(months + 1, 1)
    }

    /// Number of consecutive days (ending today) that have at least one session.
    static func currentStreak(
        _ sessions: [StudySession],
        asOf today: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let studiedDays = Set(sessions.map { calendar.startOfDay(for: $0.startDate) })
        guard !studiedDays.isEmpty else { return 0 }

        var streak = 0
        var day = calendar.startOfDay(for: today)

        // Allow the streak to stand if today has no sessions yet but yesterday did.
        if !studiedDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  studiedDays.contains(yesterday) else { return 0 }
            day = yesterday
        }

        while studiedDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }
}
