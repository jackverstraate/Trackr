//
//  InsightsView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI
import SwiftData
import Charts

/// Charts and summary stats: time per period, streak, goal, and per-activity breakdown.
struct InsightsView: View {
    @AppStorage(SettingsKey.dailyGoalMinutes) private var goalMinutes = 0
    @Query(sort: \StudySession.startDate, order: .reverse) private var allSessions: [StudySession]

    @State private var range: Range = .week
    @State private var showingSettings = false

    enum Range: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All"
        var id: String { rawValue }

        /// Longer label used in the total card ("All" → "All Time").
        var displayName: String { self == .all ? "All Time" : rawValue }

        /// Whether the chart buckets by month (Year, All Time) rather than by day.
        var isMonthly: Bool { self == .year || self == .all }
    }

    /// Sessions that fall inside the selected range.
    private var rangeSessions: [StudySession] {
        switch range {
        case .week: StudyStats.sessions(allSessions, inLast: 7)
        case .month: StudyStats.sessions(allSessions, inLast: 30)
        case .year: StudyStats.sessions(allSessions, inLastMonths: 12)
        case .all: allSessions
        }
    }

    /// Per-bucket, per-category totals used by the chart (daily or monthly buckets).
    private var chartTotals: [DailyCategoryTotal] {
        switch range {
        case .week: StudyStats.perDay(allSessions, days: 7)
        case .month: StudyStats.perDay(allSessions, days: 30)
        case .year: StudyStats.perMonth(allSessions, months: 12)
        case .all: StudyStats.perMonth(allSessions, months: StudyStats.monthSpan(allSessions))
        }
    }

    /// Number of buckets currently plotted (used to space the x-axis for All Time).
    private var bucketCount: Int {
        chartTotals.count / max(StudyCategory.allCases.count, 1)
    }

    private var categoryTotals: [CategoryTotal] {
        StudyStats.byCategory(rangeSessions)
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
                            title: range.displayName,
                            value: DurationFormat.short(rangeTotal),
                            unit: "total",
                            icon: "clock.fill",
                            tint: .blue
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section(range.isMonthly ? "Time per Month" : "Time per Day") {
                    chart
                        .frame(height: 220)
                        .padding(.vertical, 8)
                }

                Section("By Activity") {
                    if rangeTotal <= 0 {
                        Text("No sessions in this range.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categoryTotals) { item in
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Settings", systemImage: "gearshape") { showingSettings = true }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var chart: some View {
        Chart(chartTotals) { item in
            BarMark(
                x: .value("Period", item.day, unit: range.isMonthly ? .month : .day),
                y: .value("Minutes", item.total / 60)
            )
            .foregroundStyle(by: .value("Activity", item.category.shortName))
        }
        .chartForegroundStyleScale([
            StudyCategory.activeImmersion.shortName: StudyCategory.activeImmersion.tint,
            StudyCategory.passiveImmersion.shortName: StudyCategory.passiveImmersion.tint,
            StudyCategory.flashcards.shortName: StudyCategory.flashcards.tint,
            StudyCategory.written.shortName: StudyCategory.written.tint,
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: xAxisUnit, count: xAxisStride)) { _ in
                AxisGridLine()
                AxisValueLabel(format: xAxisFormat)
            }
        }
        .chartLegend(position: .bottom)
    }

    private var xAxisUnit: Calendar.Component {
        range.isMonthly ? .month : .day
    }

    private var xAxisStride: Int {
        switch range {
        case .week: 1
        case .month: 5
        case .year: 2
        case .all: max(bucketCount / 6, 1)
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch range {
        case .week, .month: .dateTime.month(.defaultDigits).day()
        case .year: .dateTime.month(.abbreviated)
        case .all: .dateTime.month(.narrow).year(.twoDigits)
        }
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

    private func breakdownRow(_ item: CategoryTotal) -> some View {
        let fraction = rangeTotal > 0 ? item.total / rangeTotal : 0
        return VStack(spacing: 6) {
            HStack {
                Image(systemName: item.category.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(item.category.tint)
                    .frame(width: 32, height: 32)
                    .background(item.category.tint.opacity(0.15), in: .rect(cornerRadius: 9))
                Text(item.category.displayName)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(DurationFormat.short(item.total))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.category.tint)
                    .frame(width: 44, alignment: .trailing)
            }
            ProgressView(value: fraction)
                .tint(item.category.tint)
        }
        .padding(.vertical, 2)
    }
}
