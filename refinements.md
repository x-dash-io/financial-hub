Refinements to Complete the MVP and Improve the Product

This document outlines specific improvements and refinements recommended after analysing the current Financial Hub repository. These tasks focus on finishing the behavioural MVP, polishing the user experience and laying the groundwork for the future production‑grade application.

1. Authentication

Implement Supabase phone OTP authentication – Replace the anonymous session plus phone capture with a full OTP flow. This requires:

Integrating Supabase Auth’s phone verification APIs to send and verify codes.

Handling error cases (invalid code, network errors, timeouts) gracefully.

Migrating existing anonymous profiles to verified profiles or merging them where appropriate.

Persisting session tokens securely on the device.

Enforce single account per phone number – Ensure that each phone number maps to only one profile row. Consider unique constraints and server‑side checks to prevent duplication.

2. Allocation result UX for SMS events

Dedicated allocation result screen – When income is detected from SMS, display a bottom sheet or page that mirrors the simulated income breakdown. It should show how each pocket was credited, the timestamp and the reference code. This provides transparency and reduces confusion.

Navigate automatically – From the pockets dashboard, navigate to the result screen rather than just showing a snackbar. After dismissal, return to the dashboard and refresh the state.

3. End‑to‑end testing and quality assurance

Write integration tests using Flutter’s integration_test package to cover the full user journey: onboarding → auth → money plan creation → SMS simulation → spending → reallocation → behaviour report.

Set up CI for integration tests – Extend the existing GitHub Actions workflow to run these tests on at least one device emulator. Fail the build if tests fail.

Performance profiling and optimisation – Use Flutter DevTools on physical devices to measure cold start time, frame rendering and memory usage. Address jank (e.g. by deferring heavy operations) and reduce startup overhead (e.g. by lazy loading modules).

4. Server‑side validation and de‑duplication

Supabase Edge Functions – Write functions (in TypeScript) to validate allocation requests, spending, and reallocation. These functions should:

Recompute allocation amounts based on stored plan rules to prevent manipulated clients from crediting arbitrary amounts.

Reject any attempt to spend from the savings pocket or exceed pocket balances.

Enforce friction rules for reallocation (e.g. a minimum delay between reallocations or a server‑side confirmation token).

Duplicate SMS handling – Introduce an incoming_payments or sms_events table with a unique constraint on the transaction reference. The SMS listener should check this table before triggering allocation to prevent double crediting.

Transaction idempotency – Ensure that reallocation and spending functions can be retried safely (e.g. by using idempotency keys on client requests).

5. Behavioural analytics and scoring

Define a discipline score – Derive a score based on behavioural events (e.g. ratio of successful spends to overspend attempts, frequency of reallocation). Display the score in the insights screen with clear explanations.

Extended behavioural events – Add event types for plan modifications, savings percentage changes and manual reallocation cancellations. Use these to refine scoring.

Dashboards and charts – Visualise spending and savings trends over time. Use bar charts or line graphs to show monthly spending, savings growth and reallocation amounts.

6. Notifications and user engagement

Push notifications – Integrate Firebase Cloud Messaging or Supabase’s push service to send notifications when:

A new income allocation occurs (with breakdown summary).

An overspend attempt is blocked.

It’s time to update the money plan or reallocate funds.
Ensure notifications respect user settings and avoid spamming.

Local notifications – Use Flutter’s flutter_local_notifications package for reminders when the app is not connected to the internet.

7. Premium UI upgrade

Design system upgrade – Implement a refined theme with larger corner radii, soft shadows and optional gradients. Define tokens for primary, secondary and accent colours, success and warning states, and apply them consistently across the app.

Component refactoring – Create reusable premium components:

AppCard with elevation and hover effects

Buttons with gradient backgrounds and tactile feedback

Floating bottom navigation bar

Skeleton loaders with shimmer animations

Improved numeric keypad with large keys and haptic feedback

Micro‑interactions – Animate pocket cards when balances change, show progress arcs during friction timers, and use hero animations when transitioning between screens (e.g. from pockets to allocation breakdown).

Responsiveness – Ensure layouts work on various Android screen sizes and densities. Use media queries or responsive widgets where necessary.

8. M‑Pesa and bank API integration (future)

While this is beyond the MVP, preparing for production means:

Incoming payments table – Add an incoming_payments table that stores parsed SMS data and webhook payloads. Map each transaction to an incoming payment and enforce uniqueness via constraints.

Webhook handling – Implement Supabase Edge Functions or a server component to ingest M‑Pesa API callbacks, perform validations and trigger allocation.

Bank APIs – Research open banking APIs in Kenya to allow direct bank transfers into pockets. Implement OAuth flows, account linking and periodic balance checks.

9. Security and privacy

Enforce HTTPS everywhere – Ensure that all network calls to Supabase and any external services use TLS.

JWT verification in Edge Functions – Validate Supabase JWTs within server functions to prevent forged requests.

Sensitive data encryption – Consider encrypting phone numbers and references at rest. Use the Supabase key management features or an external KMS.

Configurable SMS sender allowlist – Maintain a list of allowed sender IDs in a remote configuration so that the parser can adapt if Safaricom changes the sender format. Provide an admin UI or environment variable to update this list.

10. Documentation and developer experience

Update documentation – Keep README.md and HOW_IT_WORKS.md in sync with new features. Document how to run tests and how to set up Supabase and local environment.

API versioning – If Edge Functions are introduced, version their endpoints to minimise breaking changes.

Coding guidelines – Document architecture guidelines for new contributors (e.g. folder structure, naming conventions, testing practices).

Summary

The Financial Hub prototype lays a strong foundation. Completing the MVP requires finishing phone OTP authentication, building a dedicated UI for real SMS allocations, adding end‑to‑end tests and performance optimisations, and migrating financial validations to the backend. Enhancing behavioural analytics, notifications and the UI will provide a premium user experience. Finally, planning for production involves adding API integrations, strengthening security and documenting clear guidelines for future development.