-- Add source (sender) to transactions for MPESA income tracking.
-- Persisted with amount, reference, created_at (timestamp).
alter table public.transactions add column if not exists source text;
