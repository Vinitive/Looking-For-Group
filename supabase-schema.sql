-- Looking For Group: run this in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Player',
  created_at timestamptz not null default now()
);

create table if not exists public.lobbies (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  game text not null,
  title text not null check (char_length(title) between 3 and 65),
  description text not null default '' check (char_length(description) <= 240),
  platform text not null check (platform in ('PC','Xbox','PlayStation','Crossplay')),
  mode text not null default 'Any',
  region text not null default '',
  max_players integer not null default 4 check (max_players between 2 and 100),
  discord text not null default '',
  discord_invite text not null default '',
  xbox text not null default '',
  psn text not null default '',
  status text not null default 'open' check (status in ('open','closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.lobby_members (
  lobby_id uuid not null references public.lobbies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (lobby_id,user_id)
);

create index if not exists lobbies_status_created_idx on public.lobbies(status,created_at desc);
create index if not exists lobbies_game_idx on public.lobbies(game);
create index if not exists lobby_members_user_idx on public.lobby_members(user_id);

alter table public.profiles enable row level security;
alter table public.lobbies enable row level security;
alter table public.lobby_members enable row level security;

drop policy if exists "Profiles are publicly readable" on public.profiles;
create policy "Profiles are publicly readable" on public.profiles for select using (true);
drop policy if exists "Users create own profile" on public.profiles;
create policy "Users create own profile" on public.profiles for insert with check (auth.uid() = id);
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "Anyone can view open lobbies" on public.lobbies;
create policy "Anyone can view open lobbies" on public.lobbies for select using (status = 'open' or auth.uid() = owner_id);
drop policy if exists "Signed-in users create own lobbies" on public.lobbies;
create policy "Signed-in users create own lobbies" on public.lobbies for insert with check (auth.uid() = owner_id);
drop policy if exists "Owners update own lobbies" on public.lobbies;
create policy "Owners update own lobbies" on public.lobbies for update using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
drop policy if exists "Owners delete own lobbies" on public.lobbies;
create policy "Owners delete own lobbies" on public.lobbies for delete using (auth.uid() = owner_id);

drop policy if exists "Members visible to signed-in users" on public.lobby_members;
create policy "Members visible to signed-in users" on public.lobby_members for select using (auth.uid() is not null);
drop policy if exists "Users join as themselves" on public.lobby_members;
create policy "Users join as themselves" on public.lobby_members for insert with check (auth.uid() = user_id);
drop policy if exists "Users leave own memberships" on public.lobby_members;
create policy "Users leave own memberships" on public.lobby_members for delete using (auth.uid() = user_id);

-- Automatically create a profile when a new account is registered.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();
