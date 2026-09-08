//
//  OnboardingView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-08.
//

import SwiftUI

/// First-launch flow where the user chooses the language they want to learn.
struct OnboardingView: View {
    @AppStorage(SettingsKey.knownLanguages) private var languageList = LanguageList.seed
    @AppStorage(SettingsKey.lastLanguage) private var lastLanguage = "Japanese"
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false

    @State private var selectedPreset: String?
    @State private var customLanguage = ""
    @State private var isFinishing = false
    @FocusState private var customFieldFocused: Bool

    private let presets = [
        "Japanese", "Korean", "Chinese", "Spanish",
        "French", "German", "Italian", "Russian",
    ]

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
                            ForEach(presets, id: \.self) { language in
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

            getStartedButton
                .padding()
        }
        .overlay {
            if isFinishing {
                successOverlay
                    .transition(.opacity)
            }
        }
    }

    private var successOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 88))
                    .foregroundStyle(.tint)
                    .symbolEffect(.bounce, value: isFinishing)
                Text("You're all set!")
                    .font(.title2.weight(.semibold))
                Text("Let's start tracking your \(chosenLanguage).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
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
        var list = LanguageList(languages: [])
        list.add(language)
        languageList = list
        lastLanguage = language

        customFieldFocused = false
        // Show a brief confirmation, then hand off to the main app.
        withAnimation(.smooth) { isFinishing = true }
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            withAnimation(.snappy) { hasOnboarded = true }
        }
    }
}

#Preview {
    OnboardingView()
}
