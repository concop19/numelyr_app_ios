# Calendar screen — behavior and parity specification

## React Native source audited

- `src/screens/CalendarScreen.tsx`
- `src/components/BlocDetailModal.tsx`
- `src/services/lunarService.ts`
- `src/db/cadaoService.ts`
- `src/config/calendarArtConfig.ts`
- `src/config/calendarImages.ts`
- `src/store/userProfile.ts`
- Calendar route and tab configuration in `App.tsx`

## Reachable behavior

1. The screen opens on the local current date and derives a complete lunar-day snapshot from the selected solar date and active profile birth date.
2. Previous/next buttons, the bottom pager and the seven-day week rail all change the selected date. The Today button returns to the local current date.
3. The month chip opens a Monday-first 42-cell picker. Moving month clamps the day to the target month's last valid day, matching JavaScript `Date` behavior in the source.
4. Every selected date refreshes lunar data, the ISO week rail, deterministic daily ca dao and deterministic seasonal artwork.
5. The four quick cards all open the reachable Hoàng lịch sheet: best departure hour, good direction, recommended activities and activities to avoid.
6. The topic card and bottom pull handle open the culture sheet containing seasonal art, the rotating literary work and daily ca dao.
7. Date selection and sheet opening use light haptics. The menu/history icons are visual-only in the current React Native source and remain non-navigating until their owner features are migrated.

## Data rules

- Daily ca dao keeps the source seed `(day * 31 + month * 37 + year * 7) % total`, querying rows ordered by ID. SQLite/open/query failures resolve to the same local fallback sayings rather than an error screen.
- The artwork season follows lunar months: 1–3 Spring, 4–6 Summer, 7–9 Autumn, 10–12 Winter.
- The source catalog currently contains 297 CDN filenames: 122 Spring, 73 Summer, 42 Autumn and 60 Winter.
- The selected image index is `((dayInSeason - 1) * 17 + lunarYear * 37) % seasonCount`; leap-month dates add 15 to `dayInSeason`.
- Literature rotates over four source records using `dayInSeason % 4`.
- Remote art uses `https://assets.numelyra.online/<season>/<filename>` and falls back to one bundled image per season.

## Native iOS mapping

- `CalendarFeature` owns selected date, derived snapshot, ca dao, art loading, stale-response protection and presentation state.
- `CalendarDatePickerFeature` owns month navigation and date selection.
- `CalendarDetailFeature` owns native sheet presentation for Hoàng lịch and culture content.
- `LunarClient`, `CaDaoClient`, `CalendarArtClient` and `HapticClient` isolate all calculations/I/O/haptic side effects from SwiftUI views.
- The native sheet replaces the custom React Native drag interpolation with the standard iOS interactive sheet. This preserves swipe-to-dismiss and accessibility while deliberately using native motion.
- The dormant `lunar_destiny` branch in `BlocDetailModal.tsx` is not exposed because no reachable control opens it in `CalendarScreen.tsx`.

## Acceptance criteria

- The initial and selected dates render matching weekday, solar day, lunar date, Can Chi, week number, 12 hours, direction and activities for the same profile fixture.
- Fast date changes cannot allow an older ca dao or remote image response to overwrite the newest selected date.
- Offline/CDN failure shows bundled seasonal art; missing/corrupt SQLite returns the established ca dao fallback.
- The 42-cell picker includes adjacent-month days, visually distinguishes selected/today/outside-month states and selects all cells.
- The layout remains usable on compact iPhone width, Dynamic Type and VoiceOver; all date/navigation/sheet controls have Vietnamese accessibility labels.
- Reducer tests and screenshot parity must be rerun with full Xcode before marking the slice complete.
