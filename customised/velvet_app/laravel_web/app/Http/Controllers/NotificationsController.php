<?php

namespace App\Http\Controllers;

use App\Services\NetApi\NotificationsApi;
use Inertia\Inertia;
use Inertia\Response;

class NotificationsController extends Controller
{
    public function __construct(private readonly NotificationsApi $api)
    {
    }

    public function index(): Response
    {
        $response = $this->api->sent();

        // GET /api/notifications/sent returns everything with no
        // server-side pagination — grouping/virtualizing is handled
        // client-side in Notifications/Index.tsx.
        $notifications = $response->successful() ? $response->json() : [];

        return Inertia::render('Notifications/Index', [
            'notifications' => $notifications,
        ]);
    }
}
