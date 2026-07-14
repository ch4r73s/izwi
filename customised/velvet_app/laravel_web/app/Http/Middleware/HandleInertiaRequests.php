<?php

namespace App\Http\Middleware;

use App\Services\Auth\NetAuthSession;
use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    /**
     * The root template that is loaded on the first page visit.
     *
     * @var string
     */
    protected $rootView = 'app';

    public function __construct(private readonly NetAuthSession $auth)
    {
    }

    /**
     * Determine the current asset version.
     */
    public function version(Request $request): ?string
    {
        return parent::version($request);
    }

    /**
     * Define the props that are shared by default.
     *
     * @return array<string, mixed>
     */
    public function share(Request $request): array
    {
        return [
            ...parent::share($request),
            'auth' => [
                'user' => $this->auth->user(),
            ],
            'flash' => [
                'success' => fn () => $request->session()->get('flash.success'),
                'error' => fn () => $request->session()->get('flash.error'),
            ],
        ];
    }
}
