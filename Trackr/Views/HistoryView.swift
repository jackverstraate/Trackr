//
//  HistoryView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI
import SwiftData

/// Full history of sessions grouped by day, with an activity filter and editing.
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudySession.startDate, order: .reverse) private var allSessions: [StudySession]

    @State private var kindFilter: ActivityKind?
    @State private var editingSession: StudySession?

    private var filteredSessions: [StudySession] {
        allSessions.filter { session in
            kindFilter == nil || session.kind == kindFilter
        }
    }

    /// Sessions grouped by calendar day, most recent day first.
    private var groupedByDay: [(day: Date, sessions: [StudySession])] {
        let groups = Dictionary(grouping: filteredSessions) {
            Calendar.current.startOfDay(for: $0.startDate)
        }
        return groups
            .map { (day: $0.key, sessions: $0.value) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredSessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Logged sessions will appear here.")
                    )
                } else {
                    List {
                        ForEach(groupedByDay, id: \.day) { group in
                            Section {
                                ForEach(group.sessions) { session in
                                    SessionRow(session: session)
                                        .contentShape(.rect)
                                        .onTapGesture { editingSession = session }
                                        .swipeActions {
                                            Button("Delete", systemImage: "trash", role: .destructive) {
                                                modelContext.delete(session)
                                            }
                                        }
                                }
                            } header: {
                                HStack {
                                    Text(group.day, format: .dateTime.weekday(.wide).month().day())
                                    Spacer()
                                    Text(DurationFormat.short(StudyStats.total(group.sessions)))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    filterMenu
                }
            }
            .sheet(item: $editingSession) { session in
                SessionEditorView(session: session)
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Activity", selection: $kindFilter) {
                Label("All Activities", systemImage: "square.grid.2x2")
                    .tag(ActivityKind?.none)
                ForEach(ActivityKind.allCases) { kind in
                    Label(kind.displayName, systemImage: kind.systemImage)
                        .tag(ActivityKind?.some(kind))
                }
            }
        } label: {
            Label("Filter", systemImage: isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    private var isFiltering: Bool {
        kindFilter != nil
    }
}

#Preview {
    HistoryView()
        .modelContainer(SampleData.container)
}
