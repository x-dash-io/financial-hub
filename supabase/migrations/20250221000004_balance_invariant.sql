-- Balance model: transactions are source of truth, pockets.cached_balance is derived.
-- Never mutate cached_balance without inserting a transaction.
-- This trigger keeps cached_balance in sync on every transaction insert.

alter table public.pockets rename column balance to cached_balance;

create or replace function public.on_transaction_insert()
returns trigger as $$
begin
  update public.pockets
  set cached_balance = cached_balance + new.amount
  where id = new.pocket_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger tr_transaction_insert
  after insert on public.transactions
  for each row execute function public.on_transaction_insert();
