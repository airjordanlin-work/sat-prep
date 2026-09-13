begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(31);

-- Enum values are API contracts shared with the Flutter client.
select extensions.results_eq(
  $$
    select e.enumlabel::text
    from pg_catalog.pg_type t
    join pg_catalog.pg_namespace n on n.oid = t.typnamespace
    join pg_catalog.pg_enum e on e.enumtypid = t.oid
    where n.nspname = 'public' and t.typname = 'answer_result'
    order by e.enumsortorder
  $$,
  $$values ('correct'::text), ('incorrect'::text), ('too_fast'::text)$$,
  'answer_result exposes exactly the supported grading outcomes'
);

select extensions.results_eq(
  $$
    select e.enumlabel::text
    from pg_catalog.pg_type t
    join pg_catalog.pg_namespace n on n.oid = t.typnamespace
    join pg_catalog.pg_enum e on e.enumtypid = t.oid
    where n.nspname = 'public' and t.typname = 'device_platform'
    order by e.enumsortorder
  $$,
  $$values ('ios'::text), ('android'::text)$$,
  'device_platform rejects unsupported pass-length strategies'
);

select extensions.set_eq(
  $$
    select table_name::text
    from information_schema.tables
    where table_schema = 'public'
      and table_name in ('review_items', 'pass_state', 'attempts')
  $$,
  $$values ('review_items'::text), ('pass_state'::text), ('attempts'::text)$$,
  'the migration creates all three server-authoritative tables'
);

-- Keep each table's full shape in one readable contract assertion so an
-- accidental rename, type change, nullable field, or default is caught.
select extensions.results_eq(
  $$
    select
      column_name::text,
      udt_name::text,
      is_nullable::text,
      coalesce(column_default, '')::text
    from information_schema.columns
    where table_schema = 'public' and table_name = 'review_items'
    order by ordinal_position
  $$,
  $$
    values
      ('user_id'::text, 'uuid'::text, 'NO'::text, ''::text),
      ('question_id'::text, 'text'::text, 'NO'::text, ''::text),
      ('due_at'::text, 'timestamptz'::text, 'NO'::text, ''::text),
      ('interval_minutes'::text, 'int4'::text, 'NO'::text, '10'::text),
      ('consecutive_correct'::text, 'int4'::text, 'NO'::text, '0'::text)
  $$,
  'review_items mirrors ReviewItem and its defaults'
);

select extensions.results_eq(
  $$
    select
      column_name::text,
      udt_name::text,
      is_nullable::text,
      coalesce(column_default, '')::text
    from information_schema.columns
    where table_schema = 'public' and table_name = 'pass_state'
    order by ordinal_position
  $$,
  $$
    values
      ('user_id'::text, 'uuid'::text, 'NO'::text, ''::text),
      ('platform'::text, 'device_platform'::text, 'NO'::text, ''::text),
      ('pass_expires_at'::text, 'timestamptz'::text, 'YES'::text, ''::text),
      ('window_started_at'::text, 'timestamptz'::text, 'NO'::text, 'now()'::text),
      ('entries_this_window'::text, 'int4'::text, 'NO'::text, '0'::text),
      ('updated_at'::text, 'timestamptz'::text, 'NO'::text, 'now()'::text)
  $$,
  'pass_state persists platform-aware pass and rolling-window state'
);

select extensions.results_eq(
  $$
    select
      column_name::text,
      udt_name::text,
      is_nullable::text,
      coalesce(column_default, '')::text
    from information_schema.columns
    where table_schema = 'public' and table_name = 'attempts'
    order by ordinal_position
  $$,
  $$
    values
      ('id'::text, 'uuid'::text, 'NO'::text, 'gen_random_uuid()'::text),
      ('user_id'::text, 'uuid'::text, 'NO'::text, ''::text),
      ('question_id'::text, 'text'::text, 'NO'::text, ''::text),
      ('started_at'::text, 'timestamptz'::text, 'NO'::text, 'now()'::text),
      ('answered_at'::text, 'timestamptz'::text, 'YES'::text, ''::text),
      ('result'::text, 'answer_result'::text, 'YES'::text, ''::text),
      ('response_time_ms'::text, 'int4'::text, 'YES'::text, ''::text)
  $$,
  'attempts supports ungraded starts and graded outcomes'
);

select extensions.results_eq(
  $$
    select
      table_class.relname::text,
      array_agg(column_attribute.attname::text order by key_column.ordinality)::text[]
    from pg_catalog.pg_index table_index
    join pg_catalog.pg_class table_class on table_class.oid = table_index.indrelid
    join unnest(table_index.indkey) with ordinality as key_column(attnum, ordinality) on true
    join pg_catalog.pg_attribute column_attribute
      on column_attribute.attrelid = table_class.oid
     and column_attribute.attnum = key_column.attnum
    join pg_catalog.pg_namespace table_namespace on table_namespace.oid = table_class.relnamespace
    where table_namespace.nspname = 'public'
      and table_class.relname in ('review_items', 'pass_state', 'attempts')
      and table_index.indisprimary
    group by table_class.relname
    order by table_class.relname
  $$,
  $$
    values
      ('attempts'::text, array['id']::text[]),
      ('pass_state'::text, array['user_id']::text[]),
      ('review_items'::text, array['user_id', 'question_id']::text[])
  $$,
  'primary keys enforce one pass state and one review item per user/question'
);

select extensions.results_eq(
  $$
    select
      source_table.relname::text,
      source_column.attname::text,
      target_namespace.nspname::text,
      target_table.relname::text,
      target_column.attname::text,
      constraint_row.confdeltype::text
    from pg_catalog.pg_constraint constraint_row
    join pg_catalog.pg_class source_table on source_table.oid = constraint_row.conrelid
    join pg_catalog.pg_namespace source_namespace on source_namespace.oid = source_table.relnamespace
    join pg_catalog.pg_class target_table on target_table.oid = constraint_row.confrelid
    join pg_catalog.pg_namespace target_namespace on target_namespace.oid = target_table.relnamespace
    join pg_catalog.pg_attribute source_column
      on source_column.attrelid = source_table.oid
     and source_column.attnum = constraint_row.conkey[1]
    join pg_catalog.pg_attribute target_column
      on target_column.attrelid = target_table.oid
     and target_column.attnum = constraint_row.confkey[1]
    where source_namespace.nspname = 'public'
      and source_table.relname in ('review_items', 'pass_state', 'attempts')
      and constraint_row.contype = 'f'
    order by source_table.relname
  $$,
  $$
    values
      ('attempts'::text, 'user_id'::text, 'auth'::text, 'users'::text, 'id'::text, 'c'::text),
      ('pass_state'::text, 'user_id'::text, 'auth'::text, 'users'::text, 'id'::text, 'c'::text),
      ('review_items'::text, 'user_id'::text, 'auth'::text, 'users'::text, 'id'::text, 'c'::text)
  $$,
  'every user-scoped row cascades when its auth user is removed'
);

select extensions.results_eq(
  $$
    select
      table_class.relname::text,
      array_agg(column_attribute.attname::text order by key_column.ordinality)::text[]
    from pg_catalog.pg_index table_index
    join pg_catalog.pg_class table_class on table_class.oid = table_index.indrelid
    join unnest(table_index.indkey) with ordinality as key_column(attnum, ordinality) on true
    join pg_catalog.pg_attribute column_attribute
      on column_attribute.attrelid = table_class.oid
     and column_attribute.attnum = key_column.attnum
    join pg_catalog.pg_namespace table_namespace on table_namespace.oid = table_class.relnamespace
    where table_namespace.nspname = 'public'
      and table_class.relname in ('review_items', 'attempts')
      and not table_index.indisprimary
    group by table_class.relname
    order by table_class.relname
  $$,
  $$
    values
      ('attempts'::text, array['user_id', 'started_at']::text[]),
      ('review_items'::text, array['user_id', 'due_at']::text[])
  $$,
  'lookup indexes support per-user chronological queue and attempt reads'
);

select extensions.results_eq(
  $$
    select relname::text, relrowsecurity
    from pg_catalog.pg_class table_class
    join pg_catalog.pg_namespace table_namespace on table_namespace.oid = table_class.relnamespace
    where table_namespace.nspname = 'public'
      and relname in ('review_items', 'pass_state', 'attempts')
    order by relname
  $$,
  $$
    values
      ('attempts'::text, true),
      ('pass_state'::text, true),
      ('review_items'::text, true)
  $$,
  'RLS is enabled on every user-scoped table'
);

select extensions.results_eq(
  $$
    select
      tablename::text,
      policyname::text,
      cmd::text,
      roles::text,
      (qual = '(auth.uid() = user_id)') as owns_row,
      (with_check is null) as no_write_check
    from pg_catalog.pg_policies
    where schemaname = 'public'
      and tablename in ('review_items', 'pass_state', 'attempts')
    order by tablename, policyname
  $$,
  $$
    values
      ('attempts'::text, 'own_attempts'::text, 'SELECT'::text, '{public}'::text, true, true),
      ('pass_state'::text, 'own_pass_state'::text, 'SELECT'::text, '{public}'::text, true, true),
      ('review_items'::text, 'own_review_items'::text, 'SELECT'::text, '{public}'::text, true, true)
  $$,
  'clients receive only owner-scoped select policies'
);

select extensions.is(
  (
    select count(*)::bigint
    from pg_catalog.pg_policies
    where schemaname = 'public'
      and tablename in ('review_items', 'pass_state', 'attempts')
      and cmd <> 'SELECT'
  ),
  0::bigint,
  'no client write policy can bypass the grading function'
);

-- Seed through the migration-owner role, which models server/service-role writes.
insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-0000000000a1', 'schema-a@example.test'),
  ('00000000-0000-0000-0000-0000000000b2', 'schema-b@example.test'),
  ('00000000-0000-0000-0000-0000000000c3', 'schema-c@example.test');

insert into public.review_items (user_id, question_id, due_at)
values
  ('00000000-0000-0000-0000-0000000000a1', 'shared-question', '2030-01-01 00:00:00+00'),
  ('00000000-0000-0000-0000-0000000000a1', 'reading:craft-and-structure:1', '2030-01-02 00:00:00+00'),
  ('00000000-0000-0000-0000-0000000000b2', 'shared-question', '2030-01-03 00:00:00+00'),
  ('00000000-0000-0000-0000-0000000000c3', 'cascade-question', '2030-01-04 00:00:00+00');

insert into public.pass_state (user_id, platform)
values
  ('00000000-0000-0000-0000-0000000000a1', 'ios'),
  ('00000000-0000-0000-0000-0000000000b2', 'android'),
  ('00000000-0000-0000-0000-0000000000c3', 'ios');

insert into public.attempts (user_id, question_id)
values
  ('00000000-0000-0000-0000-0000000000a1', 'shared-question'),
  ('00000000-0000-0000-0000-0000000000b2', 'shared-question'),
  ('00000000-0000-0000-0000-0000000000c3', 'cascade-question');

select extensions.results_eq(
  $$
    select question_id, interval_minutes, consecutive_correct
    from public.review_items
    where user_id = '00000000-0000-0000-0000-0000000000a1'
      and question_id = 'reading:craft-and-structure:1'
  $$,
  $$values ('reading:craft-and-structure:1'::text, 10, 0)$$,
  'review items preserve non-UUID question IDs and scheduling defaults'
);

select extensions.ok(
  (
    select
      pass_expires_at is null
      and window_started_at is not null
      and entries_this_window = 0
      and updated_at is not null
    from public.pass_state
    where user_id = '00000000-0000-0000-0000-0000000000a1'
  ),
  'new pass state starts expired with an empty initialized window'
);

select extensions.ok(
  (
    select
      id is not null
      and started_at is not null
      and answered_at is null
      and result is null
      and response_time_ms is null
    from public.attempts
    where user_id = '00000000-0000-0000-0000-0000000000a1'
  ),
  'a started attempt is valid before grading fields are populated'
);

select extensions.throws_ok(
  $$
    insert into public.review_items (user_id, question_id, due_at)
    values (
      '00000000-0000-0000-0000-0000000000a1',
      'shared-question',
      '2031-01-01 00:00:00+00'
    )
  $$,
  '23505',
  null,
  'one user cannot have duplicate review rows for the same question'
);

select extensions.lives_ok(
  $$
    insert into public.attempts (user_id, question_id)
    values ('00000000-0000-0000-0000-0000000000a1', 'shared-question')
  $$,
  'repeated attempts for the same question remain valid history'
);

select extensions.is(
  (
    select count(*)::bigint
    from public.attempts
    where user_id = '00000000-0000-0000-0000-0000000000a1'
      and question_id = 'shared-question'
  ),
  2::bigint,
  'each repeated attempt receives its own row'
);

select extensions.throws_ok(
  $$
    insert into public.pass_state (user_id, platform)
    values ('00000000-0000-0000-0000-0000000000c3', 'web')
  $$,
  '22P02',
  null,
  'unsupported device platforms are rejected'
);

select extensions.throws_ok(
  $$
    update public.attempts
    set result = 'skipped'
    where user_id = '00000000-0000-0000-0000-0000000000a1'
  $$,
  '22P02',
  null,
  'unsupported answer outcomes are rejected'
);

select extensions.throws_ok(
  $$
    insert into public.attempts (user_id, question_id)
    values ('00000000-0000-0000-0000-000000000099', 'missing-user')
  $$,
  '23503',
  null,
  'attempts cannot outlive or bypass auth users'
);

update public.attempts
set
  answered_at = started_at + interval '1500 milliseconds',
  result = 'too_fast',
  response_time_ms = 1500
where user_id = '00000000-0000-0000-0000-0000000000b2';

select extensions.results_eq(
  $$
    select result::text, response_time_ms, answered_at > started_at
    from public.attempts
    where user_id = '00000000-0000-0000-0000-0000000000b2'
  $$,
  $$values ('too_fast'::text, 1500, true)$$,
  'the service role can complete attempts with too-fast timing data'
);

delete from auth.users where id = '00000000-0000-0000-0000-0000000000c3';

select extensions.results_eq(
  $$
    select relation_name, remaining_rows
    from (
      select 'attempts'::text as relation_name, count(*)::bigint as remaining_rows
      from public.attempts
      where user_id = '00000000-0000-0000-0000-0000000000c3'
      union all
      select 'pass_state'::text, count(*)::bigint
      from public.pass_state
      where user_id = '00000000-0000-0000-0000-0000000000c3'
      union all
      select 'review_items'::text, count(*)::bigint
      from public.review_items
      where user_id = '00000000-0000-0000-0000-0000000000c3'
    ) cascaded_rows
    order by relation_name
  $$,
  $$
    values
      ('attempts'::text, 0::bigint),
      ('pass_state'::text, 0::bigint),
      ('review_items'::text, 0::bigint)
  $$,
  'deleting an auth user cascades through every user-scoped table'
);

-- Exercise policy behavior as real client roles, not only through catalogs.
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';

select extensions.results_eq(
  $$
    select relation_name, visible_rows
    from (
      select 'attempts'::text as relation_name, count(*)::bigint as visible_rows from public.attempts
      union all
      select 'pass_state'::text, count(*)::bigint from public.pass_state
      union all
      select 'review_items'::text, count(*)::bigint from public.review_items
    ) visible
    order by relation_name
  $$,
  $$
    values
      ('attempts'::text, 2::bigint),
      ('pass_state'::text, 1::bigint),
      ('review_items'::text, 2::bigint)
  $$,
  'an authenticated user sees only their own server state'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

select extensions.results_eq(
  $$
    select relation_name, visible_rows
    from (
      select 'attempts'::text as relation_name, count(*)::bigint as visible_rows from public.attempts
      union all
      select 'pass_state'::text, count(*)::bigint from public.pass_state
      union all
      select 'review_items'::text, count(*)::bigint from public.review_items
    ) visible
    order by relation_name
  $$,
  $$
    values
      ('attempts'::text, 1::bigint),
      ('pass_state'::text, 1::bigint),
      ('review_items'::text, 1::bigint)
  $$,
  'switching JWT identity cannot leak another user''s rows'
);

select extensions.throws_ok(
  $$
    insert into public.review_items (user_id, question_id, due_at)
    values (
      '00000000-0000-0000-0000-0000000000b2',
      'client-write',
      '2030-01-01 00:00:00+00'
    )
  $$,
  '42501',
  null,
  'authenticated clients cannot insert review items'
);

select extensions.throws_ok(
  $$
    insert into public.pass_state (user_id, platform)
    values ('00000000-0000-0000-0000-0000000000c3', 'android')
  $$,
  '42501',
  null,
  'authenticated clients cannot insert pass state'
);

select extensions.throws_ok(
  $$
    insert into public.attempts (user_id, question_id)
    values ('00000000-0000-0000-0000-0000000000b2', 'client-write')
  $$,
  '42501',
  null,
  'authenticated clients cannot insert attempts'
);

select extensions.results_eq(
  $$
    with changed_review as (
      update public.review_items
      set consecutive_correct = 99
      returning 'review_items'::text as relation_name
    ), changed_pass as (
      update public.pass_state
      set entries_this_window = 99
      returning 'pass_state'::text
    ), changed_attempt as (
      update public.attempts
      set response_time_ms = 99
      returning 'attempts'::text
    )
    select relation_name from changed_review
    union all select relation_name from changed_pass
    union all select relation_name from changed_attempt
  $$,
  $$select null::text where false$$,
  'authenticated clients cannot update even their own rows'
);

select extensions.results_eq(
  $$
    with deleted_review as (
      delete from public.review_items returning 'review_items'::text as relation_name
    ), deleted_pass as (
      delete from public.pass_state returning 'pass_state'::text
    ), deleted_attempt as (
      delete from public.attempts returning 'attempts'::text
    )
    select relation_name from deleted_review
    union all select relation_name from deleted_pass
    union all select relation_name from deleted_attempt
  $$,
  $$select null::text where false$$,
  'authenticated clients cannot delete even their own rows'
);

reset role;
set local role anon;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000099';

select extensions.results_eq(
  $$
    select relation_name, visible_rows
    from (
      select 'attempts'::text as relation_name, count(*)::bigint as visible_rows from public.attempts
      union all
      select 'pass_state'::text, count(*)::bigint from public.pass_state
      union all
      select 'review_items'::text, count(*)::bigint from public.review_items
    ) visible
    order by relation_name
  $$,
  $$
    values
      ('attempts'::text, 0::bigint),
      ('pass_state'::text, 0::bigint),
      ('review_items'::text, 0::bigint)
  $$,
  'anonymous clients cannot read user-scoped state'
);

reset role;

select * from extensions.finish();
rollback;
