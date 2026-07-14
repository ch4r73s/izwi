<?php

namespace App\Services\Sms;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\Pool;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * Direct port of _sendViaTumirai in
 * flutter_app/lib/services/common/send_bulk_sms.dart, run server-side.
 * EBS (the legacy gateway) is intentionally not implemented — it's being
 * phased out.
 */
class TumiraiGateway
{
    private const BATCH_SIZE = 10;

    /**
     * @param  array<string,string>  $messages  phone => resolved text
     * @return array<string,array{success:bool,reason:?string,gatewayId:?string,gatewayPayload:?string}>
     */
    public function sendBatch(string $endpoint, string $apiKey, string $senderId, array $messages): array
    {
        $results = [];

        foreach (array_chunk($messages, self::BATCH_SIZE, preserve_keys: true) as $batch) {
            $responses = Http::pool(function (Pool $pool) use ($batch, $endpoint, $apiKey, $senderId) {
                $requests = [];

                foreach ($batch as $phone => $text) {
                    $requests[] = $pool->as($phone)
                        ->withHeaders([
                            'Authorization' => "Bearer {$apiKey}",
                            'Idempotency-Key' => str_replace('+', '', $phone) . '-' . (int) round(microtime(true) * 1000),
                        ])
                        ->acceptJson()
                        ->post($endpoint, [
                            'to' => $phone,
                            'sender_id' => $senderId,
                            'text' => $text,
                        ]);
                }

                return $requests;
            });

            foreach ($batch as $phone => $text) {
                $results[$phone] = $this->parseResult($responses[$phone] ?? null);
            }
        }

        return $results;
    }

    private function parseResult(Response|ConnectionException|Throwable|null $response): array
    {
        if ($response === null) {
            return ['success' => false, 'reason' => 'No response from gateway', 'gatewayId' => null, 'gatewayPayload' => null];
        }

        if ($response instanceof Throwable) {
            return ['success' => false, 'reason' => $response->getMessage(), 'gatewayId' => null, 'gatewayPayload' => null];
        }

        if (! $response->successful()) {
            return ['success' => false, 'reason' => $response->body(), 'gatewayId' => null, 'gatewayPayload' => null];
        }

        $decoded = $response->json();
        $gatewayId = null;
        $gatewayPayload = null;

        if (is_array($decoded)) {
            $data = $decoded['data'] ?? null;

            if (is_array($data)) {
                $gatewayId = $data['id'] ?? null;
                $gatewayPayload = json_encode($data);
            } else {
                $gatewayId = $decoded['id'] ?? $decoded['message_id'] ?? $decoded['messageId'] ?? null;
            }
        }

        return ['success' => true, 'reason' => null, 'gatewayId' => $gatewayId, 'gatewayPayload' => $gatewayPayload];
    }
}
