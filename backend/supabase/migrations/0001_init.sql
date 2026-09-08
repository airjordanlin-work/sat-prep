-- M2. Server-authoritative state. Clients read, never write.

create type question_tier as enum ('gate', 'session');
create type attempt_kind as enum ('pass', 'extended');

create table questions (
  id            uuid primary key default gen_random_uuid(),
  section       text not null,
  skill         text not null,
  difficulty    int  not null check (difficulty between 1 and 5),
  tier          question_tier not null,
  stem          text not null,
  choices       jsonb not null,
  correct_index int not null,
  explanation   text not null,
  reviewed      bool not null default false,
  created_at    timestamptz not null default now()
);

-- Nothing circulates until a human approves it.
create index on questions (tier, reviewed) where reviewed;

create table attempts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users on delete cascade,
  kind         attempt_kind not null,
  question_ids uuid[] not null,
  started_at   timestamptz not null default now(),
  submitted_at timestamptz,
  score        int,
  passed       bool
);

create table pass_state (
  user_id              uuid primary key references auth.users on delete cascade,
  pass_expires_at      timestamptz,
  entries_this_hour    int not null default 0,
  hour_window_started  timestamptz,
  consecutive_failures int not null default 0,
  extended_used_on     date
);

-- Spaced repetition. This is what makes the gate fast: served items
-- have been seen before, so answering is retrieval, not learning.
create table review_items (
  user_id          uuid not null references auth.users on delete cascade,
  question_id      uuid not null references questions on delete cascade,
  due_at           timestamptz not null default now(),
  interval_minutes int not null default 10,
  streak           int not null default 0,
  primary key (user_id, question_id)
);

create index on review_items (user_id, due_at);

-- Cohort matters: volunteers and skeptics must be reported separately
-- or the pilot flatters itself.
create table profiles (
  user_id      uuid primary key references auth.users on delete cascade,
  cohort       text not null default 'volunteer',
  installed_at timestamptz not null default now(),
  last_active_at timestamptz
);

alter table attempts      enable row level security;
alter table pass_state    enable row level security;
alter table review_items  enable row level security;
alter table profiles      enable row level security;
alter table questions     enable row level security;

create policy own_attempts on attempts
  for select using (auth.uid() = user_id);

-- Deliberately select-only. Only the grading function writes these.
create policy own_pass_state on pass_state
  for select using (auth.uid() = user_id);

create policy own_review_items on review_items
  for select using (auth.uid() = user_id);

create policy own_profile on profiles
  for all using (auth.uid() = user_id);

create policy reviewed_questions_readable on questions
  for select using (reviewed = true);
