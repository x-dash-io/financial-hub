Findings: Financial Hub Repository Analysis

This document summarises the current state of the Financial Hub project based on the contents of the GitHub repository x‑dash‑io/Financial‑Hub. The goal was to identify what has been implemented, how the code is structured and where there are gaps relative to the product requirements.

Repository structure

The project follows a modular Flutter architecture:

Path	Purpose
lib/core/	Core services such as the Supabase client, allocation engine, SMS parsing, and ledger service. These files encapsulate the business logic and data access.
lib/features/	Feature‑specific modules for onboarding, authentication, money plan management, pockets dashboard, allocation, spending, reallocation and behaviour reporting. Each feature exposes its own screen(s), repositories and service classes.
lib/shared/	Shared models and UI components. Includes theme definitions (app_colors.dart, app_text.dart, app_theme.dart, app_shadows.dart), reusable widgets (AppCard, PrimaryButton, PocketCard, etc.) and model classes (Pocket, LatestAllocationSnapshot).
supabase/migrations/	SQL migration scripts that create tables (profiles, pockets, money_plans, money_plan_allocations, transactions, behavioral_events) and apply row level security (RLS) policies and triggers. A trigger maintains pockets.cached_balance from the transactions ledger.
test/	Unit and widget tests for core logic (SMS parser, allocation engine, money plan validation) and regression tests.

The root of the repository also includes high‑level documentation:

README.md – summarises the product, tech stack, project structure and how to run the app. It lists implemented features such as onboarding, anonymous auth, money plan CRUD, pockets dashboard, allocation engine, SMS parsing, spending, reallocation and behaviour reporting. It also notes that the full phone OTP flow and post‑SMS allocation result screen are still in progress.

PRD.md – the product requirements document describing the vision, roadmap, prototype/MVP/production phases, core functional requirements, non‑functional requirements, and UX principles.

plan.md – a build plan updated on 2026‑02‑21 that records what has been implemented, what is in progress and what remains to be done across eight phases (project setup, backend foundation, auth and onboarding, money plan and pockets, allocation engine, SMS detection, spending, reallocation, polish & validation).

HOW_IT_WORKS.md – explains the user journey, savings rules, allocation logic, data model, and UX principles currently in place.

Implemented features and code evidence

The code base already covers a substantial portion of the behavioural MVP described in the PRD:

Onboarding flow – A three‑screen introduction is implemented in lib/features/onboarding/onboarding_screen.dart. It explains the product, requests SMS permission and can be skipped.

Authentication (MVP) – The app uses an anonymous Supabase session with phone capture via auth_screen.dart. Phone numbers are stored but no OTP verification is applied yet (this is still in progress).

Money plan management – lib/features/money_plan includes screens and logic to create, update, activate and delete money plans. Validation ensures percentages sum to 100 % and that at least one pocket is a savings pocket with a minimum of 10 % allocation. Only one active plan exists per user. Default plans/pockets are seeded via Supabase migrations.

Pockets dashboard – The PocketsScreen (lib/features/pockets/pockets_screen.dart) shows a summary of today’s spendable balance, locked savings, spent this month and the last allocation time. It lists pockets as cards with their balances, progress and icons. The dashboard hides lump‑sum totals and emphasises category balances. Users can open the money plan, behaviour report or log out via the top app bar and bottom navigation.

Allocation engine – lib/features/allocation/allocation_service.dart orchestrates the allocation of income. It retrieves the active plan and pockets, builds allocation rules, calls the AllocationEngine (integer math; remainder to savings) and records credit transactions via the LedgerService. The allocation result is a map from pocket ID to amount.

Ledger model – lib/core/ledger_service.dart defines recordCredit, recordDebit and recordReallocation. Each method inserts a transaction row; a Supabase trigger updates pockets.cached_balance. The ledger is the only source of truth for balances; direct balance mutations are prohibited.

SMS income detection – lib/core/sms_parser.dart contains MpesaSmsParser, a strict parser that accepts only sender MPESA and messages containing “Confirmed. You have received”, a Ksh amount and an alphanumeric reference. Parsed results include amount, reference, timestamp and sender. SmsIncomeListener (in sms_income_listener.dart) registers an Android BroadcastReceiver for SMS messages, invokes the parser and triggers allocation when income is detected. Raw SMS bodies are never stored.

Simulated income – Users can open a bottom sheet to simulate income for testing. The same allocation logic is used. This is available via the Simulate button on the pockets dashboard.

Latest allocation snapshot – The repository includes a helper in PocketsRepository (getLatestAllocation) that groups recent credit transactions with the same reference into a LatestAllocationSnapshot. This enables the UI to display the most recent income allocation with a breakdown by pocket and total received amount. It filters credit transactions within a short time window and aggregates them into a summary object, which is then shown in the dashboard.

Reallocation duplicate‑key crash fix – A recent update fixed a crash caused by duplicate primary keys during reallocation. The ledger service now inserts paired debit/credit rows atomically to avoid constraint violations during reallocation operations.

Debug banner removed – The Flutter debug banner (debugShowCheckedModeBanner) has been disabled in the main app configuration, giving the application a more polished appearance in development builds.

Spending and validation – lib/features/spending/spend_sheet.dart lets users pick a spendable pocket and amount. It checks that the selected pocket is not the savings pocket and that the requested amount does not exceed the balance. Debit transactions are recorded via the ledger service. Overspend attempts are blocked and recorded.

Reallocation with friction – lib/features/reallocation/reallocate_sheet.dart allows moving funds between pockets. The UI introduces a countdown timer (5–10 seconds) before the confirm button becomes active. Reallocations insert paired debit/credit transactions and are logged as behavioural events. Savings remains locked and cannot be used as a source pocket.

Behavioural reporting – Basic behavioural insight is presented in behavior_report_screen.dart. It queries the behavioral_events table and displays counts of overspend attempts, reallocation events, etc. This gives users feedback about their discipline.

Theme and widgets – The project defines a consistent design system (app_colors.dart, app_text.dart, app_spacing.dart, app_shadows.dart) and uses reusable widgets (AppCard, PrimaryButton, SecondaryButton, PocketCard, BottomNav, etc.). The design is minimal and modern, with subtle elevation and clear typography. These tokens enable future UI refinement.

Database schema & RLS – SQL migrations create the necessary tables and apply row level security to restrict access to each user’s data. There are triggers to maintain cached balances and to seed a default plan on profile creation. The prototype does not yet include an incoming_payments table or webhooks, consistent with the behavioural MVP.

Gaps and limitations relative to the PRD

OTP authentication – The full phone OTP flow (via Supabase Auth) is not completed. The current implementation relies on an anonymous session with phone capture, which reduces security and prevents account recovery.

Dedicated post‑allocation result for real SMS – When real SMS income is detected, the app currently shows a snackbar and refreshes the dashboard. The PRD calls for a dedicated allocation result screen to mirror the simulated income experience. This is marked “In progress” in the plan.

End‑to‑end tests & performance tuning – The repository contains unit/widget tests but lacks comprehensive end‑to‑end tests. Android performance profiling and optimisations (e.g. cold‑start time, jank) have not been performed.

Server‑side enforcement and duplicate detection – Allocation, spending and reallocation validations occur on the client. The PRD envisions moving validation to Supabase edge functions and adding duplicate detection for incoming messages (to prevent double allocation). These are scheduled for MVP expansion and are not present in the code.

Behavioural scoring and analytics – Although basic event logging exists, there is no scoring system or advanced analytics dashboard. The plan lists this as a future enhancement.

Push notifications – The PRD suggests overspend warning notifications. There is no push notification implementation yet.

Incoming payments APIs – The prototype relies exclusively on SMS parsing for income detection and does not integrate with the M‑Pesa Daraja API or any bank APIs. Such integrations are deferred to the production phase.

Savings lock configuration – Savings is always locked; there is no time‑based unlocking or configurable lock period. The PRD mentions this as a potential future enhancement.

Premium UI refinement – The current UI is functional and clean but does not fully achieve the premium, skeuomorphic feel described in the PRD and the provided reference designs. Upgrading the design system (rounded cards, soft shadows, gradients, animations) is still required.

Quality observations

Modular architecture – The separation into core, features and shared promotes maintainability and clear boundaries between business logic and UI.

Ledger model – Using an append‑only transaction table with derived balances is appropriate for financial applications. The LedgerService enforces positive/negative amount rules.

Strict SMS parser – The parser accepts only messages whose sender is exactly MPESA (case‑sensitive, no hyphen) and that contain the phrase “Confirmed. You have received” along with a Ksh amount and an alphanumeric reference. This hardening significantly reduces fraud risk, as other variants (M‑PESA, short codes, etc.) are ignored. However, it could miss legitimate messages if Safaricom changes the sender format; a configurable allow‑list or remote configuration may be required in the future.

Client‑side validation – Many financial rules (e.g. savings protection, insufficient balance) are enforced on the client. Without server‑side checks, a compromised or modified client could circumvent these rules. The PRD’s MVP expansion addresses this by proposing edge functions for validation.

Theme tokens – The design system is flexible; adding a premium visual layer will be straightforward without disrupting underlying logic.

Conclusion

The repository provides a solid foundation for the behavioural MVP. Most core features outlined in the PRD prototype phase are implemented: onboarding, basic auth, money plan management, pockets dashboard, allocation engine, SMS parsing, spending, reallocation with friction, behavioural logging and a consistent design system. However, several important items remain unfinished or require improvement to deliver a polished MVP and a production‑ready financial app. The next sections (refinements and plan) will detail specific recommendations and a roadmap for completion.