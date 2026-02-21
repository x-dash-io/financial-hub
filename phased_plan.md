Financial Hub – Roadmap to MVP Completion and Production Readiness

This plan builds on the existing build phases in plan.md and incorporates the refinements required to finish the behavioural MVP and to transition into a production‑ready financial application. Time estimates are approximate and assume a small team working part‑time. Tasks can run in parallel when resources permit.

Phase 1: Finalise MVP Authentication and Allocation UX (1–2 weeks)

Phone OTP authentication

Implement phone number verification via Supabase Auth.

Migrate existing anonymous sessions to verified sessions or prompt users to re‑register.

Add server‑side checks to ensure unique phone numbers.

Dedicated post‑SMS allocation screen

Build a bottom sheet or page that displays the amount received, pocket breakdown and timestamp for real SMS‑triggered allocations.

Update the SmsIncomeListener to navigate to this screen after allocation.

UI polish for existing screens

Fix minor alignment/spacing issues.

Remove debug banners and review copy for clarity.

Phase 2: End‑to‑End Testing & Performance Optimisation (1–2 weeks)

Integration tests

Use Flutter’s integration testing tools to write tests covering onboarding → auth → money plan → allocation (simulation and SMS) → spend → reallocate → behaviour report.

Mock Supabase responses as needed to run in CI.

Performance profiling

Measure cold start time, frame rendering, memory use and battery impact on a range of Android devices.

Identify and fix slow operations (e.g. database calls on the UI thread, unnecessary rebuilds).

Continuous integration

Extend GitHub Actions to run integration tests on each pull request.

Fail builds when tests fail or when performance budgets are exceeded.

Phase 3: Backend Hardening & De‑duplication (2–3 weeks)

Edge Functions for validation

Implement functions to validate allocations, spends and reallocations based on the stored plan and pocket balances.

Reject attempts to spend from savings or exceed balances, even if the client is compromised.

Incoming payments table and duplicate detection

Create an incoming_payments (or sms_events) table with columns for reference, amount, sender and processed flag.

Add a unique constraint on the reference to prevent duplicate allocations.

Update the SMS listener to write to this table and check the processed flag before allocating.

Idempotent transactions

Add idempotency keys to reallocation and spend requests so repeated requests do not cause duplicate debits/credits.

Phase 4: Behavioural Scoring and Notifications (2 weeks)

Discipline score

Define a scoring algorithm using behavioural events (e.g. overspend attempts vs. valid spends, frequency of reallocations).

Store scores in the database and display them in the insights screen with contextual guidance.

Enhanced analytics dashboards

Develop simple charts (bar/line) for monthly spending, savings growth and allocation history.

Use the existing design system and consider leveraging chart libraries available for Flutter.

Push and local notifications

Integrate Firebase Cloud Messaging (or Supabase notifications) to send push notifications for new income allocations, overspend blocks and reallocation reminders.

Implement local notifications for offline reminders.

Phase 5: Premium UI Revamp (2–3 weeks)

Design system upgrade

Define new colour palettes, typography scales, corner radii and elevation/shadow styles inspired by premium fintech apps.

Implement these tokens in lib/shared/theme and update AppCard, buttons, inputs, navigation and other widgets.

Component refactoring

Create new reusable components for premium cards, buttons (with gradients), floating navigation bar and skeleton loaders with shimmer animations.

Refactor existing screens to use the new components.

Micro‑interactions & animations

Animate pocket balance changes, allocation result cards and friction timers.

Use hero animations for transitions (e.g. from pocket card to detail sheet).

Responsiveness

Test layouts on various screen sizes and adjust to avoid overflow or cramped elements on small devices.

Phase 6: MVP Release & Feedback Loop (1 week)

Soft launch

Release the polished MVP to a small group of users (50–100) in the target demographic.

Collect feedback on onboarding, allocation clarity, UI satisfaction and perceived discipline improvement.

Bug fixing & quick iterations

Address critical bugs or UX issues reported during the soft launch.

Prepare a minor patch release if necessary.

Success metrics

Measure key indicators such as user retention, frequency of overspend attempts, savings growth and average reallocation delays.

Phase 7: Production Roadmap (3–6 months)

After validating the behavioural MVP, transition towards production readiness:

API integrations

Integrate with M‑Pesa Daraja API for push STK requests and paybill settlement.

Add bank integrations using open banking APIs or aggregator services where available.

Introduce a incoming_payments table and webhook handlers for real money flow.

Financial controls

Implement row locking and transactional consistency in Postgres via Supabase functions to handle concurrent incoming payments and spends.

Enforce stricter auditing and logging for financial operations.

Security and compliance

Encrypt sensitive data (phone numbers, references) at rest.

Add JWT validation and service role isolation in all server‑side functions.

Conduct a security audit and penetration testing to satisfy regulatory requirements.

Scalability

Optimise database indexes and queries for higher user volumes.

Explore horizontal scaling options for Supabase or consider migrating heavy workloads to dedicated back‑end services.

User administration

Build account recovery and multi‑device sync features.

Provide a settings page for users to configure savings lock duration and notification preferences.

SME & multi‑user support (optional)

Introduce role‑based access (owners, treasurers, members) for small saving groups (chamas).

Add features for joint pockets and shared transaction approvals.

Conclusion

By following this roadmap, the Financial Hub team can systematically finish the behavioural MVP, deliver a polished and engaging user experience, and then evolve the platform into a production‑ready application with robust financial integrations and enterprise‑grade security. Regular feedback loops and testing at each phase will help ensure the product meets users’ needs while adhering to the behavioural finance principles that underpin the vision.