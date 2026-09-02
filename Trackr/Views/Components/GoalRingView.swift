//
//  GoalRingView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI

/// A circular progress ring showing today's study time against the daily goal.
/// When `goalMinutes` is zero, it shows the accumulated time without a target.
struct GoalRingView: View {
    let secondsToday: TimeInterval
    let goalMinutes: Int

    private var goalSeconds: TimeInterval { TimeInterval(goalMinutes) * 60 }

    private var progress: Double {
        guard goalSeconds > 0 else { return 0 }
        return min(secondsToday / goalSeconds, 1)
    }

    private var isComplete: Bool {
        goalSeconds > 0 && secondsToday >= goalSeconds
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.tint.opacity(0.15), lineWidth: 14)

            if goalMinutes > 0 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.tint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy, value: progress)
            }

            VStack(spacing: 2) {
                Text(DurationFormat.short(secondsToday))
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .monospacedDigit()
                if goalMinutes > 0 {
                    Text(isComplete ? "Goal reached" : "of \(DurationFormat.short(goalSeconds))")
                        .font(.caption)
                        .foregroundStyle(isComplete ? Color.green : .secondary)
                } else {
                    Text("today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 180, height: 180)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 40) {
        GoalRingView(secondsToday: 32 * 60, goalMinutes: 60)
        GoalRingView(secondsToday: 90 * 60, goalMinutes: 0)
    }
    .padding()
}
