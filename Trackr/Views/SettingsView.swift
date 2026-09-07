//
//  SettingsView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Settings sheet housing data backup and restore.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKey.knownLanguages) private var languageList = LanguageList.seed
    @AppStorage(SettingsKey.dailyGoalMinutes) private var goalMinutes = 0

    @Query private var allSessions: [StudySession]

    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument: BackupDocument?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export Backup…", systemImage: "square.and.arrow.up")
                    }
                    .disabled(allSessions.isEmpty)
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Saves all \(allSessions.count) session(s), your languages, and daily goal to a JSON file you can store in Files, iCloud, or anywhere else.")
                }

                Section {
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import Backup…", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Restore")
                } footer: {
                    Text("Adds sessions from a backup file. Sessions already on this device are left untouched, so importing the same file twice won't create duplicates.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: exportFilename
            ) { result in
                if case .failure(let error) = result {
                    message = "Export failed: \(error.localizedDescription)"
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json]
            ) { result in
                handleImport(result)
            }
            .alert(
                "Backup",
                isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })
            ) {
                Button("OK", role: .cancel) { message = nil }
            } message: {
                Text(message ?? "")
            }
        }
    }

    private var exportFilename: String {
        "Trackr-Backup-\(Date.now.formatted(.iso8601.year().month().day()))"
    }

    private func prepareExport() {
        do {
            let data = try DataBackup.encode(
                sessions: allSessions,
                languages: languageList.languages,
                goalMinutes: goalMinutes
            )
            exportDocument = BackupDocument(data: data)
            isExporting = true
        } catch {
            message = "Couldn't create backup: \(error.localizedDescription)"
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: url)
            let backup = try DataBackup.decode(data)

            let existingIDs = Set(allSessions.map(\.id))
            var added = 0
            for session in backup.sessions where !existingIDs.contains(session.id) {
                modelContext.insert(
                    StudySession(
                        id: session.id,
                        kind: ActivityKind(rawValue: session.kind) ?? .immersion,
                        language: session.language,
                        startDate: session.startDate,
                        duration: session.duration,
                        note: session.note,
                        immersionStyle: session.immersionStyle.flatMap(ImmersionStyle.init(rawValue:))
                    )
                )
                added += 1
            }

            var list = languageList
            backup.languages.forEach { list.add($0) }
            languageList = list
            if goalMinutes == 0 { goalMinutes = backup.dailyGoalMinutes }

            let skipped = backup.sessions.count - added
            message = "Imported \(added) new session(s)."
                + (skipped > 0 ? " \(skipped) already existed." : "")
        } catch {
            message = "Import failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(SampleData.container)
}
