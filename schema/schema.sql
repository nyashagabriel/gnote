-- ─────────────────────────────────────────────────────────────
-- GNOTE — SUPABASE SCHEMA
--
-- Run this in Supabase SQL editor.
-- Tables mirror models exactly — same field names.
-- RLS enabled on all tables — users only see their own data.
-- ─────────────────────────────────────────────────────────────

-- ── Profiles ──────────────────────────────────────────────────
create table public.profiles (
  id            uuid primary key references auth.users on delete cascade,
  email         text not null,
  display_name  text not null,
  timezone      text default 'Africa/Harare',
  created_at    timestamptz default now(),
  last_seen     timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users manage own profile"
  on public.profiles
  for all
  using (auth.uid() = id);

-- ── Anchors ───────────────────────────────────────────────────
create table public.anchors (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.profiles on delete cascade,
  content     text not null,
  date        date not null default current_date,
  created_at  timestamptz default now(),
  unique(user_id, date)   -- one anchor per day per user
);

alter table public.anchors enable row level security;

create policy "Users manage own anchors"
  on public.anchors
  for all
  using (auth.uid() = user_id);

-- ── Tasks (Daily 3 + Capture) ─────────────────────────────────
create table public.tasks (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references public.profiles on delete cascade,
  what          text not null,
  done_when     text not null default '',
  by            timestamptz not null,
  category      text not null default 'other',
  is_done       boolean default false,
  is_capture    boolean default false,
  created_at    timestamptz default now(),
  completed_at  timestamptz
);

alter table public.tasks enable row level security;

create policy "Users manage own tasks"
  on public.tasks
  for all
  using (auth.uid() = user_id);

-- ── Habits ────────────────────────────────────────────────────
create table public.habits (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references public.profiles on delete cascade,
  name          text not null,
  streak        int default 0,
  last_checked  timestamptz,
  is_active     boolean default false,
  created_at    timestamptz default now()
);

alter table public.habits enable row level security;

create policy "Users manage own habits"
  on public.habits
  for all
  using (auth.uid() = user_id);

-- ── People (Responsibility) ───────────────────────────────────
create table public.people (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid references public.profiles on delete cascade,
  name              text not null,
  whatsapp_number   text not null,
  role              text not null check (role in ('Motivator', 'Meditator')),
  message_template  text not null,
  last_selected_at  timestamptz,
  times_selected    int default 0,
  created_at        timestamptz default now()
);

alter table public.people enable row level security;

create policy "Users manage own people"
  on public.people
  for all
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
-- AUTO-CREATE PROFILE ON SIGNUP
-- Trigger fires when user signs up via Supabase Auth
-- ─────────────────────────────────────────────────────────────

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', 'User')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();