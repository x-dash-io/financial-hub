# How Financial Hub Works

This document explains the current user flow, product behavior, and savings rules.

Repository: https://github.com/x-dash-io/Financial-Hub.git

## 1. User Journey (Simple Flow)

1. Onboarding
- User sees 3 short screens.
- User can skip or continue.
- App requests SMS permission for MPESA income detection.

2. Registration
- User registers with phone input.
- Current MVP uses anonymous Supabase session + stored phone (OTP path is planned).

3. Pockets Dashboard
- User lands on premium-style category pocket cards, not a lump-sum-first view.
- Savings pocket is clearly marked as locked.
- Spendable pockets are tappable for spending.
- User sees monthly spending insights (overall + per-pocket).

4. Income Allocation
- Income is detected from strict sender `MPESA` or manually simulated.
- Income is allocated by percentage rules.
- Result shows pocket-by-pocket breakdown.

5. Spending
- User picks a spendable pocket and amount.
- Amount entry uses in-app numeric keypad (finance flows use consistent keypad UX).
- Savings cannot be spent from directly.
- Overspend is blocked.

6. Reallocation
- User moves money between spendable pockets.
- Countdown friction must complete before confirm.
- Savings stays protected.

7. Behavior Insights
- App shows event counts (overspend attempts, reallocation, etc.).

## 2. Savings Rules (Important)

Current savings behavior:
- Minimum savings allocation: **10%**
- Default seeded savings allocation: **10%**
- Savings lock: **always on** (no expiry timer right now)
- Direct spending from Savings: **not allowed**
- Savings as source in reallocation: **not allowed**

What can be changed now:
- You can change the savings percentage anytime in **Money Plan**.
- Validation still enforces minimum 10%.

What is not time-configurable yet:
- Lock duration/period is not currently a user setting.
- The current model is continuous lock protection.

## 3. Allocation Logic

- Integer math only:
  - `floor(income * percentage / 100)`
- Any remainder is assigned to Savings.
- Ledger writes are transaction-based.
- `pockets.cached_balance` is updated by DB trigger from transactions.

## 4. Data + Security Model

- Core tables:
  - `profiles`
  - `money_plans`
  - `pockets`
  - `money_plan_allocations`
  - `transactions`
  - `behavioral_events`
- RLS is enabled and scoped per authenticated user via profile ownership.
- Raw SMS body is not persisted by app logic.

## 5. UX Principles Used

- Category-first presentation instead of lump-sum emphasis
- Minimal steps for common actions
- Clear constraint messaging (locked savings, insufficient balance, etc.)
- Reallocation friction to discourage impulsive movement
- Consistent in-app numeric keypad for money/percentage input
- Pocket icon semantics are dynamic: auto-match by name with optional manual override

## 6. Pocket Icons (Dynamic)

- Pocket icon metadata is persisted in DB:
  - `icon_key`
  - `icon_custom`
- If `icon_custom = false`, icon is auto-derived from pocket name keywords.
- If `icon_custom = true`, user-selected icon is respected.
- Savings icon is always enforced as `savings`.

## 7. Android SMS Runtime Note

On some Android runs you may see:
- `MissingPluginException` on `plugins.elyudde.com/recvSMS`

Current behavior:
- App falls back gracefully (SMS auto-detect unavailable message).

Tracked platform fix:
- Align host activity/plugin runtime wiring for `sms_advanced` and validate on clean reinstall.

## 8. Time-Based Savings Lock (Future)

A future enhancement can introduce lock periods (for example: 7 days, 30 days):
- Add a lock configuration field (e.g., `savings_unlock_at` or lock policy table).
- Enforce unlock checks in spending/reallocation services.
- Expose lock-period controls in Money Plan UI.

Current version does not implement this yet; it uses always-on lock.
