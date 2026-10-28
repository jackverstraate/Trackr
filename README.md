# Trackr

A focused iOS app for tracking the time you spend learning a language — Japanese, or any other. Log time across three kinds of study, watch your progress build with streaks and charts, and keep your data portable with JSON backups.

Built with SwiftUI, SwiftData, and Swift Charts, and designed around the iOS 26 **Liquid Glass** design system.

## Features

- **Three activity types** — track **Immersion** (listening/watching native content), **Flashcards** (Anki / SRS review), and **Written** study (textbooks like *Remembering the Kanji* or *Genki*).
- **Live timer + manual entry** — run a start/pause/resume stopwatch while you study, or add a session after the fact with a typed duration. The running timer survives tab switches.
- **Multiple languages** — every session is tagged with a language. Add new languages on the fly and filter by them.
- **Daily goal** — set an optional daily target and watch a progress ring fill on the Today screen.
- **Insights** — Swift Charts break your time down by activity across **Week**, **Month**, **Year**, and **All Time** ranges (daily bars for short ranges, monthly bars for long ones), alongside a current-streak counter and a per-activity percentage breakdown.
- **History** — every session grouped by day with per-day totals, filterable by language and activity, editable, and swipe-to-delete.
- **Backup & restore** — export all your sessions, languages, and goal to a JSON file (Files, iCloud, AirDrop…) and import it back later. Imports dedupe by session ID, so restoring the same file twice never creates duplicates.

## Screens

| Today | History | Insights |
| --- | --- | --- |
| Daily goal ring, live timer, and today's sessions | Sessions grouped by day with filters | Charts, streak, and per-activity breakdown |

## Requirements

- iOS 26.5 or later
- Xcode 26 or later

## Getting started

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/Trackr.git
   ```
2. Open `Trackr.xcodeproj` in Xcode.
3. Select the **Trackr** scheme and a simulator (or your device), then press **⌘R** to build and run.

### iPhone Duo readiness

Build with **Xcode 27.1 or later (iOS 27.1 SDK)** for native Duo display and system bar adaptation. The SDK requirement is independent of the app's minimum supported iOS version.

Today responds to the current content width: wide windows show progress and timer beside today's sessions; narrow windows and accessibility text sizes use a single column. `AnyLayout` retains view identity while resizing, and the shared timer remains outside the layout. iPhone supports portrait and both landscape orientations. Onboarding keeps its content at a comfortable reading width.

Before release, use the iPhone Duo simulator or Device Hub to check:

- Fold and unfold while timing, paused, and editing a session; confirm elapsed time and unsaved edits survive.
- Rotate on both displays and resize Split View; check system side bars, safe areas, and keyboard presentation.
- Check Today, History, Insights, onboarding, settings, and session sheets at narrow widths and accessibility text sizes.
- Save, edit, and delete sessions after resizing, and verify chart and history content remain reachable.

The simulator build was verified with Xcode 27.1. Duo pose and visual checks still require a Duo simulator runtime; the installed runtime at implementation time was iOS 27.0.

### Running on a physical device

Select the **Trackr** target → **Signing & Capabilities** → enable *Automatically manage signing* and choose your team (a free Apple ID works). Then pick your iPhone as the run destination and press **⌘R**. On the first launch, trust the developer certificate under **Settings → General → VPN & Device Management** on the device. Apps signed with a free Apple ID expire after 7 days and must be re-deployed from Xcode.

## Architecture

Trackr is a SwiftUI app using SwiftData for persistence, organized for clear separation of concerns:

```
Trackr/
├── Models/
│   ├── ActivityKind.swift     # Immersion / Flashcards / Written enum + display metadata
│   ├── StudySession.swift     # @Model persisted study session
│   └── StudyTimer.swift        # @Observable stopwatch (start/pause/resume)
├── Support/
│   ├── StudyStats.swift        # Pure aggregation: totals, streaks, per-day/per-month buckets
│   ├── DurationFormat.swift    # TimeInterval → "1h 23m" / "00:00" formatting
│   ├── LanguageList.swift      # @AppStorage-backed list of known languages
│   ├── DataBackup.swift        # JSON backup encode/decode + FileDocument
│   └── SampleData.swift        # In-memory sample container for previews (DEBUG only)
├── Views/
│   ├── ContentView.swift       # Root TabView (Today / History / Insights)
│   ├── TodayView.swift
│   ├── HistoryView.swift
│   ├── InsightsView.swift
│   ├── SessionEditorView.swift # Shared add/edit sheet
│   ├── SettingsView.swift      # Backup & restore
│   └── Components/             # ActivityBadge, SessionRow, GoalRingView, TimerControlView
└── TrackrApp.swift             # App entry point + ModelContainer
```

**Design notes**

- The stats layer (`StudyStats`) is free of SwiftUI and SwiftData so it stays simple and testable.
- Following Apple's Human Interface Guidelines, Liquid Glass is applied sparingly — only to the timer control (the functional layer) — while content uses standard materials. System navigation and tab bars pick up Liquid Glass automatically.
- The live timer keeps only in-progress state and never touches the database; a `StudySession` is created only when you save.

## License

Released under the MIT License. See [LICENSE](LICENSE) for details.
