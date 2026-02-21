Financial Hub
Behavioral Financial Operating System
 Android-First | Flutter + Supabase

1. PRODUCT VISION
Financial Hub is a behavioral financial operating system that restructures how individuals perceive and allocate money before spending decisions occur.
The system:
Auto-allocates income into predefined pockets


Displays category balances instead of lump-sum totals


Protects savings structurally


Introduces behavioral friction for impulsive reallocation


It launches as a behavioral prototype and evolves into a production-grade financial infrastructure application.

2. PRODUCT EVOLUTION ROADMAP
Stage
Focus
Financial Custody
Integration Level
Prototype
Behavioral validation
None
SMS parsing only
MVP
Scaled behavioral beta
None
SMS + structured ingestion
Production
Financial infrastructure
Limited / Controlled
API integrations


3. PROTOTYPE (BEHAVIORAL MVP)
3.1 Objective
Validate:
Perception shift (category-based thinking)


Reduction in impulsive spending


Protection of savings


Emotional response to allocation limits


No regulatory exposure. No custody.

3.2 Target Platform
Android only


Flutter


Supabase (Auth + Postgres)



3.3 Core Functional Requirements
3.3.1 Onboarding
3-screen introduction (skippable)


SMS permission explanation


Phone OTP authentication


Default money plan (editable)



3.3.2 Money Plan
Rules:
Percentages must total 100%


Savings ≥ 10%


Exactly one active plan


Editable anytime


Categories:
Savings (locked)


Multiple spendable pockets



3.3.3 Income Detection
Source:
Android SMS (READ_SMS permission)


Filter MPESA sender (exact match only; exclude variants such as M-PESA to avoid fraud—only real payment SMS from the official sender use MPESA)


Regex-based parsing


Flow:
SMS detected


Income parsed


Allocation auto-executed


User sees post-allocation breakdown


Manual fallback:
“Simulate income” button


No Daraja API.
 No webhooks.
 No Paybill integration.

3.3.4 Allocation Engine
Rules:
Integer math only


floor(income × percentage / 100)


Remainder assigned to Savings


Allocation occurs automatically


User never sees lump sum first.

3.3.5 Pockets Dashboard
Card-based UI


Category balances only


Savings visually locked


Total balance minimized



3.3.6 Spending
Rules:
Only from spendable pockets


Reject insufficient balance


Reject spending from Savings


Log overspend attempts



3.3.7 Manual Reallocation
Allowed with friction:
Warning modal


5–10 second delay


Confirmation step


Savings minimum preserved


Behavioral event logged



3.3.8 Behavioral Logging
Track:
Overspend attempts


Savings withdrawal attempts


Reallocation events


Plan modifications


Spend within budget


Purpose:
 Generate impact report.

3.4 Database Schema (Prototype Level)
Tables:
profiles
 pockets
 money_plans
 money_plan_allocations
 transactions (ledger-lite, append-only)
 behavioral_events
No:
Incoming_payments table


Webhook endpoints


Idempotency constraints


Atomic financial locks



3.5 Non-Functional Requirements
Clean minimal UI


Android performance optimized


SMS parsed locally


No raw SMS stored unless necessary


RLS enabled (basic)
4. MVP (BETA EXPANSION)
After prototype validation.
4.1 Objective
Scale to 100–1,000 users.
 Improve reliability.
 Prepare infrastructure foundation.

4.2 Enhancements
Income Ingestion Improvements
Structured SMS parser


Duplicate detection logic


Better pattern handling


Backend Hardening
Move allocation validation server-side


Edge Functions for:


Allocation validation


Spend validation


Reallocation enforcement


Ledger Upgrade
Immutable append-only ledger


Deterministic processing


Unique constraints for source reference


Analytics Dashboard
User discipline score


Savings growth trend


Overspend frequency



4.3 Feature Additions (Limited)
Savings goal progress tracking


Behavioral scoring system


Push notifications for overspend warnings


Improved UX animations


Still:
No custody


No paybill processing


No SME features



5. PRODUCTION VERSION
5.1 Objective
Transition from behavioral OS to controlled financial flow system.

5.2 Financial Integration Phase
Possible integrations:
M-Pesa Daraja API


Bank APIs (Open Banking where available)


Wallet sub-account enforcement


Architecture changes:
Real incoming_payments table


Idempotent webhook ingestion


Postgres transactional allocation


Row locking for consistency


Real-time spend validation via backend



5.3 Security Upgrade
Strict RLS policies


Service role isolation


Edge Function-only ledger writes


Audit logging


Encrypted sensitive data



5.4 Optional Advanced Features
Selective rail control


Conditional transfers


Automated savings transfers


SME multi-user accounts (separate product track)



6. UX DESIGN PRINCIPLES (ALL STAGES)
Never emphasize lump sum total


Savings visually protected


Friction over freedom


Minimal but premium interface


Subtle depth (light skeuomorphic cues)


Financial clarity over gamification

Financial Hub is not a bank.
It begins as a behavioral financial operating system that restructures financial perception.
 It validates discipline before building financial rails.
 It scales responsibly into infrastructure once behavioral product-market fit is proven.


