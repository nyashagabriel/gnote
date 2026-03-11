-- ============================================================
-- GNOTE — SUPABASE SCHEMA
-- Run this in the Supabase SQL editor (once, on a fresh project).
-- RLS is enabled on all tables. Users only see their own rows.
-- ============================================================

-- ── Enable UUID extension ─────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ──────────────────────────────────────────────────────────────
-- PROFILES
-- Created on signup. Ties Supabase auth.users to app data.
-- ──────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id            uuid        primary key references auth.users(id) on delete cascade,
  email         text        not null,
  display_name  text        not null default '',
  timezone      text        not null default 'Africa/Harare',
  created_at    timestamptz not null default now(),
  last_seen     timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- ──────────────────────────────────────────────────────────────
-- ANCHORS
-- One per day per user. Locked — never updated after insert.
-- ──────────────────────────────────────────────────────────────
create table if not exists public.anchors (
  id          uuid        primary key default uuid_generate_v4(),
  user_id     uuid        not null references auth.users(id) on delete cascade,
  content     text        not null check (char_length(content) <= 160),
  date        date        not null,
  created_at  timestamptz not null default now(),

  unique (user_id, date)  -- one anchor per day
);

alter table public.anchors enable row level security;

create policy "Users manage own anchors"
  on public.anchors for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index anchors_user_date on public.anchors (user_id, date desc);

-- ──────────────────────────────────────────────────────────────
-- TASKS
-- Handles both Daily 3 (is_capture = false) and Capture (is_capture = true).
-- ──────────────────────────────────────────────────────────────
create table if not exists public.tasks (
  id            uuid        primary key default uuid_generate_v4(),
  user_id       uuid        not null references auth.users(id) on delete cascade,
  what          text        not null check (char_length(what) <= 80),
  done_when     text        not null default '',
  by            timestamptz not null,
  category      text        not null default 'other',
  is_done       boolean     not null default false,
  is_capture    boolean     not null default false,
  completed_at  timestamptz,
  created_at    timestamptz not null default now()
);

alter table public.tasks enable row level security;

create policy "Users manage own tasks"
  on public.tasks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index tasks_user_created   on public.tasks (user_id, created_at desc);
create index tasks_user_capture   on public.tasks (user_id, is_capture);

-- ──────────────────────────────────────────────────────────────
-- HABITS
-- One active habit per user. isActive enforced in app logic.
-- ──────────────────────────────────────────────────────────────
create table if not exists public.habits (
  id            uuid        primary key default uuid_generate_v4(),
  user_id       uuid        not null references auth.users(id) on delete cascade,
  name          text        not null check (char_length(name) <= 80),
  streak        integer     not null default 0,
  last_checked  timestamptz,
  is_active     boolean     not null default false,
  created_at    timestamptz not null default now()
);

alter table public.habits enable row level security;

create policy "Users manage own habits"
  on public.habits for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index habits_user_active on public.habits (user_id, is_active);

-- ──────────────────────────────────────────────────────────────
-- PEOPLE
-- Motivators and Meditators. Picked randomly each day.
-- ──────────────────────────────────────────────────────────────
create table if not exists public.people (
  id                uuid        primary key default uuid_generate_v4(),
  user_id           uuid        not null references auth.users(id) on delete cascade,
  name              text        not null check (char_length(name) <= 80),
  whatsapp_number   text        not null,
  role              text        not null check (role in ('Motivator', 'Meditator')),
  message_template  text        not null default '' check (char_length(message_template) <= 300),
  last_selected_at  timestamptz,
  times_selected    integer     not null default 0,
  created_at        timestamptz not null default now()
);

alter table public.people enable row level security;

create policy "Users manage own people"
  on public.people for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index people_user_role on public.people (user_id, role);

-- ──────────────────────────────────────────────────────────────
-- SELECTIONS
-- Optional: tracks daily picks for analytics. Not used by app yet.
-- ──────────────────────────────────────────────────────────────
create table if not exists public.selections (
  id          uuid        primary key default uuid_generate_v4(),
  user_id     uuid        not null references auth.users(id) on delete cascade,
  person_id   uuid        not null references public.people(id) on delete cascade,
  selected_at date        not null default current_date
);

alter table public.selections enable row level security;

create policy "Users manage own selections"
  on public.selections for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ──────────────────────────────────────────────────────────────
-- TRIGGER: auto-create profile row on signup
-- Fires when a new row is inserted into auth.users.
-- Saves one round-trip — profile exists before app first loads.
-- ──────────────────────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
