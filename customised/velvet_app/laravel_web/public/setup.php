<?php

/**
 * One-time deployment setup for cPanel hosts with no CLI/SSH access.
 *
 * This app has NO database (file sessions/cache, sync queue, pure API
 * client of dotnet_api) — there is nothing to migrate or seed. This
 * script only does what `php artisan` would otherwise be needed for:
 * generating APP_KEY, caching config/routes/views, and sanity-checking
 * that the server can actually reach dotnet_api and write to storage/.
 *
 * Protected by SETUP_SECRET in .env — set a random value there before
 * uploading, then visit:
 *   https://your-domain/setup.php?token=YOUR_SECRET
 *
 * DELETE THIS FILE (or use the "Delete this file now" button on the
 * result page) as soon as setup succeeds. Leaving it reachable is a
 * standing risk even with the token check.
 */

require __DIR__ . '/../vendor/autoload.php';

/** @var \Illuminate\Foundation\Application $app */
$app = require_once __DIR__ . '/../bootstrap/app.php';

/** @var \Illuminate\Contracts\Console\Kernel $kernel */
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Http;

header('Content-Type: text/html; charset=utf-8');

function render(array $steps, bool $success, ?string $selfDeleteUrl = null, ?string $extra = null): void
{
    $rows = '';
    foreach ($steps as $step) {
        $icon = $step['ok'] ? '&#9989;' : '&#10060;';
        $rows .= '<li><strong>' . $icon . ' ' . htmlspecialchars($step['label']) . '</strong>';
        if (!empty($step['detail'])) {
            $rows .= '<div style="color:#555;font-size:0.9em;margin-left:1.5em;">' . htmlspecialchars($step['detail']) . '</div>';
        }
        $rows .= '</li>';
    }

    $banner = $success
        ? '<p style="color:#0a7a2f;font-weight:bold;">Setup completed. Delete this file now.</p>'
        : '<p style="color:#b00020;font-weight:bold;">Setup did not fully complete — see the failed step(s) above before deleting this file.</p>';

    $deleteButton = $selfDeleteUrl
        ? '<form method="post" action="' . htmlspecialchars($selfDeleteUrl) . '"><input type="hidden" name="action" value="delete"><button type="submit" style="padding:0.6em 1.2em;background:#b00020;color:#fff;border:none;border-radius:4px;cursor:pointer;">Delete this file now</button></form>'
        : '';

    echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Izwi Web — Setup</title></head><body style="font-family:system-ui,sans-serif;max-width:640px;margin:2rem auto;padding:0 1rem;">';
    echo '<h1>Izwi Web — Deployment Setup</h1>';
    echo '<ul style="list-style:none;padding:0;">' . $rows . '</ul>';
    echo $banner;
    if ($extra) {
        echo '<pre style="background:#f5f5f5;padding:1em;overflow:auto;">' . htmlspecialchars($extra) . '</pre>';
    }
    echo $deleteButton;
    echo '</body></html>';
}

// --- Self-delete handler -----------------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'delete') {
    $ok = @unlink(__FILE__);
    echo $ok
        ? '<p style="font-family:sans-serif;">Deleted. Setup is finished.</p>'
        : '<p style="font-family:sans-serif;color:#b00020;">Could not delete this file automatically — remove public/setup.php manually via File Manager.</p>';
    exit;
}

// --- Token check ---------------------------------------------------------
$expected = config('netapi.setup_secret');
$given = $_GET['token'] ?? '';

if (empty($expected)) {
    http_response_code(500);
    echo '<p style="font-family:sans-serif;">SETUP_SECRET is not set in .env. Add a random value for SETUP_SECRET before running this script.</p>';
    exit;
}

if (!hash_equals((string) $expected, (string) $given)) {
    http_response_code(403);
    echo '<p style="font-family:sans-serif;">Forbidden. Append ?token=YOUR_SETUP_SECRET (the value of SETUP_SECRET in .env) to the URL.</p>';
    exit;
}

$force = ($_GET['force'] ?? '') === '1';
$steps = [];
$success = true;

// --- Step 1: APP_KEY -----------------------------------------------------
$envPath = __DIR__ . '/../.env';
$envContent = @file_get_contents($envPath);
$hasKey = $envContent !== false && preg_match('/^APP_KEY=base64:.+$/m', $envContent);

if ($hasKey && !$force) {
    $steps[] = ['label' => 'APP_KEY', 'ok' => true, 'detail' => 'Already set — skipped (pass ?force=1 to regenerate, which invalidates existing sessions).'];
} else {
    try {
        Artisan::call('key:generate', ['--force' => true]);
        $steps[] = ['label' => 'APP_KEY', 'ok' => true, 'detail' => 'Generated and written to .env.'];
    } catch (\Throwable $e) {
        $steps[] = ['label' => 'APP_KEY', 'ok' => false, 'detail' => $e->getMessage()];
        $success = false;
    }
}

// --- Step 2: writable directories ----------------------------------------
$paths = [
    'storage/framework/sessions',
    'storage/framework/views',
    'storage/framework/cache',
    'storage/logs',
    'bootstrap/cache',
];

foreach ($paths as $rel) {
    $full = __DIR__ . '/../' . $rel;
    $ok = is_dir($full) && is_writable($full);
    $steps[] = ['label' => "Writable: {$rel}", 'ok' => $ok, 'detail' => $ok ? null : 'Not writable — fix permissions via File Manager (usually 755, owned by the site user).'];
    $success = $success && $ok;
}

// --- Step 3: cache config/routes/views for production --------------------
try {
    Artisan::call('config:clear');
    Artisan::call('route:clear');
    Artisan::call('view:clear');
    Artisan::call('config:cache');
    Artisan::call('route:cache');
    Artisan::call('view:cache');
    $steps[] = ['label' => 'Cached config, routes, and views', 'ok' => true, 'detail' => 'Re-run this script (or clear caches) after any future .env change — cached config wins over .env until then.'];
} catch (\Throwable $e) {
    $steps[] = ['label' => 'Cached config, routes, and views', 'ok' => false, 'detail' => $e->getMessage()];
    $success = false;
}

// --- Step 4: no database — nothing to migrate/seed -----------------------
$steps[] = ['label' => 'Database migrations / seeding', 'ok' => true, 'detail' => 'Not applicable — this app has no database of its own (file sessions/cache, sync queue). It only talks to the existing dotnet_api backend.'];

// --- Step 5: connectivity to dotnet_api -----------------------------------
try {
    $base = config('netapi.base_url');
    $response = Http::timeout(10)->get(rtrim($base, '/') . '/health');
    $ok = $response->successful();
    $steps[] = [
        'label' => "Reach dotnet_api ({$base}/health)",
        'ok' => $ok,
        'detail' => $ok ? $response->body() : 'HTTP ' . $response->status() . ' — check NET_API_BASE_URL in .env and that this host can make outbound HTTPS requests.',
    ];
    $success = $success && $ok;
} catch (\Throwable $e) {
    $steps[] = ['label' => 'Reach dotnet_api', 'ok' => false, 'detail' => $e->getMessage()];
    $success = false;
}

$selfUrl = ($_SERVER['REQUEST_SCHEME'] ?? 'https') . '://' . $_SERVER['HTTP_HOST'] . $_SERVER['PHP_SELF'];
render($steps, $success, $selfUrl);
