-- Rising Sun Ladies Darts & Dominoes
-- Run this once in Supabase SQL Editor.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  authorised boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.league_public_state (
  id integer primary key check (id = 1),
  state jsonb not null default '{"weeks":[],"resultTotals":{},"highScorers":[]}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.league_private_state (
  id integer primary key check (id = 1),
  state jsonb not null default '{"players":[],"prefs":{}}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Automatically create a non-authorised profile whenever a Supabase Auth user is created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, authorised)
  values (new.id, false)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.league_public_state enable row level security;
alter table public.league_private_state enable row level security;

revoke all on public.profiles from anon, authenticated;
revoke all on public.league_public_state from anon, authenticated;
revoke all on public.league_private_state from anon, authenticated;

grant select on public.profiles to authenticated;
grant select on public.league_public_state to anon, authenticated;
grant select, insert, update, delete on public.league_public_state to authenticated;
grant select, insert, update, delete on public.league_private_state to authenticated;

-- A signed-in user can only see their own authorisation record.
drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile"
on public.profiles for select
to authenticated
using (id = auth.uid());

-- Public league information is readable without login.
drop policy if exists "Public can read league state" on public.league_public_state;
create policy "Public can read league state"
on public.league_public_state for select
to anon, authenticated
using (true);

-- Only authorised users can change public league information.
drop policy if exists "Authorised users can insert public state" on public.league_public_state;
create policy "Authorised users can insert public state"
on public.league_public_state for insert
to authenticated
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.authorised = true));

drop policy if exists "Authorised users can update public state" on public.league_public_state;
create policy "Authorised users can update public state"
on public.league_public_state for update
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.authorised = true))
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.authorised = true));

drop policy if exists "Authorised users can delete public state" on public.league_public_state;
create policy "Authorised users can delete public state"
on public.league_public_state for delete
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.authorised = true));

-- Player master list/preferences are private and available only to authorised users.
drop policy if exists "Authorised users can read private state" on public.league_private_state;
create policy "Authorised users can read private state"
on public.league_private_state for select
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.authorised = true));

drop policy if exists "Authorised users can insert private state" on public.league_private_state;
create policy "Authorised users can insert private state"
on public.league_private_state for insert
to authenticated
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.authorised = true));

drop policy if exists "Authorised users can update private state" on public.league_private_state;
create policy "Authorised users can update private state"
on public.league_private_state for update
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.authorised = true))
with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.authorised = true));

drop policy if exists "Authorised users can delete private state" on public.league_private_state;
create policy "Authorised users can delete private state"
on public.league_private_state for delete
to authenticated
using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.authorised = true));

-- Optional initial public/private rows. Safe to run more than once.
insert into public.league_public_state (id)
values (1)
on conflict (id) do nothing;

insert into public.league_private_state (id)
values (1)
on conflict (id) do nothing;
