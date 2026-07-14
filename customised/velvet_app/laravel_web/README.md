# Izwi Web

A web fallback for sending SMS when the Izwi mobile app isn't available. Built
with Laravel + Inertia.js + React + TypeScript + Tailwind.

## Architecture

- **No database of its own.** This app is a pure client of the existing
  `dotnet_api` backend (live at `https://izwi-api.steinovate.com`) for
  everything — auth, recipients, notifications, billing. Sessions use the
  `file` driver, cache is `file`, queue is `sync`. Nothing here needs
  migrations or seeding.
- **SMS is sent server-side.** The Laravel backend fetches SMS gateway
  credentials from `dotnet_api` server-to-server and posts to the Tumirai
  gateway itself — credentials never reach the browser (unlike the mobile
  app, which sends directly from the device).
- **Auth is a JWT proxy**, not Laravel's normal database auth. `app/Services/Auth/NetAuthSession.php`
  stores the `dotnet_api`-issued access/refresh tokens and minimal user info
  in Laravel's encrypted session; `app/Services/NetApi/NetApiClient.php` is
  the single choke point for every outbound API call, handling token refresh.
- **Template resolution and SMS billing math are ported exactly from the
  Flutter app** (`app/Services/Sms/TemplateResolver.php`), not from
  `dotnet_api`'s own resolver, so billing stays consistent regardless of
  which client sent the message.

## Local development

```bash
composer install
npm install
cp .env.example .env
php artisan key:generate
npm run dev        # Vite dev server, in one terminal
php artisan serve  # in another
```

Set `NET_API_BASE_URL` in `.env` to point at either the live API
(`https://izwi-api.steinovate.com`, has real data) or a local `dotnet_api`
instance.

No `php artisan migrate` step — there's nothing to migrate.

## Deploying to Namecheap cPanel (no terminal)

A ready-to-upload package can be built locally and uploaded via cPanel File
Manager — no SSH, Composer, or Node needed on the server itself.

### Building the package (on your dev machine)

```bash
npm run build
# then, in a throwaway copy of this folder (not your working copy —
# --no-dev strips packages like phpunit that local dev still needs):
composer install --no-dev --optimize-autoloader
```

Zip that copy with something that writes forward-slash paths — **not**
PowerShell's `Compress-Archive`, which has produced zips cPanel's `unzip`
can't extract (scattered `checkdir: Permission denied` errors, with a
"backslashes as path separators" warning). Use PHP's `ZipArchive` instead
(a short script suffices, or 7-Zip/`zip` if available). Verify by extracting
the result locally and confirming file counts match before uploading.

The zip should contain: `vendor/` (production only), `public/build/`
(compiled frontend), and a `.env` pre-filled with production defaults —
`APP_ENV=production`, `APP_DEBUG=false`, `SESSION_DRIVER=file`,
`CACHE_STORE=file`, `QUEUE_CONNECTION=sync`, the real `APP_URL`, and a random
`SETUP_SECRET` (see below). Leave `APP_KEY` blank.

**If the site doesn't have HTTPS**, set `SESSION_SECURE_COOKIE=false` — a
"secure" cookie is silently dropped by the browser over plain HTTP, which
breaks login with no visible error (you just get bounced back to the login
page). Switch it to `true` (and `APP_URL` to `https://`) once SSL/AutoSSL is
enabled, then re-run setup (see below) to re-cache config.

### 1. Upload and extract

1. In cPanel → **File Manager**, go to your home directory (one level
   *above* `public_html` — do **not** extract into `public_html` itself).
2. Upload the zip, then right-click it → **Extract**.
3. Rename the extracted folder to something clean, e.g. `izwi-web`.

Layout should end up:

```
~/izwi-web/            <- the whole Laravel app (NOT web-accessible)
~/izwi-web/public/     <- this is what the domain must point at
~/public_html/         <- untouched, other sites live here
```

### 2. Point the domain at `public/`

cPanel → **Domains** (or **Subdomains**) → find the domain/subdomain → set
its **Document Root** to:

```
izwi-web/public
```

This is the step that's easiest to skip or get wrong — if it's missed, or
the extracted folder name doesn't match what you typed here, every URL on
the domain (including `/setup.php`) 404s, often via a **generic themed error
page from the hosting platform**, not a Laravel error — because the request
never reaches Laravel at all. If `setup.php` 404s, check this step first
before anything else.

### 3. Set the PHP version

cPanel → **MultiPHP Manager** (or **Select PHP Version**) → set this domain
to **PHP 8.3 or newer**. Extensions needed (usually on by default):
`openssl`, `mbstring`, `tokenizer`, `xml`, `ctype`, `json`, `bcmath`,
`fileinfo`, `curl`.

### 4. Run setup

Visit, in a browser:

```
https://your-domain/setup.php?token=<the SETUP_SECRET value from .env>
```

This is a plain PHP file — visiting the URL *is* running it, no separate
"execute" step exists. It does everything `php artisan` would otherwise be
needed for. It does **not** touch a database (this app doesn't have one):

- Generates `APP_KEY` (once — safe to reload, won't regenerate unless you add `&force=1`)
- Confirms `storage/` and `bootstrap/cache/` are writable
- Caches config/routes/views for production
- Confirms the server can actually reach `dotnet_api`'s `/health` endpoint

All green checkmarks expected. Safe to reload repeatedly if something's red
— fix it and reload.

### 5. Delete `setup.php`

Click **"Delete this file now"** on the result page, or delete
`~/izwi-web/public/setup.php` manually. Don't skip this — it's
token-protected, but a setup endpoint has no reason to exist afterward.

### 6. Test it

Visit `https://your-domain/login` and sign in with a real `dotnet_api`
account.

## Troubleshooting

**`setup.php` (or anything else) 404s, especially via a themed/generic error
page rather than a Laravel one.** The domain's Document Root isn't actually
pointing at `izwi-web/public` (step 2), or the extracted folder name doesn't
match what was typed there. The request is being served by the hosting
platform's default location, never reaching this app at all — check cPanel
→ Domains for the exact current Document Root value and compare it byte for
byte against the real extracted folder path.

**Blank page / generic 500 error.** `APP_DEBUG=false` hides details on
purpose. Check `~/izwi-web/storage/logs/laravel.log`. To see the error
in-browser temporarily: flip `APP_DEBUG=true` in `.env`, delete
`~/izwi-web/bootstrap/cache/config.php` (forces a fresh `.env` read), reload,
then set it back to `false` and re-run `setup.php` to re-cache.

**Setup fails on "writable" checks.** Select the flagged folder in File
Manager → Permissions → set `755` (owned by your site's user).

**Setup fails to reach dotnet_api.** Some shared hosts have an incomplete CA
bundle for outbound HTTPS from PHP — hit exactly this in local dev, fixed by
pointing PHP at a fresh `cacert.pem` (`curl.cainfo`/`openssl.cafile` in
`php.ini`). If it happens on the host, ask hosting support to check/update
PHP's CA bundle. Never work around it by disabling SSL verification in code.

**CSS/JS missing, page looks unstyled.** Document root isn't actually
pointing at `izwi-web/public` — see the 404 entry above, same root cause.

**Login appears to silently fail / bounces back to the login page with no
error, on an HTTP-only (no SSL) site.** `SESSION_SECURE_COOKIE` is `true`
while the site has no HTTPS — the browser drops the cookie. Set it to
`false` in `.env` and re-run `setup.php`.

## Updating later

No CLI on the server, so an update means rebuilding locally (`npm run build`,
`composer install --no-dev --optimize-autoloader` in a throwaway copy) and
re-zipping (PHP `ZipArchive`, not `Compress-Archive`) — but **don't just
extract the new zip over the live folder.** The zip's `.env` is a fresh
template with a blank `APP_KEY` and default `APP_URL`/`SESSION_SECURE_COOKIE`
— overwriting the live `.env` with it wipes the real generated `APP_KEY`
(logging everyone out) and any settings changed since the first deploy (e.g.
switching to HTTPS). Safe update procedure:

1. Upload and extract the new zip into a **new** folder next to the live one
   (e.g. `izwi-web-new`), not on top of it.
2. Copy the *live* `~/izwi-web/.env` over to `~/izwi-web-new/.env` via File
   Manager, so the real `APP_KEY` and any settings you've since changed
   carry forward unchanged.
3. Rename `~/izwi-web` → `~/izwi-web-old` (keep as a rollback copy), then
   rename `~/izwi-web-new` → `~/izwi-web`.
4. Re-run `setup.php` (recreate it from the new zip first if you'd deleted
   it) — the config/route/view caches are per-build and must be regenerated
   against the new code even though `APP_KEY` itself doesn't need
   regenerating this time (`setup.php` skips that step automatically when
   `APP_KEY` is already set).
5. Delete `setup.php` again, test, then delete `~/izwi-web-old` once
   confirmed working.
