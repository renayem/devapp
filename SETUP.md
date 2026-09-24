# Rising Sun cloud/PWA setup

This version keeps the public league information separate from the private player master list.

## 1. Create/connect Supabase

Create a Supabase project, or connect Supabase to the Vercel project. Vercel's Supabase integration can synchronise the relevant environment variables for supported setups.

## 2. Create the database/security rules

Open Supabase **SQL Editor**, paste `supabase-schema.sql`, and run it.

The schema creates:
- `profiles` — authorised-user flag
- `league_public_state` — weeks, matches, results and saved high scorers; readable publicly
- `league_private_state` — player master list and preferences; authorised users only

## 3. Create authorised users

Create the users in **Supabase Authentication > Users**.

The trigger creates each user's `profiles` row with `authorised = false`.

After creating a user, run:

```sql
update public.profiles
set authorised = true
where id = 'THE-USER-UUID-HERE';
```

Only users with `authorised = true` can use the restricted areas.

For tighter control, disable public sign-up in Supabase Auth and create the authorised accounts yourself.

## 4. Connect this static PWA to Supabase

The HTML contains these two configuration variables near the top of `<body>`:

```js
window.RISING_SUN_SUPABASE_URL="";
window.RISING_SUN_SUPABASE_PUBLISHABLE_KEY="";
```

Replace the empty strings with the Supabase **Project URL** and **Publishable/anon key** from your Supabase project settings.

Do **not** put a Supabase secret/service-role key in this file. The browser version must only use the publishable key, with RLS enforcing access.

## 5. Deploy to Vercel

Upload/deploy the contents of this directory as the site root. The existing service worker/manifest from the PWA can then be added to this version.

## Behaviour

Public users can see:
- Schedule
- Previous Weeks Matches
- Results
- Saved Weekly High Scorers

Authorised users can additionally:
- open Player's Master List
- schedule games
- enter/save Weekly High Scorer
- edit/save matches
- save results

The database, not just the interface, enforces the private/public boundary.
