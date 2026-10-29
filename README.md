# Delta Pay — Full Platform Starter

Recommended stack: **Supabase + Vercel**.

- **Vercel**: host the frontend.
- **Supabase Auth**: user registration and login.
- **Supabase Postgres**: profiles, wallet records, deposits, withdrawals, and transaction history.
- **Supabase Edge Functions**: trusted server-side operations and payment-provider webhooks.

## Important status
This package is a starter, not a live-money-ready financial service. The included `index.html` is the current visual demo and still contains simulated UI interactions. The SQL establishes a safer database foundation, but the real authentication flows, API/Edge Functions, admin interface, provider onboarding, webhooks, reconciliation, monitoring, and testing still need to be implemented before it can be called a complete working platform.

Real deposits/payouts are intentionally not enabled. Before offering a wallet or automatic payouts in India, confirm the legal/business model and required authorizations with qualified counsel and the payment provider. Do not promise investment returns or collect customer funds until the model has been reviewed and approved.

## Setup outline
1. Create a Supabase project at https://supabase.com/.
2. In Supabase SQL Editor, run `supabase/migrations/001_initial_schema.sql`.
3. Enable email authentication and configure allowed redirect URLs.
4. Create a Vercel project and deploy `index.html` as the frontend.
5. Build Supabase Edge Functions for all privileged wallet and payment actions using the plan in `api/README.txt`.
6. Store secrets only in Supabase/Vercel server-side environment variables. Never put a Supabase service-role key or payment secret in `index.html`.
7. Test with fake/sandbox transactions and verify idempotency, authorization, race conditions, and provider webhook signatures before any live rollout.

## Security notes
- Monetary values are stored as integer paise.
- Client-side code must never set wallet balances or mark transactions paid.
- A provider webhook must be signature-verified and safely deduplicated.
- Withdrawal requests must reserve funds atomically to prevent double spending.
- Keep audit logs for admin and financial actions.
