<?php

namespace App\Http\Controllers;

use App\Services\NetApi\RecipientsApi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class RecipientsController extends Controller
{
    public function __construct(private readonly RecipientsApi $api)
    {
    }

    public function index(): Response
    {
        return Inertia::render('Recipients/Index', [
            'pauseEnabled' => config('netapi.recipient_pause_enabled'),
        ]);
    }

    public function search(Request $request): JsonResponse
    {
        $page = max(1, (int) $request->query('page', 1));
        $pageSize = min(100, max(1, (int) $request->query('pageSize', 20)));
        $search = $request->query('search');
        $district = $request->query('district');

        $response = $this->api->my($page, $pageSize, $search, $district);

        if (! $response->successful()) {
            return response()->json(['message' => $response->json('message') ?? 'Unable to load recipients.'], $response->status());
        }

        $recipients = $response->json();

        return response()->json([
            'recipients' => $recipients,
            'hasMore' => count($recipients) === $pageSize,
        ]);
    }

    public function districts(): JsonResponse
    {
        $response = $this->api->districts();

        if (! $response->successful()) {
            return response()->json(['message' => $response->json('message') ?? 'Unable to load districts.'], $response->status());
        }

        return response()->json($response->json());
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phoneNumber' => ['required', 'string', 'max:30'],
            'email' => ['nullable', 'string', 'email', 'max:255'],
            'address' => ['nullable', 'string', 'max:500'],
            'ageRange' => ['nullable', 'string'],
            'gender' => ['nullable', 'string'],
            'district' => ['nullable', 'string', 'max:100'],
        ]);

        $response = $this->api->create($validated);

        if ($response->status() === 409) {
            return response()->json(['errors' => ['phoneNumber' => ['A recipient with this phone number already exists.']]], 422);
        }

        if (! $response->successful()) {
            return response()->json(['message' => $response->json('message') ?? 'Unable to add recipient.'], $response->status());
        }

        return response()->json($response->json(), 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phoneNumber' => ['required', 'string', 'max:30'],
            'email' => ['nullable', 'string', 'email', 'max:255'],
            'address' => ['nullable', 'string', 'max:500'],
            'ageRange' => ['nullable', 'string'],
            'gender' => ['nullable', 'string'],
            'district' => ['nullable', 'string', 'max:100'],
            'isActive' => ['nullable', 'boolean'],
        ]);

        if (! config('netapi.recipient_pause_enabled')) {
            unset($validated['isActive']);
        }

        $response = $this->api->update($id, $validated);

        if ($response->status() === 409) {
            return response()->json(['errors' => ['phoneNumber' => ['A recipient with this phone number already exists.']]], 422);
        }

        if (! $response->successful()) {
            return response()->json(['message' => $response->json('message') ?? 'Unable to update recipient.'], $response->status());
        }

        return response()->json($response->json());
    }

    public function destroy(string $id): JsonResponse
    {
        $response = $this->api->delete($id);

        if (! $response->successful()) {
            return response()->json(['message' => $response->json('message') ?? 'Unable to delete recipient.'], $response->status());
        }

        return response()->json(['message' => 'Recipient deleted successfully']);
    }
}
