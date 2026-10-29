-- Delta Pay starter schema for Supabase/Postgres.
-- This schema does NOT enable real deposits or payouts. Provider integration and compliance review are required first.
create extension if not exists pgcrypto;

create type public.transaction_kind as enum ('deposit','withdrawal','adjustment','referral_reward');
create type public.transaction_status as enum ('pending','processing','completed','failed','cancelled');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  referral_code text unique not null default upper(substr(encode(gen_random_bytes(8),'hex'),1,10)),
  referred_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

-- Amounts are stored in paise as integer minor units. Never accept a balance from the browser.
create table public.wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  currency char(3) not null default 'INR' check (currency = 'INR'),
  available_paise bigint not null default 0 check (available_paise >= 0),
  reserved_paise bigint not null default 0 check (reserved_paise >= 0),
  updated_at timestamptz not null default now()
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  kind public.transaction_kind not null,
  status public.transaction_status not null default 'pending',
  amount_paise bigint not null check (amount_paise > 0),
  currency char(3) not null default 'INR' check (currency = 'INR'),
  provider text,
  provider_reference text,
  idempotency_key text unique,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index transactions_user_created_idx on public.transactions(user_id, created_at desc);

create table public.withdrawal_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  transaction_id uuid not null unique references public.transactions(id),
  amount_paise bigint not null check (amount_paise > 0),
  -- Store only provider token/reference here, not raw bank credentials or UPI PINs.
  payout_method text not null check (payout_method in ('upi','bank_transfer')),
  payout_destination_token text,
  status public.transaction_status not null default 'pending',
  provider_reference text,
  failure_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.deposit_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  transaction_id uuid not null unique references public.transactions(id),
  amount_paise bigint not null check (amount_paise > 0),
  provider text,
  provider_order_id text,
  provider_payment_id text,
  status public.transaction_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Profile/wallet creation on signup. No client-side balance changes are permitted.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, display_name) values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name',''));
  insert into public.wallets(user_id) values (new.id);
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.transactions enable row level security;
alter table public.withdrawal_requests enable row level security;
alter table public.deposit_requests enable row level security;
alter table public.admin_users enable row level security;

create policy "users read own profile" on public.profiles for select to authenticated using (auth.uid() = id);
create policy "users update own profile basics" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
create policy "users read own wallet" on public.wallets for select to authenticated using (auth.uid() = user_id);
create policy "users read own transactions" on public.transactions for select to authenticated using (auth.uid() = user_id);
create policy "users read own withdrawals" on public.withdrawal_requests for select to authenticated using (auth.uid() = user_id);
create policy "users read own deposits" on public.deposit_requests for select to authenticated using (auth.uid() = user_id);
-- Intentionally no user INSERT/UPDATE policies for wallet balances, transaction status, or payment records.
-- Server-side Edge Functions using the service role must validate every operation and never expose that key.
