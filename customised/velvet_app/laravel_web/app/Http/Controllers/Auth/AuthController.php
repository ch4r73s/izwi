<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Services\Auth\NetAuthSession;
use App\Services\NetApi\AuthApi;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class AuthController extends Controller
{
    public function __construct(
        private readonly AuthApi $authApi,
        private readonly NetAuthSession $auth,
    ) {
    }

    public function create(): Response
    {
        return Inertia::render('Auth/Login');
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'identifier' => ['required', 'string'],
            'password' => ['required', 'string'],
        ]);

        $response = $this->authApi->login($validated['identifier'], $validated['password']);

        if ($response->status() === 401) {
            return back()->withErrors(['identifier' => 'Invalid username/email or password.']);
        }

        if (! $response->successful()) {
            return back()->withErrors(['identifier' => 'Unable to reach the server. Please try again.']);
        }

        $data = $response->json();
        $this->auth->login($data['accessToken'], $data['refreshToken'], $data['user']);

        $request->session()->regenerate();

        return redirect()->intended(route('dashboard'));
    }

    public function destroy(Request $request): RedirectResponse
    {
        // Logout is a documented server-side no-op (no token blacklist) —
        // best-effort only, never block the local logout on it.
        try {
            $this->authApi->logout();
        } catch (\Throwable) {
            //
        }

        $this->auth->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
    }
}
