# Looking For Group

A cross-platform gaming LFG hub. Players browse a catalog of games, create public lobbies, and share the contact details other players need to squad up.

## Stack
- Static frontend (HTML, CSS, JavaScript)
- Supabase Auth + Postgres for accounts and shared lobbies
- GitHub Pages hosting

## Run locally
Open `index.html` in a local web server. Without Supabase credentials the page runs in preview mode with sample lobbies; accounts and shared lobby persistence require Supabase.

## Connect Supabase
1. Create a Supabase project.
2. In the Supabase SQL Editor, run `supabase-schema.sql`.
3. Copy your project URL and anon/publishable key into `config.js`.
4. Enable Email auth in Supabase Authentication settings.
5. Deploy through GitHub Pages: Settings → Pages → Deploy from branch → `main` → `/ (root)`.

Never put a Supabase `service_role` key in frontend code. Only use the anon/publishable key; Row Level Security policies are included in the SQL schema.
