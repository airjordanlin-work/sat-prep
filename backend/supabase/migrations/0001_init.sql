-- M2: server-authoritative pass state, spaced-repetition review items,
-- and the attempt log grading reads/writes. Clients read; only the
-- grading Edge Function (service role, bypasses RLS) writes.
--
-- review_items ports ReviewItem (app/lib/data/review_queue.dart) field
-- for field. pass_state persists exactly what PassService
-- (app/lib/services/pass_service.dart) needs server-side: the current
-- pass expiry, the rolling free-entry window, and the escalation count
-- that window feeds into. Interval math and cost curve stay in the
-- grading function, not the schema.

create type answer_result as enum ('correct', 'incorrect', 'too_fast');
create type device_platform as enum ('ios', 'android');

-- Spaced repetition. Mirrors ReviewItem exactly: questionId, dueAt,
-- intervalMinutes (default 10), consecutiveCorrect (default 0).
create table review_items (
  user_id             uuid not null references auth.users on delete cascade,
  question_id         text not null,
  due_at              timestamptz not null,
  interval_minutes    int not null default 10,
  consecutive_correct int not null default 0,
  primary key (user_id, question_id)
);

create index on review_items (user_id, due_at);

-- Server-authoritative pass state. platform drives the pass-length
-- floor (iOS: 5 min minimum; Android can go as low as the 90s
-- wrong-answer pass) in the grading function; window_started_at and
-- entries_this_window are the rolling-hour state that costForEntry()
-- escalates against.
create table pass_state (
  user_id             uuid primary key references auth.users on delete cascade,
  platform            device_platform not null,
  pass_expires_at     timestamptz,
  window_started_at   timestamptz not null default now(),
  entries_this_window int not null default 0,
  updated_at          timestamptz not null default now()
);

-- One row per gate attempt. started_at is set by /start-attempt;
-- result/answered_at are filled in by /grade-attempt. Doubles as the
-- retention/cohort instrumentation source.
create table attempts (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users on delete cascade,
  question_id    text not null,
  started_at     timestamptz not null default now(),
  answered_at    timestamptz,
  result         answer_result,
  response_time_ms int
);

create index on attempts (user_id, started_at);

alter table review_items enable row level security;
alter table pass_state   enable row level security;
alter table attempts     enable row level security;

-- Select-only: only the grading Edge Function (service role) writes
-- any of these three tables. No insert/update/delete policy for the
-- client role is intentional, not an oversight.
create policy own_review_items on review_items
  for select using (auth.uid() = user_id);

create policy own_pass_state on pass_state
  for select using (auth.uid() = user_id);

create policy own_attempts on attempts
  for select using (auth.uid() = user_id);
