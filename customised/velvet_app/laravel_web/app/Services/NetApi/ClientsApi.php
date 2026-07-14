<?php

namespace App\Services\NetApi;

use Illuminate\Http\Client\Response;

class ClientsApi
{
    public function __construct(private readonly NetApiClient $client)
    {
    }

    public function my(): Response
    {
        return $this->client->get('/api/clients/my');
    }

    public function recordSms(int $count): Response
    {
        return $this->client->post('/api/clients/my/record-sms', ['count' => $count]);
    }
}
