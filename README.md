# Gnote

> **Own your day.**

Gnote is a personal accountability app built in Flutter. It started as a private tool and is being prepared for public release. The core idea is a guardian system — a daily rhythm that keeps the user in lane through five focused features. No feeds, no streaks leaderboard, no social layer. Just you and your day.

---

## What the app does

Every feature maps to a moment in the user's day:

| Feature | When | What it does |
|---|---|---|
| **Anchor** | Morning | One sentence that defines why you woke up today. Locks at 9am. |
| **Daily 3** | Morning | Three tasks. No more. Locked by 9am. No additions after lock. |
| **Capture** | Any time | Brain dump for everything that isn't today. Review on Sundays. |
| **Habit** | Evening | One habit — build it or break it. Did it or didn't. |
| **People** | Daily | The app picks one person from your list. You send them a WhatsApp message. |

The Anchor gates everything else. If the user has not set their anchor before 9am, they cannot access Daily 3, Capture, Habit, or People. After 9am the gate lifts regardless — the lock window has passed.

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State management | Riverpod (`StateNotifier` pattern) |
| Local storage | Hive (offline-first) |
| Remote storage | Supabase (Postgres + Auth) |
| Navigation | GoRouter with shell routes |
| Notifications | awesome_notifications |
| Auth | Supabase Auth — email + password + OTP verification |

---

## Project structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_config.dart       # GRoutes, GBoxes, GTables, GCategories, GLimits, GJson
│   │   ├── app_strings.dart      # GStrings — all copy in one place
│   │   └── design_tokens.dart    # GColors, GSpacing, GText
│   ├── constants.dart            # barrel export for all constants
│   ├── theme.dart                # GTheme — dark + light ThemeData
│   ├── router.dart               # GoRouter setup
│   ├── router_guard.dart         # _authGuard — auth + anchor gate logic
│   ├── router_shell.dart         # _GShell — bottom nav shell
│   ├── auth_flow.dart            # completeAuthenticatedEntry()
│   └── timezone.dart             # localNow(), asLocal(), isSameLocalDay()
│
├── models/
│   ├── user.dart / user.g.dart
│   ├── task.dart / task.g.dart
│   ├── anchor.dart / anchor.g.dart
│   ├── habit.dart / habit.g.dart
│   └── person.dart / person.g.dart
│
├── services/
│   ├── local_db.dart             # Hive wrapper — single source of truth
│   ├── sync.dart                 # push/pull to Supabase + pending queue
│   ├── auth_service.dart         # signUp / signIn / verifyOTP / resendOTP
│   ├── notification_service.dart # awesome_notifications setup + scheduling
│   └── providers/
│       ├── core_providers.dart
│       ├── auth_provider.dart
│       ├── anchor_provider.dart
│       ├── daily3_provider.dart
│       ├── capture_provider.dart
│       ├── habit_provider.dart
│       ├── responsibility_provider.dart
│       └── theme_provider.dart
│
├── pages/
│   ├── anchor_page.dart
│   ├── daily3_page.dart
│   ├── capture_page.dart
│   ├── habit_page.dart + habit_page_sections.dart
│   ├── responsibility_page.dart + responsibility_page_sections.dart
│   ├── add_tasks.dart
│   ├── add_persons.dart
│   ├── login_page.dart
│   ├── signup_page.dart
│   ├── verify_otp_page.dart
│   └── profile_page.dart
│
└── main.dart
```

---

## Data model

### Supabase schema (simplified)

```sql
profiles        id, email, display_name, timezone, created_at, last_seen
anchors         id, user_id, content (text), date (date), created_at
tasks           id, user_id, what, done_when, by (timestamp), category, is_done, is_capture, created_at, completed_at
habits          id, user_id, name, streak, last_checked, is_active, created_at
people          id, user_id, name, whatsapp_number, role ('Motivator'|'Meditator'), message_template, last_selected_at, times_selected, created_at
selections      id, user_id, person_id, selected_at
```

### Key model notes

**GTask** handles both Daily 3 and Capture through a single `isCapture` boolean flag. There is no separate model for captured items. Category is stored but not shown in the UI (v1 decision).

**GHabit** supports one active habit at a time. `isActive` is enforced in `LocalDb.saveHabit()` — when a new habit is saved, all others are set `isActive = false`. Streak logic lives on the model: `doneToday`, `streakAlive`, `isBroken`, `currentStreak`.

**GPerson** has a `role` field constrained to `'Motivator'` or `'Meditator'`. `resolvedMessage` replaces `{name}` placeholder in the template with the person's actual name for WhatsApp dispatch.

---

## Offline-first architecture

**Write path:** All writes go to Hive first (synchronous, instant). Then a push op is enqueued to Supabase via `SyncService`.

**Sync queue:** Failed remote writes are stored in `LocalDb` as `_pendingSyncOps`. On next app open or reconnect, `retryPending()` replays them in order.

**Read path on login:** `pullAll()` runs once after login. It fetches all remote data and merges into Hive. Each row is wrapped in a try/catch — a malformed row is skipped silently, not crashing the pull.

**Day reset:** `main.dart` watches `AppLifecycleState.resumed`. On resume, if the calendar date has changed, all providers are invalidated — the app resets to a fresh day without requiring a restart.

---

## Auth flow

Supabase Auth is used with email + password + OTP verification.

```
SignUp → email confirmation enabled?
  ├─ session == null → SignUpNeedsVerification → user enters OTP → verifyOTP() → home
  └─ session != null → SignUpSessionActive → home directly

SignIn → email + password → GUser → home
```

Profile row creation is handled by a Supabase database trigger (`handle_new_user`). The app also attempts a manual upsert on signup as a fallback for environments where the trigger is delayed.

**OTP:** 8-digit code. `AuthService.verifyOTP()` calls `supabase.auth.verifyOTP(type: OtpType.signup, ...)`. After verification, `pullAll()` hydrates Hive from Supabase before navigating home.

---

## Routing and guards

GoRouter is used with a global `redirect` function (`_authGuard`).

**Auth guard:** Unauthenticated users on non-public routes → redirect to `/login`. Authenticated users on `/login` or `/signup` → redirect to `/`.

**Anchor gate:** Before 9am, if the user has no anchor for today and tries to access `/daily3`, `/capture`, `/habit`, or `/responsibility` → redirect to `/`. After 9am the gate is not applied regardless of anchor state.

```dart
bool _isBeforeAnchorLock() => localNow().hour < 9;
```

**Shell routes:** The five main tabs (`/`, `/daily3`, `/capture`, `/habit`, `/responsibility`) are wrapped in a `ShellRoute` that renders the bottom nav. Auth pages and profile are outside the shell.

---

## Notifications

Five scheduled daily notifications managed by `NotificationService`:

| ID | Channel | Time | Purpose |
|---|---|---|---|
| 1 | `gnote_anchor` | 08:00 | Set your anchor |
| 2 | `gnote_tasks` | 08:45 | Add tasks before lock |
| 3 | `gnote_habit` | User-set (default 20:00) | Habit reminder |
| 4 | `gnote_responsibility` | 09:00 | Pick today's person |
| 5 | `gnote_anchor` (capture channel) | Sunday 19:00 | Review capture list |

Notifications are scheduled once after login via `completeAuthenticatedEntry()`. They persist until cancelled. Web is silently skipped (`kIsWeb` guard on init).

---

## Running the app

The app requires two compile-time secrets injected via `--dart-define`. There are no hardcoded keys.

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

If either value is missing, the app throws at startup:
```
CRITICAL: Supabase configuration missing.
```

---

## Supabase setup checklist

For a new environment:

1. Create a Supabase project
2. Run the schema (tables: `profiles`, `anchors`, `tasks`, `habits`, `people`, `selections`)
3. Create a `handle_new_user` trigger on `auth.users` to insert into `profiles`
4. Enable email confirmations if OTP flow is required (recommended)
5. Set RLS policies — all tables are user-scoped via `user_id`
6. Set the project timezone to `Africa/Harare` as the default profile timezone (or adjust `GStrings` defaults)

---

## Design system

All design tokens live in `lib/core/constants/design_tokens.dart`.

**Colors:**
- `GColors.background` `#0D0D0D` — canvas
- `GColors.surface` `#1A1A1A` — cards, sheets
- `GColors.orange` `#F0A500` — primary CTA, active nav, anchor lock badge
- `GColors.azure` `#3FA9F5` — secondary actions, Meditator role
- `GColors.success` `#52E0A0`, `GColors.danger` `#E05252`, `GColors.warning` `#F0C040`

**Typography:** `GText.heading`, `GText.subheading`, `GText.body`, `GText.label`, `GText.muted`, `GText.danger`

**Spacing:** `GSpacing.xs` (4) → `GSpacing.xxl` (48), `GSpacing.pagePadding` (20), `GSpacing.cardRadius` (12)

**Contrast:** All text/background pairs are WCAG AA or above. `#E8E8E8` on `#0D0D0D` = 17.5:1.

---

## Key product rules (enforced in code)

| Rule | Where enforced |
|---|---|
| Anchor locks at 9am | `router_guard.dart` — `_isBeforeAnchorLock()` |
| Max 3 Daily tasks | `GLimits.maxDailyTasks = 3`, checked in `daily3_provider.dart` |
| One active habit at a time | `local_db.dart` — `saveHabit()` deactivates all others |
| Habit cannot be marked done twice in one day | `GHabit.doneToday` guard in `habit_provider.dart` |
| People pick is final for the day | `GPerson.selectedToday` — pick button disabled after selection |
| Capture reviewed on Sundays | Sunday banner triggers review dialog in `capture_page.dart` |

---

## What is intentionally deferred (post-v1)

- Daily 3 expanding to 5 tasks after 11 days of consistency
- Category system surfaced in UI
- History and analytics
- Deeper People weighting algorithm (currently: least-recently-picked by `lastSelectedAt`)
- Monetisation / paywall
- Advanced profile polish

---

## Folder conventions

- All copy goes in `GStrings`. No hardcoded strings in widgets.
- All colours go in `GColors`. No hardcoded hex values in widgets.
- All spacing goes in `GSpacing`. No magic numbers.
- `fromJson` always uses `GJson` helpers — null-safe against Supabase nulls.
- Providers read from `LocalDb` only. `SyncService` runs as a side effect.

---

*Built by one person, for one purpose: staying in lane.*
