Financial Hub – Comprehensive Repository Report
1. Product vision recap

Financial Hub is envisioned as a behavioral financial operating system that restructures how individuals perceive and allocate money before they make spending decisions. According to the product requirements document (PRD.md), the system:

Auto‑allocates income into predefined pockets as soon as it is detected, using integer math so that the remainder goes to savings.

Displays balances by category, not as a lump‑sum total, to encourage mental accounting and reduce the temptation to overspend.

Protects savings structurally by locking it from direct spending or reallocation.

Introduces friction when users try to move money between categories, slowing down impulsive transfers.

Evolves in stages – a prototype without custody, an MVP that scales behavioural validation, and a production version with controlled payment integrations.

The prototype targets Android first, uses Flutter for the client and Supabase (PostgreSQL with row level security) for the backend. M‑Pesa SMS parsing is the only income source; there is no bank or paybill integration.

2. Implementation overview
2.1 Client architecture

The Flutter codebase is organised into three top‑level directories:

lib/core – platform‑agnostic services and utilities. Notable components include:

supabase_client.dart – initialises and exposes the Supabase client instance used across the app.

ledger_service.dart – enforces an append‑only transaction model for credits, debits and reallocations. Balances are never mutated directly; they are derived from the transactions table via a trigger updating pockets.cached_balance.

allocation_engine.dart – pure function that takes an income amount and a list of percentage rules (with a designated savings pocket), performs integer division (floor(income × pct / 100)) and returns a map of pocket IDs to amounts. Any remainder goes to savings.

sms_parser.dart – strict parser that only accepts income messages from the sender MPESA containing “Confirmed. You have received” along with a Ksh amount and a reference code. It extracts amount, reference, sender and timestamp. Messages that do not match this pattern or sender are ignored.

sms_income_listener.dart – wraps Android’s BroadcastReceiver for SMS. When an SMS arrives, it checks the sender and calls the parser. If parsing succeeds, it calls the allocation service to allocate income.

PocketsRepository.getLatestAllocation – a utility that inspects recent credit transactions to find the latest allocation event. It groups transactions by reference within a two‑minute window to compute the total received amount and a breakdown by pocket. This snapshot is used to display the most recent allocation result on the dashboard after an income event.

lib/features – high‑level modules representing user‑facing features. Each module contains its own screens, repositories and services. For example:

Onboarding – onboarding_screen.dart implements the three introductory pages and requests SMS permission. Users can skip or continue through the screens.

Authentication – auth_screen.dart handles phone number capture. Currently, the app uses an anonymous Supabase session plus stored phone, but the code is prepared to integrate with phone OTP in a later phase.

Money plan – includes screens for listing, creating and editing money plans. Validation ensures percentages sum to 100 % and that at least one pocket is a savings pocket with a minimum allocation of 10 %.

Pockets – pockets_screen.dart serves as the main dashboard. It displays summary metrics (spendable balance, locked savings, monthly spending, last allocation), lists pockets as cards with progress indicators, and offers buttons to reallocate, simulate income, view behaviour reports or edit the money plan.

Allocation – allocation_service.dart orchestrates the allocation process. It fetches plan allocations and pockets from the PocketsRepository, calls the core allocation engine, and records credit transactions via the ledger service. A bottom sheet (simulate_income_sheet.dart) allows manual simulation of income.

Spending – spend_sheet.dart provides a form to select a pocket and amount. It prevents spending from savings and insufficient balances and records debit transactions.

Reallocation – reallocate_sheet.dart implements a transfer flow with a friction timer (5–10 seconds) before confirmation. Savings cannot be a source pocket. Reallocations generate paired debit/credit transactions.

Behaviour – behavior_report_screen.dart displays counts of behavioural events (e.g. overspend attempts, reallocation events). This fosters awareness of financial discipline.

lib/shared – reusable components and design tokens. Colour palettes, spacing constants and typography styles are defined here. Widgets such as AppCard, PrimaryButton, SecondaryButton, PocketCard, BottomNav, WarningCard, AppScaffold and a custom numeric keypad input provide a consistent look and feel. The design emphasises minimalism and clarity, with soft shadows and a neutral palette.

2.2 Backend schema and policies

The supabase/migrations directory contains SQL scripts that create the database schema and security policies. Key points:

Tables:

profiles – one row per user; holds the Supabase auth.users.id and references the user’s active plan via default_plan_id.

pockets – represents categories. Each row belongs to a profile, has a name, an is_savings flag and a cached_balance integer maintained by triggers.

money_plans – defines allocation rules for a user. Only one plan can be active at a time.

money_plan_allocations – stores percentage allocations by pocket within a plan.

transactions – the immutable ledger. Each row has pocket_id, amount (positive for credits, negative for debits), type (credit/debit/reallocation_*), reference and timestamps. A database trigger updates pockets.cached_balance when transactions are inserted.

behavioral_events – logs overspend attempts, reallocation events and other behavioural signals.

RLS policies restrict SELECT, INSERT and DELETE operations to rows where user_id matches the authenticated user (auth.uid()). There are no policies permitting UPDATE on transactions or pockets; balances can only change through inserts.

Default plan seeding occurs via a trigger when a profile is created. It inserts a default money plan with one savings pocket and a few spendable pockets with recommended percentages.

2.3 Current feature set (summary)

The repository implements nearly all items in the Prototype (behavioural MVP) section of the PRD. Implemented capabilities include:

Onboarding with SMS permission request and skip option.

Anonymous session bootstrap (phone capture) and profile creation.

Money plan CRUD with validations (100 % total, savings minimum 10 %, exactly one active plan).

Pockets dashboard showing category balances, summary metrics and latest allocation details, with minimal emphasis on total balances.

Automatic income allocation triggered by strict MPESA SMS parsing; manual simulation flow for testing.

Spending flow that blocks savings and insufficient balances; records debit transactions.

Reallocation flow with friction timer and behavioural logging.

Basic behavioural reporting.

Core database schema with RLS, cached balances and seed triggers.

The plan file (plan.md) corroborates this: phases 0, 1, 3, 4, 6 and 7 are marked as complete, while phases 2 (full OTP auth), 5 (dedicated post‑SMS allocation UI) and 8 (polish and end‑to‑end testing) are in progress.

3. Comparison with the PRD

The PRD lays out the product vision and delineates requirements for the prototype, MVP expansion and production phases. Comparing these with the repository reveals the following:

PRD prototype requirement	Implemented?	Notes
Three‑screen onboarding with skip and SMS permission explanation	Yes	Implemented in onboarding feature.
Money plan with allocations summing to 100 %, savings ≥ 10 %, one active plan	Yes	Validation in money plan feature and database constraints.
Automatic income allocation using Android SMS parsing (filter MPESA only)	Mostly	Parsing is strict and only accepts sender MPESA, message with “Confirmed. You have received” and Ksh amount. Duplicate detection not yet implemented. A dedicated allocation result screen for real SMS remains to be finished.
Simulated income	Yes	User can simulate income via bottom sheet.
Allocation engine uses integer math; remainder to savings	Yes	Implemented in AllocationEngine; ledger service records transactions.
Pockets dashboard shows category balances; lump sum de‑emphasised	Yes	Dashboard emphasises per‑pocket balances and displays summaries.
Spending only from spendable pockets; block insufficient balance and spending from savings	Yes	Implemented in spend feature. Overspend attempts are logged.
Reallocation allowed with friction (delay, warning, confirmation)	Yes	Reallocation sheet includes 5–10 second timer before confirm button.
Behavioural logging (overspend attempts, savings withdrawal attempts, reallocation events, plan modifications)	Partly	Overspend and reallocation events are logged. Savings withdrawal attempts are blocked completely; there is no attempt log for savings because spending/reallocation from savings is prevented. Logging of plan modifications exists via triggers.
Clean minimal UI with savings visually protected	Yes (basic)	The UI is functional and clean but does not fully deliver the premium skeuomorphic aesthetic described in the PRD. A design upgrade is needed.
SMS data handled locally and raw bodies never stored	Yes	The parser and listener handle messages in memory and only persist parsed fields.
MVP expansion tasks

The PRD’s MVP section enumerates enhancements such as duplicate detection, server‑side validation, behavioural scoring, notifications and analytic dashboards. None of these are implemented yet. The plan reflects that Phase 8 tasks, including end‑to‑end testing and polish, are still ongoing.

Production phase considerations

The production roadmap involves integrating M‑Pesa APIs, bank APIs, and wallet sub‑accounts; introducing a real incoming_payments table; adding idempotent webhooks; and moving validation to the backend. The current code base does not include these, which is consistent with staying within the behavioural MVP scope.

4. Quality assessment
Architecture & modularity

The application is well‑structured. Separating core, features and shared encourages single‑responsibility classes and makes the codebase easy to navigate. Each feature is encapsulated with its own repository or service, and cross‑cutting concerns such as theming and spacing are centralised. This organisation will support the transition from prototype to production.

Data model & security

Using Supabase with row level security provides user‑level isolation on all tables. The transaction ledger is immutable; modifications to pocket balances are performed via inserts, which triggers a database function that aggregates balances. This is a sound approach for financial data integrity. However, the current client‑side enforcement of rules means a malicious client could bypass restrictions. Moving validations to Supabase edge functions (as planned) will mitigate this.

Input parsing and safety

The strict SMS parser reduces fraudulent allocations by ensuring only messages from the exact sender MPESA and with the expected wording are accepted. This aligns with the PRD’s security guidance. Nevertheless, the parser may need updates if Safaricom changes message formats; a configurable allowlist or pattern may be necessary to maintain reliability.

UI and UX

The existing UI implements the minimal, category‑centric layout prescribed by the PRD. Savings pockets are visibly locked, and reallocation friction is clearly presented. However, the UI does not yet exhibit the premium modern design (rounded cards, soft gradients, micro‑interactions) referenced in the latest user direction. A design system upgrade is required to deliver a polished experience comparable to high‑end mobile wallet applications.

Testing and performance

There are unit tests covering allocation logic, SMS parsing and money plan validation. Some widget tests exist. However, there are no end‑to‑end tests verifying the full user journey (onboarding → auth → income allocation → spending → reallocation → report). The plan acknowledges this gap. Performance profiling and optimisation have not yet been done, which could affect startup time, frame rendering and battery usage on low‑end devices.

5. Key areas for improvement

Based on the analysis, the primary areas needing attention to finish the MVP and move toward production are:

Authentication – complete the phone OTP flow using Supabase Auth. This includes sending verification codes, handling errors, persisting sessions and migrating from anonymous accounts.

Dedicated allocation result screen for SMS events – replicate the “simulate income” breakdown for real incoming allocations so users understand how their income was distributed.

End‑to‑end tests and performance profiling – implement tests that cover the entire flow and run them in CI. Profile the app on multiple devices to identify jank and startup issues and apply optimisations.

Server‑side validation and duplicate detection – move allocation, spending and reallocation validation logic into Supabase edge functions. Implement a unique constraint on transaction references or an incoming payments table to avoid double‑allocation of the same SMS.

Behavioural scoring and notifications – extend behavioral_events to derive a discipline score and present it in the insights screen. Use FCM (Firebase Cloud Messaging) or Supabase functions to send push notifications when overspend attempts occur.

Premium UI upgrade – adopt a refined design system with larger corner radii, soft elevation, gradient buttons, improved typography hierarchy, micro‑interactions and a floating navigation bar. This should be implemented through reusable widgets and theme tokens to avoid duplication.

M‑Pesa and bank API integration (production phase) – create a new incoming_payments table, implement idempotent webhook handlers via Supabase Edge Functions, and add flows to manage real money transfers. Integrate with M‑Pesa Daraja API for push STK requests or paybill collections. Bank integrations should use open banking where available.

Security hardening – enforce strict RLS on all tables, require JWT checks in Supabase Edge Functions, and ensure the app never stores raw SMS messages. Consider encrypting sensitive data in transit and at rest.

6. Conclusion

The Financial Hub project presents a well‑thought‑out foundation for a behavioural financial operating system. The current repository already implements most of the prototype requirements, demonstrating how income is auto‑allocated, spending is controlled, savings is protected, and behavioural cues are logged. The architecture is modular, the database schema is sound and the user interface communicates the core financial philosophy. To reach a polished MVP and eventually production readiness, the team should address the remaining tasks identified above—completing authentication, finishing the allocation result UX, writing end‑to‑end tests, migrating validations to the backend, enriching behaviour analytics, upgrading the design system and planning for API integrations and security hardening. With these refinements, Financial Hub can evolve from a prototype into a robust platform for disciplined personal finance.