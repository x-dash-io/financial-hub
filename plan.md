# Financial Hub – Build Plan

## Phase 0: Project Setup (Week 1)

- Initialize Flutter project with Android-only configuration
- Add Supabase Flutter SDK and configure project
- Set up folder structure: `lib/core`, `lib/features`, `lib/shared`
- Configure environment (dev/staging keys)
- Set up basic CI (e.g., GitHub Actions) for lint and tests

## Phase 1: Backend Foundation (Week 1–2)

**Supabase setup**

- Create Supabase project; enable Auth (phone OTP)
- Create schema and migrations in Supabase:
  - `profiles` (user_id FK to auth.users)
  - `pockets` (profile_id, name, balance, is_savings)
  - `money_plans` (profile_id, name, is_active)
  - `money_plan_allocations` (plan_id, pocket_id, percentage)
  - `transactions` (pocket_id, amount, type, reference, created_at)
  - `behavioral_events` (profile_id, event_type, payload JSON, created_at)
- Apply basic RLS policies (all tables scoped by auth.uid via profiles)
- Seed default money plan template

## Phase 2: Auth and Onboarding (Week 2–3)

- Implement 3-screen intro (skippable) using PageView
- Request and handle `READ_SMS` permission with clear explanation
- Implement phone OTP auth via Supabase Auth
- Create profile and default money plan on first sign-in
- Persist onboarding completion

## Phase 3: Money Plan and Pockets (Week 3–4)

- Money plan CRUD with validation: percentages sum to 100%, Savings ≥ 10%
- Default categories: Savings (locked), plus 2–3 spendable pockets
- Pockets dashboard UI: card-based, category balances, Savings visually distinct
- Minimize total balance emphasis per UX principles

## Phase 4: Allocation Engine (Week 4–5)

- Implement allocation logic in Dart: integer math, `floor(income × pct / 100)`, remainder → Savings
- Integrate with Supabase: create transactions per pocket, update balances
- Allocation triggered only after successful income parsing (no lump sum shown first)

## Phase 5: SMS Income Detection (Week 5–6)

- Register SMS receiver (BroadcastReceiver) for MPESA messages only (sender = "MPESA"; reject M-PESA and other variants to prevent fraud)
- Implement regex parser for amount, date, reference
- On parse success: run allocation engine, show post-allocation breakdown
- Add "Simulate income" button for manual testing and fallback
- Do not persist raw SMS; parse in-memory only

## Phase 6: Spending and Validation (Week 6–7)

- Spending UI: select pocket, enter amount
- Client-side checks: reject insufficient balance, reject spend from Savings
- Create debit transaction; log overspend/withdrawal attempts in `behavioral_events`
- Update pocket balance via Supabase

## Phase 7: Manual Reallocation with Friction (Week 7–8)

- Reallocation flow: source pocket → destination pocket
- Warning modal with 5–10 second delay, confirmation step
- Enforce Savings minimum; block reallocating below 10% of plan
- Log reallocation in `behavioral_events`

## Phase 8: Polish and Validation (Week 8–9)

- Behavioral logging completeness check
- UI polish: clean, minimal, subtle depth
- Basic impact/behavior report (e.g., overspend count, reallocation count)
- End-to-end testing of core flows
- Performance pass for Android

## Key Files Structure

```
lib/
├── main.dart
├── core/
│   ├── allocation_engine.dart
│   ├── sms_parser.dart
│   └── supabase_client.dart
├── features/
│   ├── onboarding/
│   ├── auth/
│   ├── money_plan/
│   ├── pockets/
│   ├── allocation/
│   ├── spending/
│   └── reallocation/
└── shared/
    ├── models/
    └── widgets/
```
