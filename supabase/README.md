# Supabase Setup

Project repository: https://github.com/x-dash-io/Financial-Hub.git

1. Create a project at https://supabase.com
2. Auth provider setup (current app behavior):
   - Enable **Anonymous Sign-Ins** in Authentication > Providers
   - Phone Auth/OTP is optional for now (planned for later rollout)
3. Run migrations in order:
   - `supabase db push` or paste each migration in SQL Editor
4. Create the auth trigger (SQL Editor, service role):
```sql
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```
5. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to `.env`

## Migration Notes

Recent additions include:
- Default savings seed update to 10% baseline
- Dynamic pocket icon support:
  - `pockets.icon_key`
  - `pockets.icon_custom`
  - trigger/function to auto-match icon by pocket name when not custom
