//
//  LanguageList.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import Foundation

/// Keys shared by the `@AppStorage`-backed settings used across the app.
enum SettingsKey {
    static let knownLanguages = "knownLanguages"
    static let lastLanguage = "lastLanguage"
    static let dailyGoalMinutes = "dailyGoalMinutes"
    static let hasOnboarded = "hasOnboarded"
}

/// A `RawRepresentable` wrapper so the list of known languages can live in `@AppStorage`.
struct LanguageList: RawRepresentable, Codable, Equatable {
    var languages: [String]

    init(languages: [String]) {
        self.languages = languages
    }

    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        languages = decoded
    }

    var rawValue: String {
        guard let data = try? JSONEncoder().encode(languages),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }

    /// The default list seeded on first launch.
    static let seed = LanguageList(languages: ["Japanese"])

    /// Adds a trimmed language if it isn't already present (case-insensitive).
    mutating func add(_ language: String) {
        let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !languages.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            return
        }
        languages.append(trimmed)
    }
}
