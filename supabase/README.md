# Supabase Setup

1. Create a project at https://supabase.com
2. Enable Phone Auth in Authentication > Providers
3. Run migrations in order:
   - `supabase db push` or paste each migration in SQL Editor
4. Create the auth trigger (SQL Editor, service role):
```sql
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```
5. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to `.env`
