//
//  InsightsView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI
import SwiftData
import Charts

/// Charts and summary stats: time per day, streak, goal, and per-activity breakdown.
struct InsightsView: View {
    @AppStorage(SettingsKey.dailyGoalMinutes) private var goalMinutes = 0
    @Query(sort: \StudySession.startDate, order: .reverse) private var allSessions: [StudySession]

    @State private var range: Range = .week

    enum Range: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        var id: String { rawValue }
        var days: Int { self == .week ? 7 : 30 }
    }

    private var rangeSessions: [StudySession] {
        StudyStats.sessions(allSessions, inLast: range.days)
    }

    private var dailyTotals: [DailyActivityTotal] {
        StudyStats.perDay(allSessions, days: range.days)
    }

    private var activityTotals: [ActivityTotal] {
        StudyStats.byActivity(rangeSessions)
    }

    private var rangeTotal: TimeInterval {
        StudyStats.total(rangeSessions)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Range", selection: $range) {
                        ForEach(Range.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    HStack(spacing: 12) {
                        statCard(
                            title: "Streak",
                            value: "\(StudyStats.currentStreak(allSessions))",
                            unit: "days",
                            icon: "flame.fill",
                            tint: .orange
                        )
                        statCard(
                            title: range.rawValue,
                            value: DurationFormat.short(rangeTotal),
                            unit: "total",
                            icon: "clock.fill",
                            tint: .blue
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Time per Day") {
                    chart
                        .frame(height: 220)
                        .padding(.vertical, 8)
                }

                Section("By Activity") {
                    if rangeTotal <= 0 {
                        Text("No sessions in this range.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(activityTotals) { item in
                            breakdownRow(item)
                        }
                    }
                }

                Section("Daily Goal") {
                    Stepper(
                        goalMinutes > 0 ? "\(goalMinutes) minutes" : "No goal set",
                        value: $goalMinutes,
                        in: 0...600,
                        step: 15
                    )
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var chart: some View {
        Chart(dailyTotals) { item in
            BarMark(
                x: .value("Day", item.day, unit: .day),
                y: .value("Minutes", item.total / 60)
            )
            .foregroundStyle(by: .value("Activity", item.kind.displayName))
        }
        .chartForegroundStyleScale([
            ActivityKind.immersion.displayName: ActivityKind.immersion.tint,
            ActivityKind.flashcards.displayName: ActivityKind.flashcards.tint,
            ActivityKind.written.displayName: ActivityKind.written.tint,
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: range == .week ? 1 : 5)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
            }
        }
        .chartLegend(position: .bottom)
    }

    private func statCard(title: String, value: String, unit: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(tint)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: .rect(cornerRadius: 16))
    }

    private func breakdownRow(_ item: ActivityTotal) -> some View {
        let fraction = rangeTotal > 0 ? item.total / rangeTotal : 0
        return VStack(spacing: 6) {
            HStack {
                ActivityBadge(kind: item.kind, size: 32)
                Text(item.kind.displayName)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(DurationFormat.short(item.total))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.kind.tint)
                    .frame(width: 44, alignment: .trailing)
            }
            ProgressView(value: fraction)
                .tint(item.kind.tint)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: StudySession.self, inMemory: true)
}
