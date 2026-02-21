# Financial Hub

Behavioral financial operating system prototype built with Flutter + Supabase (Android-first).

## Repository

- GitHub: https://github.com/x-dash-io/Financial-Hub.git

Clone:

```bash
git clone https://github.com/x-dash-io/Financial-Hub.git
cd Financial-Hub
```

## What This App Does

Financial Hub helps users think in categories (pockets) instead of a single lump-sum balance.

Core behavior:
- Income is allocated into pockets by percentage rules.
- Savings is structurally protected (locked from direct spending).
- Spending is only from spendable pockets.
- Reallocation is allowed but intentionally slowed with friction.
- Behavioral events are logged for insight reporting.

## Product Rules (Current)

- Allocation percentages must total 100%.
- Savings must be at least 10%.
- Savings is locked from direct spend and cannot be the source pocket in reallocation.
- Savings lock is currently continuous (no auto-expiry timer).
- Savings percentage can be changed anytime in Money Plan.
- Spend insights are shown as monthly totals and per-pocket monthly spent.

See detailed flow: `HOW_IT_WORKS.md`

## Tech Stack

- Flutter (Material 3)
- Supabase (`auth`, `postgres`, `rls`)
- Dart
- GitHub Actions CI (`flutter analyze`, `flutter test`)

## Project Structure

```text
lib/
  core/                 # allocation, sms, ledger, supabase client
  features/             # onboarding, auth, pockets, plan, spending, reallocation, allocation
  shared/               # models, theme tokens, reusable widgets
supabase/
  migrations/           # schema + rls + seed + ledger trigger changes
test/                   # unit/widget tests
```

## Setup

1. Install Flutter (stable channel) and Android toolchain.
2. Create `.env` from `.env.example`.
3. Add Supabase values:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
4. Run dependencies:

```bash
flutter pub get
```

5. Auth provider (current MVP):
- Enable **Anonymous Sign-Ins** in Supabase Auth.
- Phone OTP auth is planned but not the active login path in this build.

## Run The App

```bash
flutter run
```

## Quality Checks

```bash
flutter analyze --no-fatal-infos
flutter test
```

## Supabase Setup

See `supabase/README.md`.

Migrations currently include:
- Base schema
- RLS policies
- Default plan/pockets seed trigger function
- Ledger balance invariant (`transactions` as source of truth, `pockets.cached_balance` derived)
- Transaction source column for MPESA income tracking
- Default savings floor update (10% baseline)
- Dynamic pocket icon persistence + trigger-based icon auto-matching (`icon_key`, `icon_custom`)

## Current Status

Implemented:
- Onboarding redesign + SMS permission request
- MVP auth bootstrap (anonymous session + phone capture)
- Money plan CRUD and validation
- Pockets dashboard redesign (premium card style + floating nav)
- Allocation engine + simulate flow
- SMS parsing/listening and allocation trigger
- Spend + reallocation flows
- Unified in-app numeric keypad for numeric money inputs
- Dynamic pocket icons (auto-match + manual icon override/editing)
- Monthly spend visibility (dashboard summary + per-pocket spent this month)
- Behavioral report
- Theming/tokenized colors across UI components

In progress:
- Full Supabase phone OTP auth path
- Dedicated post-allocation result for real SMS-triggered allocations (not only simulate)
- E2E flow coverage and performance tuning
- Android SMS plugin runtime alignment for some environments (`recvSMS` MissingPluginException)

## Known Runtime Note (Android SMS)

If you see:
- `MissingPluginException` on `plugins.elyudde.com/recvSMS`

the `sms_advanced` plugin host/activity wiring is not fully aligned at runtime. This repo currently handles the failure gracefully in-app (fallback messaging), and the platform-level alignment is tracked as a next fix.

## Documentation

- Product requirements: `PRD.md`
- Execution status and phase plan: `plan.md`
- End-user/system behavior guide: `HOW_IT_WORKS.md`
