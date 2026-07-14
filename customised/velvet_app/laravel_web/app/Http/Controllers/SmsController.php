<?php

namespace App\Http\Controllers;

use App\Http\Requests\SendSmsRequest;
use App\Services\Sms\SendSmsOrchestrator;
use Illuminate\Http\RedirectResponse;
use Inertia\Inertia;
use Inertia\Response;

class SmsController extends Controller
{
    public function __construct(private readonly SendSmsOrchestrator $orchestrator)
    {
    }

    public function create(): Response
    {
        return Inertia::render('Compose/Send');
    }

    public function store(SendSmsRequest $request): RedirectResponse
    {
        // Bulk sends fan out to the gateway in batches of 10 concurrent
        // requests — give this one route more headroom than the default
        // PHP execution limit before it's considered synchronous-too-long.
        set_time_limit(120);

        $validated = $request->validated();

        try {
            $result = $this->orchestrator->send($validated['title'], $validated['message'], $validated['recipients']);
        } catch (\Throwable $e) {
            return back()->withErrors(['message' => $e->getMessage()])->withInput();
        }

        return redirect()->route('notifications.index')->with('flash', [
            'success' => "Sent {$result->sentCount} message(s)" . ($result->failedCount > 0 ? ", {$result->failedCount} failed." : '.'),
        ]);
    }
}
