//
//  DataBackup.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A single session as stored in a backup file.
struct SessionBackup: Codable {
    var id: UUID
    var kind: String
    var language: String
    var startDate: Date
    var duration: TimeInterval
    var note: String
}

/// The full contents of a Trackr backup file.
struct BackupFile: Codable {
    var version: Int
    var exportedAt: Date
    var languages: [String]
    var dailyGoalMinutes: Int
    var sessions: [SessionBackup]
}

/// Encodes and decodes the app's data to/from a portable JSON backup.
enum DataBackup {
    static let currentVersion = 1

    static func encode(sessions: [StudySession], languages: [String], goalMinutes: Int) throws -> Data {
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
                    note: $0.note
                )
            }
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
