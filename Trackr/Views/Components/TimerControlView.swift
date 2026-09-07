//
//  TimerControlView.swift
//  Trackr
//
//  Created by Jack Ver Straate on 2026-09-02.
//

import SwiftUI

/// The live stopwatch on the Today screen: activity + language selection, a running
/// readout, and start/pause/save controls. This is the app's functional layer, so it's
/// the one place that adopts Liquid Glass (per Apple's HIG, kept off the content layer).
struct TimerControlView: View {
    @Environment(StudyTimer.self) private var timer
    let languages: [String]
    /// Called when the user saves the timed session. The caller reads the timer's
    /// elapsed time and selection to build the `StudySession`, then resets the timer.
    var onSave: () -> Void

    var body: some View {
        @Bindable var timer = timer

        VStack(spacing: 20) {
            Picker("Activity", selection: $timer.selectedKind) {
                ForEach(ActivityKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .disabled(timer.isActive)

            if timer.selectedKind == .immersion {
                Picker("Immersion Style", selection: $timer.selectedImmersionStyle) {
                    ForEach(ImmersionStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(timer.isActive)
            }

            Menu {
                ForEach(languages, id: \.self) { language in
                    Button(language) { timer.selectedLanguage = language }
                }
            } label: {
                Label(
                    timer.selectedLanguage.isEmpty ? "Select language" : timer.selectedLanguage,
                    systemImage: "globe"
                )
                .font(.subheadline.weight(.medium))
            }
            .disabled(timer.isActive)

            GlassEffectContainer(spacing: 20) {
                VStack(spacing: 20) {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(DurationFormat.clock(timer.elapsed(asOf: context.date)))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundStyle(timer.isRunning ? timer.selectedKind.tint : .primary)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            .glassEffect(in: .rect(cornerRadius: 28))
                    }

                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.snappy) { timer.toggle() }
                        } label: {
                            Label(primaryTitle, systemImage: primaryIcon)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(timer.selectedKind.tint)
                        .disabled(timer.selectedLanguage.isEmpty)

                        if timer.isActive {
                            Button {
                                onSave()
                            } label: {
                                Label("Save", systemImage: "checkmark")
                                    .font(.headline)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 4)
                            }
                            .buttonStyle(.glass)
                        }
                    }
                }
            }
        }
    }

    private var primaryTitle: String {
        if timer.isRunning { return "Pause" }
        return timer.isActive ? "Resume" : "Start"
    }

    private var primaryIcon: String {
        timer.isRunning ? "pause.fill" : "play.fill"
    }
}
