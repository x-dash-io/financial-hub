# Financial Hub - Build Plan (Status Updated)

Last updated: 2026-02-21

## Snapshot

### Implemented
- Project scaffolding, folder structure, `.env` setup, and CI (`flutter analyze` + `flutter test`)
- Supabase schema migrations for profiles, plans, pockets, allocations, transactions, behavioral events
- RLS policies and default plan seeding migrations
- Onboarding redesign (3 screens max, skippable, illustration placeholders, page dots, SMS permission/privacy step)
- Session/bootstrap auth flow (MVP anonymous session + phone capture)
- Money plan management (create, update, activate, delete) with validation
- Pockets dashboard redesign (premium card style, floating pill nav, savings lock badge)
- Allocation engine (integer math, remainder to savings) + transaction-based ledger writes
- SMS listener/parser for strict `MPESA` sender matching and parsed allocation trigger
- Simulate income flow with upgraded allocation result UI and "View pockets" CTA
- Spending flow with savings lock, insufficient-balance checks, behavioral logging
- Reallocation flow with friction countdown, confirmation, and behavioral logging
- Basic behavior report screen
- Reallocation duplicate-key crash fix
- Dynamic pocket icon system (expanded icon catalog, auto-match by name, custom icon picker/edit, DB-backed icon fields)
- In-app numeric keypad across finance inputs (spend, reallocate, simulate, money-plan percentage)
- Animated pocket balance numbers on card refresh
- Monthly spend visibility (per-pocket and dashboard summary; sourced from debit transactions)
- Debug banner removed (`debugShowCheckedModeBanner: false`)

### In Progress
- Replace MVP anonymous auth with full Supabase phone OTP auth flow
- Ensure real SMS-triggered allocations always show a post-allocation result screen (not only snackbar/dashboard refresh)
- Android SMS plugin runtime fix (`MissingPluginException` on `plugins.elyudde.com/recvSMS`): align host activity with plugin requirement and verify cold start behavior
- Broader product polish and consistency hardening across all interaction states

### Not Started
- End-to-end integration/UI tests for complete user journeys
- Android performance profiling/tuning pass
- MVP expansion items from PRD section 4 (duplicate detection, server-side/edge validation, behavioral scoring, push notifications)

## Phase Status

## Phase 0: Project Setup
Status: Completed
- [x] Initialize Flutter project (Android-first)
- [x] Add Supabase Flutter SDK and basic configuration
- [x] Set up folders (`core`, `features`, `shared`)
- [x] Configure local environment keys
- [x] Add basic CI workflow

## Phase 1: Backend Foundation
Status: Completed (app-side)
- [x] Create schema and migrations
- [x] Apply baseline RLS policies
- [x] Seed default plan and default pockets
- [x] Add ledger balance trigger model (`cached_balance` maintained from transactions)
- [ ] Supabase console-level auth provider configuration verification checklist

## Phase 2: Auth and Onboarding
Status: In Progress
- [x] 3-screen intro with skip + redesigned premium onboarding visuals
- [x] SMS permission + privacy note path
- [x] Persist onboarding completion
- [x] Create/ensure profile + default plan bootstrap
- [ ] Phone OTP auth (currently MVP anonymous session + phone capture)

## Phase 3: Money Plan and Pockets
Status: Completed
- [x] Money plan CRUD with validation (100% total, savings floor, naming checks)
- [x] Default categories with locked savings
- [x] Pockets dashboard (premium wallet card style, category-first presentation)
- [x] Keep total-balance emphasis low
- [x] Pocket icon automation + custom icon selection/editing
- [x] Persistent icon metadata in DB (`icon_key`, `icon_custom`) with dynamic trigger-based defaults

## Phase 4: Allocation Engine
Status: Completed
- [x] Integer allocation math and remainder-to-savings rule
- [x] Persist allocation through transaction inserts
- [x] Trigger/derived balance model via DB trigger
- [x] Category-first post-allocation UX in simulate flow

## Phase 5: SMS Income Detection
Status: In Progress
- [x] SMS receiver with strict sender filter (`MPESA` only)
- [x] Parser for amount/reference + timestamp handling
- [x] Parse success triggers allocation
- [x] Simulate income fallback
- [x] Do not persist raw SMS body
- [ ] Dedicated post-allocation breakdown screen for real incoming SMS events

## Phase 6: Spending and Validation
Status: Completed
- [x] Spend UI and pocket selection
- [x] Reject spend from savings
- [x] Reject insufficient balance
- [x] Record debit transactions
- [x] Log behavioral events for attempts and valid spends
- [x] Show spend insights in dashboard (monthly total + per-pocket monthly spent)
- [x] Unified in-app numeric keypad for spend amount entry

## Phase 7: Manual Reallocation with Friction
Status: Completed
- [x] Source/destination pocket flow
- [x] Friction timer and confirmation gating
- [x] Reallocation ledger writes
- [x] Behavioral event logging

## Phase 8: Polish and Validation
Status: In Progress
- [x] Basic behavior report screen
- [x] Core unit/widget tests for parser/allocation/money-plan/reallocation-key regression
- [x] Animated balance transitions on pocket cards
- [x] Floating pill-style bottom navigation
- [ ] Full end-to-end flow testing
- [ ] Performance pass for Android
- [ ] Final UX polish review against PRD copy/interaction standards

## Next Priority Queue

1. Fix Android SMS plugin runtime issue (`recvSMS` MissingPluginException) by aligning activity/plugin host requirements and validating on clean install.
2. Implement Supabase phone OTP auth and remove anonymous session fallback.
3. Add a reusable allocation-result route for both simulated and SMS-triggered income events.
4. Add e2e tests for onboarding/auth -> allocation -> spend/reallocate -> report flow.
5. Run Android performance and startup profiling, then apply targeted optimizations.
