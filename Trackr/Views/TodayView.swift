//
//  TodayView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI
import SwiftData

/// The home screen: today's progress ring, the live timer, and today's logged sessions.
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StudyTimer.self) private var timer

    @AppStorage(SettingsKey.knownLanguages) private var languageList = LanguageList.seed
    @AppStorage(SettingsKey.lastLanguage) private var lastLanguage = "Japanese"
    @AppStorage(SettingsKey.dailyGoalMinutes) private var goalMinutes = 0

    @Query(sort: \StudySession.startDate, order: .reverse) private var allSessions: [StudySession]

    @State private var isAddingManually = false
    @State private var editingSession: StudySession?

    private var todaySessions: [StudySession] {
        allSessions.filter { Calendar.current.isDateInToday($0.startDate) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    GoalRingView(secondsToday: StudyStats.total(todaySessions), goalMinutes: goalMinutes)
                        .padding(.top, 8)

                    TimerControlView(languages: languageList.languages, onSave: saveTimedSession)

                    sessionsSection
                }
                .padding()
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Session", systemImage: "plus") { isAddingManually = true }
                }
            }
            .sheet(isPresented: $isAddingManually) {
                SessionEditorView(session: nil)
            }
            .sheet(item: $editingSession) { session in
                SessionEditorView(session: session)
            }
            .onAppear(perform: seedTimerLanguage)
        }
    }

    @ViewBuilder
    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Sessions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if todaySessions.isEmpty {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "clock.badge.checkmark",
                    description: Text("Start the timer or add a session to begin tracking today.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(todaySessions) { session in
                        SessionRow(session: session)
                            .contentShape(.rect)
                            .onTapGesture { editingSession = session }
                            .contextMenu {
                                Button("Edit", systemImage: "pencil") { editingSession = session }
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    modelContext.delete(session)
                                }
                            }
                        if session.id != todaySessions.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(.background.secondary, in: .rect(cornerRadius: 16))
            }
        }
    }

    private func seedTimerLanguage() {
        guard timer.selectedLanguage.isEmpty else { return }
        timer.selectedLanguage = languageList.languages.contains(lastLanguage)
            ? lastLanguage
            : (languageList.languages.first ?? "")
    }

    private func saveTimedSession() {
        let elapsed = timer.elapsed()
        guard elapsed >= 1 else {
            timer.reset()
            return
        }
        let session = StudySession(
            kind: timer.selectedKind,
            language: timer.selectedLanguage,
            startDate: Date.now.addingTimeInterval(-elapsed),
            duration: elapsed
        )
        modelContext.insert(session)
        lastLanguage = timer.selectedLanguage
        withAnimation(.snappy) { timer.reset() }
    }
}

#Preview {
    TodayView()
        .environment(StudyTimer())
        .modelContainer(for: StudySession.self, inMemory: true)
}
