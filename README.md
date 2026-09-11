# Daily Timeline

A Flutter Android app for logging a handful of daily events — wake up,
protein drink, protein bar, meals, exercise, water, tirzepatide, pills,
GAC, bed time — on an hour-gridded timeline that positions each entry at
its actual time of day. Left/right arrows step through days (or weeks),
and a floating Day/Week/Grid switcher swaps between the day timeline, a
7-day summary, and a horizontal week-at-a-glance timeline grid. All data
is stored on-device in a local SQLite database via `sqflite`; nothing
leaves the phone.

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

- `lib/models/timeline_entry.dart` — the data model for one timeline entry:
  `water`, `tirzepatide` (dose + unit), `pills` (a list of `PillDose`,
  stored as JSON) and `gac` (ml) as entry types, plus a `calories` field
  used by protein bar/drink entries
- `lib/models/app_settings.dart` — the default calories + protein grams for
  protein bar/drink, the default unit ('mg'/'ml') + dose for tirzepatide,
  and the default ml for GAC, all editable from Settings
- `lib/models/pill_type.dart` — `PillType` (a configurable pill + the count
  you normally take, managed in Settings) and `PillDose` (what actually got
  logged on a pills entry)
- `lib/db/database_helper.dart` — SQLite setup: an `entries` table plus
  `protein_options` / `veggie_options` tables that grow automatically every
  time you type a new protein or veggie name into a meal, a single-row
  `settings` table for the protein bar/drink/tirzepatide defaults, and a
  `pill_types` table (seeded with 2 MRC-6, 2 Fish Oil, 2 Enhancer, 2
  Corti-Trim on first run); also has `updateEntry` (for editing) and
  `mostRecentBedBefore` (for sleep-duration estimates)
- `lib/screens/today_screen.dart` — hosts all three views (`ViewMode`:
  day / weekSummary / weekTimeline) plus the AppBar's day/week navigation
  arrows and the floating Day/Week/Grid `SegmentedButton` in
  `bottomNavigationBar`. The day view is an hour-gridded, scrollable
  timeline canvas — entries are positioned vertically at their actual
  time of day (colliding entries nudge apart slightly to stay readable),
  with a live "now" marker (today only) and an AppBar meal counter +
  summary + settings buttons (day mode only). Tapping anywhere on the
  empty timeline (not the FAB) opens the add-entry sheet pre-filled with
  the tapped time, on the currently selected date
- `lib/screens/week_summary_view.dart` — the 7-day breakdown: a totals
  card for the week (meals, protein drinks/bars, calories, water,
  protein/veggie, pills, tirzepatide/GAC day counts) plus one card per
  day (same stats, tap to jump to that day) with a star badge — filled if
  tirzepatide was taken that day, circled if GAC was also taken
- `lib/screens/week_timeline_view.dart` — the 7 days stacked as
  horizontal mini-timelines aligned by time of day, horizontally
  scrollable across the full 24h but opening scrolled to a 6am-11pm
  focus window (hour labels every 3h, vertical dotted gridlines, a "now"
  line on today's row). Each entry (other than tirzepatide/GAC, which
  show as the star/circle badge next to the date instead) is the same
  small colored icon used in the day view — tap one to open/edit it;
  tapping elsewhere on a row jumps to the day view for that date. A key
  at the bottom labels every icon plus the star/circle badge
- `lib/widgets/tirz_gac_badge.dart` — `TirzGacBadge`, the small star
  (filled if tirzepatide was taken, outlined otherwise) circled in teal
  if GAC was also taken; shared by the week summary and week timeline
  views
- `lib/widgets/timeline_painter.dart` — the `CustomPainter` that draws the
  dotted hourly gridlines and the shaded "optimal window" bands (3-4 hours
  after any meal/protein entry — a rough follow-up-meal timing cue)
- `lib/widgets/add_entry_sheet.dart` — the "+" button (or tapping the
  timeline) opens a scrollable picker for the 10 entry types. Protein
  bar/drink, tirzepatide and GAC use the saved defaults from Settings with
  a "Change values" toggle to override them for just that entry; pills
  shows a checkbox per configured pill type (all checked by default),
  logging each checked pill's configured count. Also powers
  `showEntryDetailSheet`, used when tapping an existing timeline entry to
  view/edit/delete it
- `lib/widgets/dual_unit_field.dart` — linked oz/gram input pair used for
  meal and protein bar/drink amounts; typing into either field updates the
  other
- `lib/widgets/timeline_tile.dart` — renders each entry as an icon + time +
  detail line; tap to edit, swipe to delete
- `lib/screens/settings_screen.dart` — the Settings sheet: one collapsible
  card per group (protein bar, protein drink, tirzepatide, GAC, pills),
  each showing a current-values preview when collapsed. Pill-type
  management (add/edit count/delete) applies immediately; the other
  defaults need "Save settings"
- `lib/screens/summary_screen.dart` — `DaySummary.compute` (shared by the
  day-summary sheet and both week views) plus the day-summary bottom
  sheet itself: meal count, protein drinks/bars, estimated calories,
  protein/veggie totals, water, exercise minutes, sleep duration,
  tirzepatide dose totals, pill counts, GAC total. `statRow` is exported
  for reuse by `week_summary_view.dart`
- `lib/utils/units.dart` — oz↔gram conversion and the calorie-estimate
  formula (protein ~4 kcal/g, veggies ~0.3 kcal/g for meals — a rough
  macro-based guess, not a food database; protein bars/drinks use their
  default or overridden calorie value directly)

## What I'd extend first

1. **A real food database** for calorie estimates — the current estimate
   is a rough macro-weight heuristic, not per-food nutrition data.
2. **Export/backup** — since storage is local-only, add a "share as
   CSV/JSON" option so you don't lose history if you lose the phone.
3. **Reminders** — a local notification if you haven't logged a meal by a
   certain time, or a wake-up/bed-time nudge.
4. **Cloud sync** — once the local flow feels right, layer in Firebase or
   a simple REST backend so history survives a reinstall.
5. **Month view / calendar jump** — the day and week arrows only step one
   unit at a time; a calendar picker would make jumping to a specific
   past date faster.
