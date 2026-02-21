-- RLS: all tables scoped by auth.uid() via profiles
alter table public.profiles enable row level security;
alter table public.money_plans enable row level security;
alter table public.pockets enable row level security;
alter table public.money_plan_allocations enable row level security;
alter table public.transactions enable row level security;
alter table public.behavioral_events enable row level security;

-- profiles: user can CRUD own
create policy profiles_select on public.profiles
  for select using (auth.uid() = user_id);
create policy profiles_insert on public.profiles
  for insert with check (auth.uid() = user_id);
create policy profiles_update on public.profiles
  for update using (auth.uid() = user_id);

-- money_plans: via profile ownership
create policy money_plans_select on public.money_plans
  for select using (
    profile_id in (select id from public.profiles where user_id = auth.uid())
  );
create policy money_plans_insert on public.money_plans
  for insert with check (
    profile_id in (select id from public.profiles where user_id = auth.uid())
  );
create policy money_plans_update on public.money_plans
  for update using (
    profile_id in (select id from public.profiles where user_id = auth.uid())
  );
create policy money_plans_delete on public.money_plans
  for delete using (
    profile_id in (select id from public.profiles where user_id = auth.uid())
  );

-- pockets: via profile ownership
create policy pockets_select on public.pockets
  for select using (
    profile_id in (select id from public.profiles where user_id = auth.uid())
  );
create policy pockets_insert on public.pockets
  for insert with check (
    profile_id in (select id from public.profiles where user_id = auth.uid())
  );
create policy pockets_update on public.pockets
  for update using (
    profile_id in (select id from public.profiles where user_id = auth.uid())
  );
create policy pockets_delete on public.pockets
  for delete using (
    profile_id in (select id from public.profiles where user_id = auth.uid())
  );

-- money_plan_allocations: via plan -> profile
create policy mpa_select on public.money_plan_allocations
  for select using (
    plan_id in (
      select mp.id from public.money_plans mp
      join public.profiles p on p.id = mp.profile_id
      where p.user_id = auth.uid()
    )
  );
create policy mpa_insert on public.money_plan_allocations
  for insert with check (
    plan_id in (
      select mp.id from public.money_plans mp
      join public.profiles p on p.id = mp.profile_id
      where p.user_id = auth.uid()
    )
  );
create policy mpa_update on public.money_plan_allocations
  for update using (
    plan_id in (
      select mp.id from public.money_plans mp
      join public.profiles p on p.id = mp.profile_id
      where p.user_id = auth.uid()
    )
  );
create policy mpa_delete on public.money_plan_allocations
  for delete using (
    plan_id in (
      select mp.id from public.money_plans mp
      join public.profiles p on p.id = mp.profile_id
      where p.user_id = auth.uid()
    )
  );

-- transactions: via pocket -> profile
create policy transactions_select on public.transactions
  for select using (
    pocket_id in (
      select pk.id from public.pockets pk
      join public.profiles p on p.id = pk.profile_id
      where p.user_id = auth.uid()
    )
  );
create policy transactions_insert on public.transactions
  for insert with check (
    pocket_id in (
      select pk.id from public.pockets pk
      join public.profiles p on p.id = pk.profile_id
      where p.user_id = auth.uid()
    )
  );

-- behavioral_events: own profile
create policy behavioral_events_select on public.behavioral_events
  for select using (
    profile_id in (select id from public.profiles where user_id = auth.uid())
  );
create policy behavioral_events_insert on public.behavioral_events
  for insert with check (
    profile_id in (select id from public.profiles where user_id = auth.uid())
  );
