<?php

namespace App\Services\NetApi;

use App\Exceptions\NetApiUnauthenticatedException;
use App\Services\Auth\NetAuthSession;
use Illuminate\Http\Client\Response;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;

/**
 * Single choke point for every call to dotnet_api. Attaches the bearer
 * token, refreshes it proactively before it's 15-minute lifetime runs out,
 * and falls back to a single refresh+retry on a reactive 401.
 *
 * dotnet_api has no global exception handler: 4xx bodies are `{"message":...}`
 * but a plain Unauthorized()/Forbid() has an EMPTY body, so callers of this
 * class must never assume a JSON body is present on 401/403.
 */
class NetApiClient
{
    public function __construct(private readonly NetAuthSession $auth)
    {
    }

    public function get(string $path, array $query = [], bool $authenticated = true): Response
    {
        return $this->send('get', $path, $query, $authenticated);
    }

    public function post(string $path, array $body = [], bool $authenticated = true): Response
    {
        return $this->send('post', $path, $body, $authenticated);
    }

    public function put(string $path, array $body = [], bool $authenticated = true): Response
    {
        return $this->send('put', $path, $body, $authenticated);
    }

    public function patch(string $path, array $body = [], bool $authenticated = true): Response
    {
        return $this->send('patch', $path, $body, $authenticated);
    }

    public function delete(string $path, bool $authenticated = true): Response
    {
        return $this->send('delete', $path, [], $authenticated);
    }

    private function send(string $method, string $path, array $payload, bool $authenticated): Response
    {
        if ($authenticated) {
            $this->ensureFreshToken();
        }

        $response = $this->client($authenticated)->send($method, $path, $this->payloadFor($method, $payload));

        if ($authenticated && $response->status() === 401) {
            if (! $this->refreshTokens()) {
                throw new NetApiUnauthenticatedException('Session expired and could not be refreshed.');
            }

            $response = $this->client(true)->send($method, $path, $this->payloadFor($method, $payload));

            if ($response->status() === 401) {
                throw new NetApiUnauthenticatedException('Session expired.');
            }
        }

        return $response;
    }

    private function payloadFor(string $method, array $payload): array
    {
        return strtolower($method) === 'get' ? ['query' => $payload] : ['json' => $payload];
    }

    private function client(bool $authenticated): PendingRequest
    {
        $client = Http::baseUrl(config('netapi.base_url'))
            ->timeout(config('netapi.timeout'))
            ->acceptJson();

        if ($authenticated && $this->auth->accessToken()) {
            $client = $client->withToken($this->auth->accessToken());
        }

        return $client;
    }

    private function ensureFreshToken(): void
    {
        if ($this->auth->check() && $this->auth->isAccessTokenExpiringSoon()) {
            $this->refreshTokens();
        }
    }

    /**
     * Calls dotnet_api's /api/auth/refresh directly (not via AuthApi, to
     * avoid a circular dependency) and updates the session on success.
     */
    private function refreshTokens(): bool
    {
        $refreshToken = $this->auth->refreshToken();

        if (! $refreshToken) {
            return false;
        }

        $response = Http::baseUrl(config('netapi.base_url'))
            ->timeout(config('netapi.timeout'))
            ->acceptJson()
            ->post('/api/auth/refresh', ['refreshToken' => $refreshToken]);

        if (! $response->successful()) {
            return false;
        }

        $data = $response->json();

        if (! isset($data['accessToken'], $data['refreshToken'])) {
            return false;
        }

        $this->auth->updateTokens($data['accessToken'], $data['refreshToken']);

        return true;
    }
}
