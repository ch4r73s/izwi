<?php

namespace App\Services\NetApi;

use Illuminate\Http\Client\Response;

class GatewayApi
{
    public function __construct(private readonly NetApiClient $client)
    {
    }

    /**
     * Server-to-server only — the returned smsUsername/smsPassword/apiKey
     * must never be forwarded to the browser.
     */
    public function credentials(): Response
    {
        return $this->client->get('/api/messagegatewayapi/credentials');
    }
}
