<?php

namespace App\Services\Sms;

class SendSmsResult
{
    /**
     * @param  array<int,array{name:?string,phoneNumber:string,success:bool,reason:?string}>  $recipients
     */
    public function __construct(
        public readonly int $sentCount,
        public readonly int $failedCount,
        public readonly ?string $notificationId,
        public readonly array $recipients,
    ) {
    }
}
