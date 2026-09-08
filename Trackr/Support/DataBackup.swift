//
//  DataBackup.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// A single session as stored in a backup file.
struct SessionBackup: Codable {
    var id: UUID
    var kind: String
    var language: String
    var startDate: Date
    var duration: TimeInterval
    var note: String
    /// Immersion sub-type raw value. Optional so older backups still decode.
    var immersionStyle: String?
}

/// The full contents of a Trackr backup file.
struct BackupFile: Codable {
    var version: Int
    var exportedAt: Date
    var languages: [String]
    var dailyGoalMinutes: Int
    var sessions: [SessionBackup]
    /// The language being learned when the backup was made. Optional so older
    /// backups still decode; restore falls back to `languages` when it's absent.
    var currentLanguage: String?
}

/// The outcome of restoring a backup into the model context.
struct RestoreResult {
    let added: Int
    let skipped: Int
    /// The language to select after restoring, if one could be determined.
    let language: String?
    let dailyGoalMinutes: Int
}

/// Encodes and decodes the app's data to/from a portable JSON backup.
enum DataBackup {
    static let currentVersion = 1

    static func encode(sessions: [StudySession], languages: [String], goalMinutes: Int, currentLanguage: String) throws -> Data {
        let file = BackupFile(
            version: currentVersion,
            exportedAt: .now,
            languages: languages,
            dailyGoalMinutes: goalMinutes,
            sessions: sessions.map {
                SessionBackup(
                    id: $0.id,
                    kind: $0.kindRaw,
                    language: $0.language,
                    startDate: $0.startDate,
                    duration: $0.duration,
                    note: $0.note,
                    immersionStyle: $0.immersionStyleRaw.isEmpty ? nil : $0.immersionStyleRaw
                )
            },
            currentLanguage: currentLanguage
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(file)
    }

    static func decode(_ data: Data) throws -> BackupFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupFile.self, from: data)
    }

    /// Decodes a backup and inserts any sessions not already present (deduped by id).
    /// Returns what was added plus the language and goal to apply.
    static func restore(_ data: Data, into context: ModelContext, existingIDs: Set<UUID>) throws -> RestoreResult {
        let backup = try decode(data)
        var added = 0
        for session in backup.sessions where !existingIDs.contains(session.id) {
            context.insert(
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
        // Prefer the stored current language; fall back to the first known language.
        let language = backup.currentLanguage ?? backup.languages.first
        return RestoreResult(
            added: added,
            skipped: backup.sessions.count - added,
            language: language,
            dailyGoalMinutes: backup.dailyGoalMinutes
        )
    }
}

/// A `FileDocument` wrapper so backups can be written with `.fileExporter`.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
