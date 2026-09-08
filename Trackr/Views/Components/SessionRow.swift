//
//  SessionRow.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI

/// A single session as it appears in the Today and History lists.
struct SessionRow: View {
    let session: StudySession
    /// When true, shows the day/time; otherwise shows just the time (for day-grouped lists).
    var showsDate: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ActivityBadge(kind: session.kind)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(secondaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(DurationFormat.short(session.duration))
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    /// Immersion rows show the sub-type, e.g. "Active Immersion".
    private var title: String {
        if let style = session.immersionStyle {
            return "\(style.displayName) \(session.kind.displayName)"
        }
        return session.kind.displayName
    }

    private var secondaryLine: String {
        var parts: [String] = []
        if !session.note.isEmpty {
            parts.append(session.note)
        }
        parts.append(timeText)
        return parts.joined(separator: " · ")
    }

    private var timeText: String {
        if showsDate {
            return session.startDate.formatted(date: .abbreviated, time: .shortened)
        }
        return session.startDate.formatted(date: .omitted, time: .shortened)
    }
}
