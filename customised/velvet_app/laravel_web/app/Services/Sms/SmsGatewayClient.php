<?php

namespace App\Services\Sms;

use App\Exceptions\UnsupportedGatewayException;

class SmsGatewayClient
{
    public function __construct(private readonly TumiraiGateway $tumirai)
    {
    }

    /**
     * @param  array{provider:string,smsEndpoint:string,smsUsername:?string,smsPassword:?string,apiKey:?string,senderId:?string}  $credentials
     * @param  array<string,string>  $messages  phone => resolved text
     */
    public function send(array $credentials, array $messages): array
    {
        $provider = strtolower(trim($credentials['provider'] ?? ''));

        if ($provider !== 'tumirai') {
            throw new UnsupportedGatewayException(
                "Only the Tumirai SMS gateway is supported. Configured provider: \"{$credentials['provider']}\"."
            );
        }

        return $this->tumirai->sendBatch(
            $credentials['smsEndpoint'],
            $credentials['apiKey'] ?? '',
            $credentials['senderId'] ?? '',
            $messages,
        );
    }
}
