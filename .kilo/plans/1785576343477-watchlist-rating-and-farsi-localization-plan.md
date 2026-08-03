# Plan: Fix Watchlist Zero-Rating Bug + Complete Farsi Localization

## Goal

Two user-reported defects in the `nextup` Flutter app:

1. **Watchlist rating shows 0** — items freshly added to the watchlist display a rating of `0.0` even though the title has a real TMDB rating.
2. **Incomplete Farsi localization** — when the app language is set to Persian, some buttons and UI sections stay in English because the strings are hardcoded instead of routed through `AppStrings`.

---

## Issue 1: Watchlist Zero-Rating

### Root cause

In `lib/features/watchlist/domain/watchlist_cubit.dart` (`loadWatchlist`, lines ~97-142), when a watchlist row already has cached `title` and `poster_path`, the model is built from only `id`, `name`/`title`, and `posterPath`. `voteAverage` is never passed, so it defaults to `0.0`. The full TMDB fetch (which includes `vote_average`) only runs when title/poster are missing. The page renders this value at `lib/features/watchlist/presentation/pages/watchlist_page.dart:276,313`.

### Chosen approach (Option 1)

Persist `vote_average` in the `watchlist` table when adding, and read it back in the cached fast-path. Ratings rarely change and watchlist load stays fast (no per-item network calls).

### Prerequisite: database column

The `watchlist` table needs a `vote_average` column (nullable numeric/`double precision`, default `0`). This requires a Supabase migration. **This is a mutating DB change — an implementation-capable agent must apply it.** Verify current schema first (check `supabase/` migrations directory). If the column already exists, skip the migration.

### Code changes

1. **`lib/shared/services/supabase_service.dart`** — `addToWatchlist` (~line 212):
   - Add optional param `double? voteAverage`.
   - Write it into the `row` map as `'vote_average': voteAverage` (only if non-null, matching the existing `genres`/`originCountries` pattern).
   - `getWatchlist` uses `select()` (all columns), so the value returns automatically — no change needed there.

2. **`lib/features/show/domain/show_detail_cubit.dart`** (~line 309) — pass `voteAverage: currentState.show.voteAverage` in the `addToWatchlist` call.

3. **`lib/features/movie/domain/movie_detail_cubit.dart`** (~line 294) — pass `voteAverage: currentState.movie.voteAverage` in the `addToWatchlist` call.

4. **`lib/features/watchlist/domain/watchlist_cubit.dart`** — `loadWatchlist`, both cached fast-path branches (tv ~line 104, movie ~line 122):
   - Pass `voteAverage: (item['vote_average'] as num?)?.toDouble() ?? 0.0` into `ShowModel(...)` and `MovieModel(...)`.

### Backfill note

Items added **before** this change have no stored `vote_average`, so they will still show `0.0` on the fast-path. Options for the implementer (pick one, ask user if unsure):
- **A (recommended):** In the cached branch, if `vote_average` is null/0, fall back to the existing TMDB fetch for that item so old items self-heal on next load.
- **B:** One-time backfill script/migration populating `vote_average` from TMDB.
- **C:** Accept that only newly-added items are correct.

---

## Issue 2: Incomplete Farsi Localization

### Root cause

The `AppStrings` system (`lib/core/localization/app_strings.dart`) is complete and richly translated. The gap is UI code that bypasses it with hardcoded English literals. Confirmed example: `WatchlistError('Something went wrong. Please try again.')` in `watchlist_cubit.dart:151,172,197`, shown directly at `watchlist_page.dart:211`.

### Approach

1. **Audit** — grep across `lib/` for hardcoded user-facing English string literals inside `Text(...)`, `SnackBar`, `AlertDialog`/`SimpleDialog` titles/content, `hintText`, `labelText`, button labels, and error states emitted to the UI (e.g. `*Error('...')` strings). Search patterns like `Text('`, `Text("`, `hintText:`, `labelText:`, and error-state constructors carrying literal English.

2. **Catalog** — build a list of every hardcoded string with file:line. Classify each as: (a) already has an `AppStrings` getter, (b) needs a new getter added.

3. **Add missing getters** — for any string without an existing key, add a new getter to `AppStrings` with both Farsi and English values, following the existing `_p('فارسی', 'English')` pattern and section grouping.

4. **Replace literals** — swap each hardcoded literal for `AppStrings.of(context).<getter>`. For cubits/services that lack a `BuildContext`, refactor so the error string is resolved at the UI layer (e.g. emit a stable error code/enum and map it to `AppStrings` in the widget), rather than storing an English sentence in state.

5. **Verify** — confirm the selected language propagates globally (locale set in `main.dart` / settings). Confirm the audit is exhaustive by re-grepping after replacement.

### Known starting point

- `watchlist_cubit.dart` `WatchlistError('Something went wrong. Please try again.')` (3 occurrences) → route through `AppStrings.somethingWrong` at the page. Same pattern likely exists in other cubits (e.g. `show_detail_cubit.dart:282` `ShowDetailError('Something went wrong. Please try again.')`); include all such cubits in the audit.

---

## Ordered Task List

1. Inspect `supabase/` migrations to confirm whether `watchlist.vote_average` exists.
2. If missing, add a migration adding `vote_average double precision default 0` to `watchlist` (implementation agent; mutating DB change).
3. Add `double? voteAverage` param to `addToWatchlist` and write it into the upsert row.
4. Pass `voteAverage` from `show_detail_cubit.dart` and `movie_detail_cubit.dart` call sites.
5. Read `vote_average` in both cached fast-path branches of `loadWatchlist`.
6. Decide + implement backfill strategy (recommend Option A: TMDB fallback when stored rating is null/0).
7. Grep-audit `lib/` for hardcoded user-facing English literals; produce a file:line catalog.
8. Add any missing `AppStrings` getters (Farsi + English).
9. Replace hardcoded literals with `AppStrings` getters; refactor cubit/service error strings to resolve at the UI layer.
10. Re-grep to confirm no user-facing hardcoded literals remain.

## Validation

- **Rating:** Add a movie and a show with known non-zero TMDB ratings to the watchlist; open the watchlist page; confirm the real rating displays (not `0.0`). Verify pre-existing items via the chosen backfill path.
- **Localization:** Set language to Persian in settings; walk every screen (home, search, watchlist, profile, settings, detail pages, dialogs, error/empty states, snackbars); confirm no English text remains. Trigger a watchlist error path and confirm the Farsi message shows.
- Run `flutter analyze` to confirm no new analyzer errors after edits.

## Notes / Constraints

- Steps 2-10 require source edits and a mutating DB migration → switch to an **implementation-capable agent** to execute.
- Keep the `_p('فارسی', 'English')` convention and existing section grouping in `AppStrings`.
- Do not store localized English sentences in cubit/bloc state; prefer stable codes mapped to `AppStrings` at the widget layer.
