<?php

namespace App\Services\NetApi;

use Illuminate\Http\Client\Response;

class NotificationsApi
{
    public function __construct(private readonly NetApiClient $client)
    {
    }

    public function sent(): Response
    {
        return $this->client->get('/api/notifications/sent');
    }

    /**
     * The only endpoint that actually creates NotificationRecipient child
     * rows (needed for later delivery-status PATCH matching by phone
     * number) — send-to-recipients does not, and never calls a gateway.
     */
    public function create(array $data): Response
    {
        return $this->client->post('/api/notifications', $data);
    }

    public function updateDelivery(string $id, array $data): Response
    {
        return $this->client->patch("/api/notifications/{$id}/delivery", $data);
    }
}
