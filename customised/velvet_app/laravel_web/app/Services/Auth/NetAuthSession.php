<?php

namespace App\Services\Auth;

use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Session;

/**
 * Holds the .NET API's JWT access/refresh tokens and the minimal current-user
 * fields in Laravel's own (file-backed, encrypted) session. There is no
 * `users` table — this app is a pure client of dotnet_api's auth endpoints.
 */
class NetAuthSession
{
    private const KEY = 'net_auth';

    public function login(string $accessToken, string $refreshToken, array $user): void
    {
        Session::put(self::KEY, [
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken,
            // dotnet_api issues access tokens with a fixed 15 minute expiry
            // (AuthController.cs GenerateTokens) — computed here rather than
            // decoded from the JWT to keep this class dependency-free.
            'access_expires_at' => Carbon::now()->addMinutes(15)->toIso8601String(),
            'user' => [
                'id' => $user['id'],
                'username' => $user['username'],
                'email' => $user['email'],
                'displayName' => $user['displayName'],
                'role' => $user['role'],
            ],
        ]);
    }

    public function updateTokens(string $accessToken, string $refreshToken): void
    {
        Session::put(self::KEY . '.access_token', $accessToken);
        Session::put(self::KEY . '.refresh_token', $refreshToken);
        Session::put(self::KEY . '.access_expires_at', Carbon::now()->addMinutes(15)->toIso8601String());
    }

    public function logout(): void
    {
        Session::forget(self::KEY);
    }

    public function check(): bool
    {
        return Session::has(self::KEY . '.access_token');
    }

    public function user(): ?array
    {
        return Session::get(self::KEY . '.user');
    }

    public function accessToken(): ?string
    {
        return Session::get(self::KEY . '.access_token');
    }

    public function refreshToken(): ?string
    {
        return Session::get(self::KEY . '.refresh_token');
    }

    public function isAccessTokenExpiringSoon(): bool
    {
        $expiresAt = Session::get(self::KEY . '.access_expires_at');

        if ($expiresAt === null) {
            return true;
        }

        // No server-side clock skew tolerance on dotnet_api's end, so refresh
        // a little ahead of the real expiry rather than right at the wire.
        return Carbon::now()->addSeconds(30)->gte(Carbon::parse($expiresAt));
    }
}
