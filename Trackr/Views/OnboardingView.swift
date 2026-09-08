//
//  OnboardingView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-08.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// First-launch flow where the user chooses a language, or restores from a backup.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(SettingsKey.knownLanguages) private var languageList = LanguageList.seed
    @AppStorage(SettingsKey.lastLanguage) private var lastLanguage = "Japanese"
    @AppStorage(SettingsKey.dailyGoalMinutes) private var goalMinutes = 0
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false

    @State private var selectedPreset: String?
    @State private var customLanguage = ""
    @State private var isImporting = false
    @State private var importError: String?
    /// Non-nil once the user commits, driving the closing confirmation animation.
    @State private var finish: FinishMode?
    /// The language shown in the confirmation screen.
    @State private var finishLanguage = ""
    @FocusState private var customFieldFocused: Bool

    /// How onboarding was completed, which changes the confirmation wording.
    private enum FinishMode {
        case selected
        case restored
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    /// The language the user has settled on, trimmed. Empty if nothing chosen.
    private var chosenLanguage: String {
        let custom = customLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        return custom.isEmpty ? (selectedPreset ?? "") : custom
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Which language are you learning?")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(LanguageList.presets, id: \.self) { language in
                                presetButton(language)
                            }
                        }

                        TextField("Another language", text: $customLanguage)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .focused($customFieldFocused)
                            .onChange(of: customLanguage) { _, newValue in
                                if !newValue.isEmpty { selectedPreset = nil }
                            }
                    }
                }
                .padding()
            }

            VStack(spacing: 12) {
                getStartedButton
                Button {
                    isImporting = true
                } label: {
                    Label("Restore from Backup", systemImage: "square.and.arrow.down")
                        .font(.subheadline.weight(.medium))
                }
            }
            .padding()
        }
        .overlay {
            if let finish {
                successOverlay(finish)
                    .transition(.opacity)
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            handleRestore(result)
        }
        .alert(
            "Couldn't Restore",
            isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })
        ) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    private func successOverlay(_ mode: FinishMode) -> some View {
        ZStack {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 88))
                    .foregroundStyle(.tint)
                    .symbolEffect(.bounce, value: finish != nil)
                Text(mode == .selected ? "You're all set!" : "Backup restored!")
                    .font(.title2.weight(.semibold))
                Text(subtitle(for: mode))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    private func subtitle(for mode: FinishMode) -> String {
        switch mode {
        case .selected: "Let's start tracking your \(finishLanguage)."
        case .restored: "Picked up where you left off with \(finishLanguage)."
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.tint)
                .padding(.top, 32)
            Text("Welcome to Trackr")
                .font(.largeTitle.weight(.bold))
            Text("Track the time you spend learning a language.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func presetButton(_ language: String) -> some View {
        let isSelected = selectedPreset == language && customLanguage.isEmpty
        return Button {
            customLanguage = ""
            customFieldFocused = false
            selectedPreset = language
        } label: {
            Text(language)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.white : .primary)
        .background(
            isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.background.secondary),
            in: .rect(cornerRadius: 14)
        )
    }

    private var getStartedButton: some View {
        Button {
            complete()
        } label: {
            Text("Get Started")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(chosenLanguage.isEmpty)
    }

    private func complete() {
        let language = chosenLanguage
        guard !language.isEmpty else { return }
        setLanguage(language)
        finishOnboarding(language: language, mode: .selected)
    }

    private func handleRestore(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: url)
            let existing = (try? modelContext.fetch(FetchDescriptor<StudySession>())) ?? []
            let outcome = try DataBackup.restore(
                data,
                into: modelContext,
                existingIDs: Set(existing.map(\.id))
            )

            guard let language = outcome.language else {
                importError = "That backup doesn't specify a language."
                return
            }
            setLanguage(language)
            if outcome.dailyGoalMinutes > 0 { goalMinutes = outcome.dailyGoalMinutes }
            finishOnboarding(language: language, mode: .restored)
        } catch {
            importError = error.localizedDescription
        }
    }

    /// Persists the chosen language as the single language the app tracks.
    private func setLanguage(_ language: String) {
        var list = LanguageList(languages: [])
        list.add(language)
        languageList = list
        lastLanguage = language
    }

    /// Shows the closing confirmation, then hands off to the main app.
    private func finishOnboarding(language: String, mode: FinishMode) {
        finishLanguage = language
        customFieldFocused = false
        withAnimation(.smooth) { finish = mode }
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            withAnimation(.snappy) { hasOnboarded = true }
        }
    }
}

#Preview {
    OnboardingView()
}
