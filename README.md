# ShopStock BD

A full-stack inventory and sales manager designed for one small shop. ShopStock BD helps shop owners track products, watch low stock, record multi-item sales, and keep a searchable receipt history in Bangladeshi taka.

## Features

- Email/password authentication and first-login shop setup
- Product catalog with categories, optional SKU, cost and selling prices, stock thresholds, search, and archive
- Dashboard for today's sales, product counts, recent receipts, and low-stock alerts
- Multi-product sale cart with stock validation and atomic PostgreSQL stock updates
- Receipt snapshots preserve product names and prices as they were at sale time
- Sales history, date filter, and CSV export
- Asia/Dhaka display time zone and BDT formatting
- Responsive layouts, accessible labels, loading, empty, error, and success states

## Stack

React, TypeScript, Vite, Supabase (PostgreSQL, Auth, RLS, RPC), and Cloudflare Pages.

## Local setup

Prerequisites: Node.js 20+ and npm. A Supabase project is required for authentication and persistent data.

1. Install dependencies: `npm install`
2. Copy `.env.example` to `.env.local` and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` from your Supabase project's API settings. Use the publishable/anon browser key only. Never put a secret or service-role key in a `VITE_` variable.
3. Apply the SQL migration in `supabase/migrations/202610230001_initial_schema.sql` using the Supabase SQL Editor, or link the project with the Supabase CLI and run `supabase db push`.
4. In Supabase Authentication settings, configure the site URL and allowed redirect URLs for local development and your production domain. Disable email confirmation only if that fits your own authentication policy.
5. Run `npm run dev` and open the Vite URL.

If the Supabase environment values are absent, the app starts in clearly labelled preview mode with temporary sample data. Preview data is local UI state and is not persisted to a real database.

## Database and security

The migration creates `shops`, `products`, `sales`, and `sale_items`, with foreign keys, constraints, indexes, cascading deletion from shop to its data, and RLS enabled on every app table. Policies scope all operations to the authenticated shop owner. Anonymous access is revoked. `record_sale` is a `SECURITY DEFINER` transaction that verifies the caller owns the shop, validates quantities and product membership, locks stock rows, rejects insufficient inventory, saves name/price snapshots, and decrements stock atomically.

Review migrations in a non-production Supabase project before applying them to a live database. Do not add real shop or customer data to this repository. `supabase/seed.sql` contains intentionally fictional demo fixtures for local development only; do not run its sample values against a production database.

## Tests and checks

- `npm test` — calculation, sale validation, and currency formatting tests
- `npm run typecheck` — TypeScript checks
- `npm run build` — production build

## Deploy to Cloudflare Pages

Create a Pages project connected to the GitHub repository. Use the Vite preset or set the build command to `npm run build` and build output directory to `dist`. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` as Pages environment variables for production (and preview if desired). Configure matching Supabase Auth site and redirect URLs. Never provide a Supabase secret key to Pages frontend builds.

## Free-tier notes

Supabase and Cloudflare free plans have provider-set usage, build, storage, and inactivity limits that may change. Confirm current limits in the provider dashboards. Backups, uptime guarantees, and custom domains may differ by plan. The app does not process payments and does not collect customer personal information.

## Portfolio description

**ShopStock BD** — Built a responsive full-stack inventory and sales manager for small shops using React, TypeScript, Vite, Supabase, PostgreSQL, and Cloudflare Pages. Implemented email authentication, owner-scoped row-level security, transactional stock updates through a validated PostgreSQL RPC, immutable receipt snapshots, searchable product management, low-stock alerts, and BDT sales reporting with Asia/Dhaka time formatting.

## Manual verification checklist

- Create a Supabase project, apply the migration, and configure the publishable environment variables.
- Verify signup/email confirmation, login, shop setup, and logout with a real Supabase Auth account.
- Create, edit, archive, search, and filter products against Supabase.
- Record a multi-item sale; verify the receipt snapshot and stock decrement in PostgreSQL.
- Try zero, fractional, and over-stock sale quantities; confirm the RPC rejects them and stock remains unchanged.
- Use a second account and verify it cannot read or modify the first shop's rows.
- Verify Supabase Auth redirect URLs and the Cloudflare Pages domain after deployment.
- Push to GitHub and connect the repository to Cloudflare Pages after choosing repository visibility.
