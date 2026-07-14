<?php

namespace App\Http\Controllers;

use App\Services\NetApi\ClientsApi;
use Inertia\Inertia;
use Inertia\Response;

class DashboardController extends Controller
{
    public function __construct(private readonly ClientsApi $api)
    {
    }

    public function index(): Response
    {
        $response = $this->api->my();

        return Inertia::render('Dashboard', [
            // Admin users typically have no Client/subscription of their
            // own (they manage other clients, not send SMS themselves) —
            // a 404 here is expected for that role, not an error.
            'client' => $response->successful() ? $response->json() : null,
        ]);
    }
}
