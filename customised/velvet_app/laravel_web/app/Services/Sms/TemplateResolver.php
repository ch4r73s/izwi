<?php

namespace App\Services\Sms;

/**
 * Direct port of flutter_app/lib/services/common/template_resolver.dart —
 * intentionally NOT the same as dotnet_api's SmsBillingHelper::resolveTemplate
 * (different tokens, no gender prefix). This must match the mobile app's
 * behavior exactly so billing units stay consistent regardless of which
 * client sent the message.
 */
class TemplateResolver
{
    public static function resolve(string $template, string $name, ?string $gender): string
    {
        return preg_replace('/\{name\}|\[name\]/i', self::resolvedName($name, $gender), $template);
    }

    private static function resolvedName(string $name, ?string $gender): string
    {
        $g = strtolower(trim($gender ?? ''));

        if (str_starts_with($g, 'm')) {
            return "madzibaba {$name}";
        }

        if (str_starts_with($g, 'f')) {
            return "madzimai {$name}";
        }

        return $name;
    }

    /**
     * Matches the billing rule confirmed against the Tumirai gateway's own
     * documentation: a flat ceil(length / 160) per message part.
     */
    public static function smsUnits(string $resolvedMessage): int
    {
        return (int) ceil(mb_strlen($resolvedMessage) / 160);
    }
}
