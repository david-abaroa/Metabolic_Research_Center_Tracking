# Daily Timeline

A single-tab Android app (built with Flutter) for logging a handful of daily
events — wake up, protein drink, protein bar, meals, exercise, water, bed
time — on an hour-gridded timeline that positions each entry at its actual
time of day. All data is stored on-device in a local SQLite database via
`sqflite`; nothing leaves the phone.

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
  (now includes `water` as an entry type)
- `lib/db/database_helper.dart` — SQLite setup: an `entries` table plus
  `protein_options` / `veggie_options` tables that grow automatically every
  time you type a new protein or veggie name into a meal; also has
  `updateEntry` (for editing) and `mostRecentBedBefore` (for sleep-duration
  estimates)
- `lib/screens/today_screen.dart` — the single tab: an hour-gridded,
  scrollable timeline canvas. Entries are positioned vertically at their
  actual time of day (colliding entries nudge apart slightly to stay
  readable), with a live "now" marker and an AppBar meal counter + summary
  button
- `lib/widgets/timeline_painter.dart` — the `CustomPainter` that draws the
  dotted hourly gridlines and the shaded "optimal window" bands (3-4 hours
  after any meal/protein entry — a rough follow-up-meal timing cue)
- `lib/widgets/add_entry_sheet.dart` — the "+" button opens a picker for
  the 7 entry types. Also powers `showEntryDetailSheet`, used when tapping
  an existing timeline entry to view/edit/delete it
- `lib/widgets/dual_unit_field.dart` — linked oz/gram input pair used for
  meal protein/veggie amounts; typing into either field updates the other
- `lib/widgets/timeline_tile.dart` — renders each entry as an icon + time +
  detail line; tap to edit, swipe to delete
- `lib/screens/summary_screen.dart` — the day-summary bottom sheet: meal
  count, estimated calories, protein/veggie totals, water, exercise
  minutes, sleep duration
- `lib/utils/units.dart` — oz↔gram conversion and the calorie-estimate
  formula (protein ~4 kcal/g, veggies ~0.3 kcal/g — a rough macro-based
  guess, not a food database)

## What I'd extend first

1. **Multiple days.** Right now it only shows today. Add a date picker or
   left/right swipe so you can review and log for past days.
2. **A real food database** for calorie estimates — the current estimate
   is a rough macro-weight heuristic, not per-food nutrition data.
3. **Export/backup** — since storage is local-only, add a "share as
   CSV/JSON" option so you don't lose history if you lose the phone.
4. **Reminders** — a local notification if you haven't logged a meal by a
   certain time, or a wake-up/bed-time nudge.
5. **Cloud sync** — once the local flow feels right, layer in Firebase or
   a simple REST backend so history survives a reinstall.
