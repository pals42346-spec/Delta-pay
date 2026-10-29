Backend API implementation plan

Use Supabase Edge Functions for privileged operations:
- create-deposit: create a pending deposit and provider order; never credit a wallet based on browser input.
- verify-deposit: verify provider webhook signature and payment status, then credit the wallet exactly once in a database transaction.
- request-withdrawal: validate auth, amount, limits, idempotency key, and available balance; reserve funds atomically.
- process-payout: call an approved payout provider only after merchant onboarding and compliance approval; reconcile provider callbacks before marking completed.
- admin-review: enforce admin_users membership server-side; log every administrative action.

The SQL schema intentionally does not include a live payout integration. Do not add a service-role key to frontend code. Do not store UPI PINs, OTPs, raw card details, or raw bank credentials. Use the payment provider's tokenized destination/beneficiary references.
