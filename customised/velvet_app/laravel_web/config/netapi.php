<?php

return [
    'base_url' => env('NET_API_BASE_URL', 'https://izwi-api.steinovate.com'),
    'timeout' => (int) env('NET_API_TIMEOUT', 30),

    // Gated behind a flag until the corresponding dotnet_api RecipientsController
    // change (optional isActive on update) has been deployed.
    'recipient_pause_enabled' => (bool) env('NET_API_RECIPIENT_PAUSE_ENABLED', true),

    // Protects public/setup.php on hosts with no CLI access. Set to a random
    // value in .env before deploying, then delete setup.php once it's run.
    'setup_secret' => env('SETUP_SECRET'),
];
