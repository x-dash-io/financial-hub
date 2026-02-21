-- Trigger: create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
declare
  new_plan_id uuid;
  savings_id uuid;
  p1_id uuid;
  p2_id uuid;
begin
  insert into public.profiles (user_id, phone)
  values (new.id, new.phone);

  insert into public.money_plans (profile_id, name, is_active)
  values (
    (select id from public.profiles where user_id = new.id),
    'Default Plan',
    true
  )
  returning id into new_plan_id;

  update public.profiles set default_plan_id = new_plan_id
  where user_id = new.id;

  -- default pockets: Savings (locked), Transport, Food, Other
  insert into public.pockets (profile_id, plan_id, name, balance, is_savings)
  values (
    (select id from public.profiles where user_id = new.id),
    new_plan_id,
    'Savings',
    0,
    true
  ) returning id into savings_id;

  insert into public.pockets (profile_id, plan_id, name, balance, is_savings)
  values (
    (select id from public.profiles where user_id = new.id),
    new_plan_id,
    'Transport',
    0,
    false
  ) returning id into p1_id;

  insert into public.pockets (profile_id, plan_id, name, balance, is_savings)
  values (
    (select id from public.profiles where user_id = new.id),
    new_plan_id,
    'Food',
    0,
    false
  ) returning id into p2_id;

  insert into public.pockets (profile_id, plan_id, name, balance, is_savings)
  values (
    (select id from public.profiles where user_id = new.id),
    new_plan_id,
    'Other',
    0,
    false
  );

  -- allocations: 50% savings, 20% transport, 20% food, 10% other
  insert into public.money_plan_allocations (plan_id, pocket_id, percentage)
  values
    (new_plan_id, savings_id, 50),
    (new_plan_id, p1_id, 20),
    (new_plan_id, p2_id, 20),
    (new_plan_id, (select id from public.pockets where plan_id = new_plan_id and name = 'Other' limit 1), 10);

  return new;
end;
$$ language plpgsql security definer;

-- Auth trigger: run in Supabase SQL Editor (requires service role) after enabling auth:
-- create trigger on_auth_user_created
--   after insert on auth.users
--   for each row execute function public.handle_new_user();
