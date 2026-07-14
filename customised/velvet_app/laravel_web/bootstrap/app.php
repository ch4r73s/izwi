<?php

use App\Exceptions\NetApiUnauthenticatedException;
use App\Http\Middleware\EnsureNetAuthenticated;
use App\Http\Middleware\RedirectIfNetAuthenticated;
use App\Services\Auth\NetAuthSession;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->web(append: [
            \App\Http\Middleware\HandleInertiaRequests::class,
            \Illuminate\Http\Middleware\AddLinkHeadersForPreloadedAssets::class,
        ]);

        $middleware->alias([
            'auth.net' => EnsureNetAuthenticated::class,
            'guest.net' => RedirectIfNetAuthenticated::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );

        $exceptions->render(function (NetApiUnauthenticatedException $e, Request $request) {
            app(NetAuthSession::class)->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('login')
                ->with('flash', ['error' => 'Your session expired, please log in again.']);
        });
    })->create();
