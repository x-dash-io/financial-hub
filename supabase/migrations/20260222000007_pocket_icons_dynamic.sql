-- Dynamic pocket icons:
-- 1) Persist icon key + custom/auto flag in DB
-- 2) Auto-match icon by pocket name when icon_custom = false
-- 3) Keep savings icon locked to "savings"

alter table public.pockets
  add column if not exists icon_key text,
  add column if not exists icon_custom boolean default false;

create or replace function public.pocket_icon_key_from_name(
  p_name text,
  p_is_savings boolean default false
)
returns text
language plpgsql
immutable
as $$
declare
  normalized text := lower(coalesce(p_name, ''));
begin
  if p_is_savings then
    return 'savings';
  end if;

  if normalized ~ '(food|meal|restaurant|grocery|grocer|lunch|dinner|breakfast|snack)' then
    return 'food';
  elsif normalized ~ '(transport|travel|bus|matatu|fare|fuel|uber|taxi|ride|car)' then
    return 'transport';
  elsif normalized ~ '(home|house|rent|mortgage|housing)' then
    return 'housing';
  elsif normalized ~ '(utility|utilities|internet|wifi|water|power|electricity|airtime|data|bill)' then
    return 'utilities';
  elsif normalized ~ '(shopping|shop|market|clothes|fashion|mall)' then
    return 'shopping';
  elsif normalized ~ '(health|medical|clinic|hospital|medicine|pharmacy|doctor|dental|insurance)' then
    return 'health';
  elsif normalized ~ '(school|education|tuition|books|learning|class|course)' then
    return 'education';
  elsif normalized ~ '(entertainment|fun|games|movie|leisure|netflix|show|music|stream)' then
    return 'entertainment';
  elsif normalized ~ '(family|kids|children|parent|baby|dependant|dependents)' then
    return 'family';
  elsif normalized ~ '(business|work|office|project|client|startup)' then
    return 'business';
  elsif normalized ~ '(debt|loan|credit|repay|repayment)' then
    return 'debt';
  elsif normalized ~ '(invest|investment|stocks|crypto|mmf|bond|fund)' then
    return 'investment';
  elsif normalized ~ '(gift|present|birthday|wedding|donation)' then
    return 'gift';
  elsif normalized ~ '(emergency|urgent|buffer|rainy|unexpected)' then
    return 'emergency';
  elsif normalized ~ '(cash|allowance|daily|wallet|spending)' then
    return 'cash';
  end if;

  return 'other';
end;
$$;

create or replace function public.pockets_apply_icon_fields()
returns trigger
language plpgsql
as $$
begin
  if new.is_savings then
    new.icon_key := 'savings';
    new.icon_custom := false;
    return new;
  end if;

  new.icon_custom := coalesce(new.icon_custom, false);

  if new.icon_custom then
    if new.icon_key is null or btrim(new.icon_key) = '' then
      new.icon_custom := false;
      new.icon_key := public.pocket_icon_key_from_name(new.name, new.is_savings);
    else
      new.icon_key := lower(btrim(new.icon_key));
    end if;
  else
    new.icon_key := public.pocket_icon_key_from_name(new.name, new.is_savings);
  end if;

  if new.icon_key not in (
    'savings',
    'food',
    'transport',
    'housing',
    'utilities',
    'shopping',
    'health',
    'education',
    'entertainment',
    'family',
    'business',
    'debt',
    'investment',
    'gift',
    'emergency',
    'cash',
    'other'
  ) then
    new.icon_key := 'other';
  end if;

  return new;
end;
$$;

update public.pockets
set icon_custom = false
where icon_custom is null;

update public.pockets
set icon_key = case
  when is_savings then 'savings'
  when icon_custom = false then public.pocket_icon_key_from_name(name, is_savings)
  else lower(btrim(coalesce(icon_key, '')))
end;

update public.pockets
set icon_key = 'other'
where (icon_key is null or icon_key = '')
  and is_savings = false;

update public.pockets
set icon_key = 'savings',
    icon_custom = false
where is_savings = true;

update public.pockets
set icon_key = 'other'
where icon_key not in (
  'savings',
  'food',
  'transport',
  'housing',
  'utilities',
  'shopping',
  'health',
  'education',
  'entertainment',
  'family',
  'business',
  'debt',
  'investment',
  'gift',
  'emergency',
  'cash',
  'other'
);

alter table public.pockets
  alter column icon_custom set default false,
  alter column icon_custom set not null,
  alter column icon_key set default 'other',
  alter column icon_key set not null;

alter table public.pockets
  drop constraint if exists pockets_icon_key_valid;

alter table public.pockets
  add constraint pockets_icon_key_valid
  check (
    icon_key in (
      'savings',
      'food',
      'transport',
      'housing',
      'utilities',
      'shopping',
      'health',
      'education',
      'entertainment',
      'family',
      'business',
      'debt',
      'investment',
      'gift',
      'emergency',
      'cash',
      'other'
    )
  );

drop trigger if exists trg_pockets_apply_icon_fields on public.pockets;

create trigger trg_pockets_apply_icon_fields
before insert or update of name, is_savings, icon_key, icon_custom
on public.pockets
for each row
execute function public.pockets_apply_icon_fields();

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

  update public.profiles
  set default_plan_id = new_plan_id
  where user_id = new.id;

  insert into public.pockets (
    profile_id, plan_id, name, balance, is_savings, icon_key, icon_custom
  )
  values (
    (select id from public.profiles where user_id = new.id),
    new_plan_id,
    'Savings',
    0,
    true,
    'savings',
    false
  )
  returning id into savings_id;

  insert into public.pockets (
    profile_id, plan_id, name, balance, is_savings, icon_key, icon_custom
  )
  values (
    (select id from public.profiles where user_id = new.id),
    new_plan_id,
    'Transport',
    0,
    false,
    'transport',
    false
  )
  returning id into p1_id;

  insert into public.pockets (
    profile_id, plan_id, name, balance, is_savings, icon_key, icon_custom
  )
  values (
    (select id from public.profiles where user_id = new.id),
    new_plan_id,
    'Food',
    0,
    false,
    'food',
    false
  )
  returning id into p2_id;

  insert into public.pockets (
    profile_id, plan_id, name, balance, is_savings, icon_key, icon_custom
  )
  values (
    (select id from public.profiles where user_id = new.id),
    new_plan_id,
    'Other',
    0,
    false,
    'other',
    false
  );

  insert into public.money_plan_allocations (plan_id, pocket_id, percentage)
  values
    (new_plan_id, savings_id, 10),
    (new_plan_id, p1_id, 30),
    (new_plan_id, p2_id, 30),
    (
      new_plan_id,
      (select id from public.pockets where plan_id = new_plan_id and name = 'Other' limit 1),
      30
    );

  return new;
end;
$$ language plpgsql security definer;
