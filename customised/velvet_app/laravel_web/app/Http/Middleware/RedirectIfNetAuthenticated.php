<?php

namespace App\Http\Middleware;

use App\Services\Auth\NetAuthSession;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RedirectIfNetAuthenticated
{
    public function __construct(private readonly NetAuthSession $auth)
    {
    }

    public function handle(Request $request, Closure $next): Response
    {
        if ($this->auth->check()) {
            return redirect()->route('dashboard');
        }

        return $next($request);
    }
}
