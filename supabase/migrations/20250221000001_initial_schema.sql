-- Financial Hub – Prototype schema
-- profiles, pockets, money_plans, money_plan_allocations, transactions, behavioral_events

-- profiles (1:1 with auth.users)
create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade unique,
  phone text,
  default_plan_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- money_plans (one active per profile)
create table public.money_plans (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  name text not null default 'Default Plan',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add constraint fk_profiles_default_plan
  foreign key (default_plan_id) references public.money_plans(id) on delete set null;

-- pockets (per plan)
create table public.pockets (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  plan_id uuid not null references public.money_plans(id) on delete cascade,
  name text not null,
  balance bigint not null default 0,
  is_savings boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- money_plan_allocations (percentage per pocket)
create table public.money_plan_allocations (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.money_plans(id) on delete cascade,
  pocket_id uuid not null references public.pockets(id) on delete cascade,
  percentage int not null check (percentage >= 0 and percentage <= 100),
  unique(plan_id, pocket_id)
);

-- transactions (ledger-lite, append-only)
create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  pocket_id uuid not null references public.pockets(id) on delete restrict,
  amount bigint not null,
  type text not null check (type in ('credit', 'debit', 'reallocation_in', 'reallocation_out')),
  reference text,
  created_at timestamptz not null default now()
);

-- behavioral_events
create table public.behavioral_events (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  event_type text not null,
  pocket_id uuid references public.pockets(id) on delete set null,
  amount bigint,
  payload jsonb default '{}',
  created_at timestamptz not null default now()
);

-- indexes
create index idx_profiles_user_id on public.profiles(user_id);
create index idx_money_plans_profile_id on public.money_plans(profile_id);
create index idx_pockets_profile_id on public.pockets(profile_id);
create index idx_pockets_plan_id on public.pockets(plan_id);
create index idx_transactions_pocket_id on public.transactions(pocket_id);
create index idx_behavioral_events_profile_id on public.behavioral_events(profile_id);
