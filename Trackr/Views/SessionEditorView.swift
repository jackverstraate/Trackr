//
//  SessionEditorView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI
import SwiftData

/// Sheet for adding a session manually or editing an existing one.
struct SessionEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKey.knownLanguages) private var languageList = LanguageList.seed
    @AppStorage(SettingsKey.lastLanguage) private var lastLanguage = "Japanese"

    /// The session being edited, or `nil` to create a new one.
    let session: StudySession?

    @State private var kind: ActivityKind = .immersion
    @State private var language = ""
    @State private var date = Date.now
    @State private var hours = 0
    @State private var minutes = 25
    @State private var note = ""
    @State private var newLanguage = ""

    private var isEditing: Bool { session != nil }
    private var totalSeconds: TimeInterval { TimeInterval(hours * 3600 + minutes * 60) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    Picker("Activity", selection: $kind) {
                        ForEach(ActivityKind.allCases) { kind in
                            Label(kind.displayName, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Language") {
                    Picker("Language", selection: $language) {
                        ForEach(languageList.languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    HStack {
                        TextField("Add a language", text: $newLanguage)
                            .autocorrectionDisabled()
                            .onSubmit(addLanguage)
                        Button("Add", action: addLanguage)
                            .disabled(newLanguage.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("When") {
                    DatePicker("Date", selection: $date, in: ...Date.now)
                }

                Section("Duration") {
                    Stepper("\(hours) h", value: $hours, in: 0...23)
                    Stepper("\(minutes) min", value: $minutes, in: 0...59, step: 5)
                }

                Section("Note") {
                    TextField("Material or note (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle(isEditing ? "Edit Session" : "New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(totalSeconds <= 0 || language.isEmpty)
                }
            }
            .onAppear(perform: loadInitialState)
        }
    }

    private func loadInitialState() {
        if let session {
            kind = session.kind
            language = session.language
            date = session.startDate
            hours = Int(session.duration) / 3600
            minutes = (Int(session.duration) % 3600) / 60
            note = session.note
        } else {
            // New session: default to the last-used language.
            language = languageList.languages.contains(lastLanguage)
                ? lastLanguage
                : (languageList.languages.first ?? "")
        }
    }

    private func addLanguage() {
        let trimmed = newLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        languageList.add(trimmed)
        language = trimmed
        newLanguage = ""
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let session {
            session.kind = kind
            session.language = language
            session.startDate = date
            session.duration = totalSeconds
            session.note = trimmedNote
        } else {
            let newSession = StudySession(
                kind: kind,
                language: language,
                startDate: date,
                duration: totalSeconds,
                note: trimmedNote
            )
            modelContext.insert(newSession)
        }
        lastLanguage = language
        dismiss()
    }
}

#Preview {
    SessionEditorView(session: nil)
        .modelContainer(for: StudySession.self, inMemory: true)
}
