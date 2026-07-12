-- ETA Report schema (lives in the afs-container-tracker Supabase project)
-- Run manually in the Supabase SQL editor. No CLI/migrations tooling, matching
-- the afs-stocking-positions convention.

create table if not exists public.report_batches (
  id bigint generated always as identity primary key,
  uploaded_at timestamptz not null default now(),
  source_filename text,
  row_count integer not null default 0
);

alter table public.report_batches enable row level security;
create policy "anon read" on public.report_batches for select using (true);
create policy "anon insert" on public.report_batches for insert with check (true);

create table if not exists public.po_lines (
  po_number text primary key,
  store integer,
  supplier text,
  product_code text,
  style_name text,
  color_desc text,
  sidemark text,
  amount_ordered numeric,
  units text,
  promise_date date,
  order_date date,
  status text,
  ordered_by text,
  taken_by text,
  style_number text,
  manufacturer text,
  gross_cost numeric,
  total_cost numeric,
  reference_number text,
  first_seen_batch_id bigint references public.report_batches(id),
  first_seen_at timestamptz not null default now(),
  last_seen_batch_id bigint references public.report_batches(id),
  last_seen_at timestamptz not null default now(),
  is_active boolean not null default true,
  pending_promise_date date -- proposed date entered in-app but not yet confirmed in RFMS
);

create index if not exists po_lines_ordered_by_idx on public.po_lines (ordered_by);
create index if not exists po_lines_store_idx on public.po_lines (store);
create index if not exists po_lines_is_active_idx on public.po_lines (is_active);
create index if not exists po_lines_promise_date_idx on public.po_lines (promise_date);

alter table public.po_lines enable row level security;
create policy "anon read" on public.po_lines for select using (true);
create policy "anon insert" on public.po_lines for insert with check (true);
create policy "anon update" on public.po_lines for update using (true) with check (true);

create table if not exists public.po_line_history (
  id bigint generated always as identity primary key,
  po_number text not null references public.po_lines(po_number) on delete cascade,
  batch_id bigint references public.report_batches(id),
  event_type text not null check (event_type in ('created','updated','closed','reappeared','manual_update','unverified_update')),
  changes jsonb,
  detected_at timestamptz not null default now()
);

create index if not exists po_line_history_po_number_idx on public.po_line_history (po_number, detected_at);

alter table public.po_line_history enable row level security;
create policy "anon read" on public.po_line_history for select using (true);
create policy "anon insert" on public.po_line_history for insert with check (true);
