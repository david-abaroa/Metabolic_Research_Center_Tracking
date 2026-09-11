# Daily Timeline

A single-tab Android app (built with Flutter) for logging a handful of daily
events — wake up, protein drink, protein bar, meals, exercise, bed time — on
a scrollable timeline. All data is stored on-device in a local SQLite
database via `sqflite`; nothing leaves the phone.

## Running it

You'll need the Flutter SDK installed on your own machine (this can't be
built/run inside this chat — there's no Android SDK or emulator here).

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Unzip this project, `cd` into `daily_timeline/`
3. `flutter pub get`
4. Connect an Android device (USB debugging on) or start an emulator
5. `flutter run`

That's it — `flutter run` builds a debug APK and installs it on the
connected device/emulator.

To install a standalone APK you can keep on your phone without a dev
connection: `flutter build apk --release`, then install the file at
`build/app/outputs/flutter-apk/app-release.apk`.

## How it works

- `lib/models/timeline_entry.dart` — the data model for one timeline entry
- `lib/db/database_helper.dart` — SQLite setup: an `entries` table plus
  `protein_options` / `veggie_options` tables that grow automatically every
  time you type a new protein or veggie name into a meal
- `lib/screens/today_screen.dart` — the single tab: today's entries in a
  scrollable list, newest additions appear in time order
- `lib/widgets/add_entry_sheet.dart` — the "+" button opens a picker for the
  6 entry types; wake/protein drink/protein bar/bed time just ask for a
  time, meal and exercise open a small form
- `lib/widgets/timeline_tile.dart` — renders each entry as an icon + time +
  detail line, and lets you swipe to delete

## What I'd extend first

1. **Multiple days.** Right now it only shows today. Add a date picker or
   left/right swipe so you can review and log for past days.
2. **Editing entries**, not just delete-and-re-add (tap a tile to reopen
   its form pre-filled).
3. **Daily summary** — a small header showing total protein/veggie grams,
   total exercise minutes, and sleep duration (bed time → next wake time).
4. **Export/backup** — since storage is local-only, add a "share as
   CSV/JSON" option so you don't lose history if you lose the phone.
5. **Reminders** — a local notification if you haven't logged a meal by a
   certain time, or a wake-up/bed-time nudge.
6. **Cloud sync** — once the local flow feels right, layer in Firebase or
   a simple REST backend so history survives a reinstall.
