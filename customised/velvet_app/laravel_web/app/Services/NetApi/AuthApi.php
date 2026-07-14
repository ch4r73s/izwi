<?php

namespace App\Services\NetApi;

use Illuminate\Http\Client\Response;

class AuthApi
{
    public function __construct(private readonly NetApiClient $client)
    {
    }

    public function login(string $identifier, string $password): Response
    {
        return $this->client->post('/api/auth/login', [
            'identifier' => $identifier,
            'password' => $password,
        ], authenticated: false);
    }

    public function logout(): Response
    {
        return $this->client->post('/api/auth/logout');
    }
}
