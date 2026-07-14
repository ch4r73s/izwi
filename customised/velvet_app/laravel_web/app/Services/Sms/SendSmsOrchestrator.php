<?php

namespace App\Services\Sms;

use App\Services\NetApi\ClientsApi;
use App\Services\NetApi\GatewayApi;
use App\Services\NetApi\NotificationsApi;
use RuntimeException;

/**
 * Server-side port of the 6-step flow in
 * flutter_app/lib/screens/create_notification.dart + send_bulk_sms.dart:
 * resolve templates -> pre-save Pending notification -> send via gateway
 * -> report delivery status back -> record billing units. Runs
 * synchronously in the request cycle (no queue infra given the app has
 * no database).
 */
class SendSmsOrchestrator
{
    public function __construct(
        private readonly GatewayApi $gatewayApi,
        private readonly NotificationsApi $notificationsApi,
        private readonly ClientsApi $clientsApi,
        private readonly SmsGatewayClient $gateway,
    ) {
    }

    /**
     * @param  array<int,array{name:string,phoneNumber:string,gender:?string}>  $recipients
     */
    public function send(string $title, string $template, array $recipients): SendSmsResult
    {
        $credentialsResponse = $this->gatewayApi->credentials();

        if (! $credentialsResponse->successful()) {
            $message = $credentialsResponse->json('message') ?? 'Unable to load SMS gateway credentials.';
            throw new RuntimeException($message);
        }

        $credentials = $credentialsResponse->json();

        // Step 1: resolve per-recipient message.
        $resolved = [];
        foreach ($recipients as $r) {
            $resolved[$r['phoneNumber']] = TemplateResolver::resolve($template, $r['name'], $r['gender'] ?? null);
        }

        // Step 2: pre-send save (best-effort — mirrors the mobile app's
        // "continue even if this fails" behavior, falling back to a full
        // POST after sending if no notificationId was captured).
        $notificationId = null;

        try {
            $preSend = $this->notificationsApi->create([
                'title' => $title,
                'message' => $template,
                'type' => 'Sms',
                'deliveryStatus' => 'Pending',
                'recipients' => array_map(
                    fn ($r) => ['name' => $r['name'], 'phoneNumber' => $r['phoneNumber'], 'status' => 'Pending'],
                    $recipients,
                ),
            ]);

            if ($preSend->successful()) {
                $notificationId = $preSend->json('id');
            }
        } catch (\Throwable) {
            // Fall through — handled below via the no-notificationId branch.
        }

        // Step 3: send via gateway.
        $gatewayResults = $this->gateway->send($credentials, $resolved);

        // Step 4: derive per-recipient + overall status.
        $sentCount = 0;
        $failedCount = 0;
        $recipientOutcomes = [];
        $failedReasons = [];

        foreach ($recipients as $r) {
            $phone = $r['phoneNumber'];
            $result = $gatewayResults[$phone] ?? ['success' => false, 'reason' => 'Not sent', 'gatewayId' => null, 'gatewayPayload' => null];

            if ($result['success']) {
                $sentCount++;
            } else {
                $failedCount++;
                $failedReasons[] = "{$phone}: {$result['reason']}";
            }

            $recipientOutcomes[] = [
                'name' => $r['name'],
                'phoneNumber' => $phone,
                'success' => $result['success'],
                'reason' => $result['reason'],
                'gatewayId' => $result['gatewayId'],
                'gatewayPayload' => $result['gatewayPayload'],
            ];
        }

        $deliveryStatus = $failedCount === 0 ? 'Sent' : ($sentCount === 0 ? 'Failed' : 'Partial');
        $errorDetails = $failedReasons === [] ? null : implode(' | ', $failedReasons);

        $recipientPayload = array_map(function ($o) {
            $entry = [
                'name' => $o['name'],
                'phoneNumber' => $o['phoneNumber'],
                'status' => $o['success'] ? 'Sent' : 'Failed',
            ];

            if (! $o['success']) {
                $entry['errorReason'] = $o['reason'];
            } else {
                if ($o['gatewayId']) {
                    $entry['gatewayMessageId'] = $o['gatewayId'];
                }
                if ($o['gatewayPayload']) {
                    $entry['gatewayPayload'] = $o['gatewayPayload'];
                }
            }

            return $entry;
        }, $recipientOutcomes);

        // Step 5: report delivery status back.
        if ($notificationId !== null) {
            $this->notificationsApi->updateDelivery($notificationId, [
                'deliveryStatus' => $deliveryStatus,
                'errorDetails' => $errorDetails,
                'recipients' => $recipientPayload,
            ]);
        } else {
            $fallback = $this->notificationsApi->create([
                'title' => $title,
                'message' => $template,
                'type' => 'Sms',
                'deliveryStatus' => $deliveryStatus,
                'errorDetails' => $errorDetails,
                'recipients' => $recipientPayload,
            ]);

            if ($fallback->successful()) {
                $notificationId = $fallback->json('id');
            }
        }

        // Step 6: record billing — successfully-sent recipients only.
        $units = 0;
        foreach ($recipientOutcomes as $o) {
            if ($o['success']) {
                $units += TemplateResolver::smsUnits($resolved[$o['phoneNumber']]);
            }
        }

        if ($units > 0) {
            $this->clientsApi->recordSms($units);
        }

        return new SendSmsResult($sentCount, $failedCount, $notificationId, $recipientOutcomes);
    }
}
