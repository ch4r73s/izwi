import { resolveTemplate, smsUnits } from '@/lib/templateResolver';
import { Recipient } from '@/types/models';
import { useMemo } from 'react';

export default function SmsCounter({ message, recipients }: { message: string; recipients: Recipient[] }) {
    const { totalUnits, maxLength } = useMemo(() => {
        if (recipients.length === 0) {
            const len = message.length;
            return { totalUnits: smsUnits(message), maxLength: len };
        }

        let total = 0;
        let max = 0;

        for (const r of recipients) {
            const resolved = resolveTemplate(message, r.name, r.gender);
            total += smsUnits(resolved);
            max = Math.max(max, resolved.length);
        }

        return { totalUnits: total, maxLength: max };
    }, [message, recipients]);

    return (
        <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
            {maxLength} characters (longest resolved message) · {totalUnits} SMS unit{totalUnits === 1 ? '' : 's'} total across{' '}
            {recipients.length || 0} recipient{recipients.length === 1 ? '' : 's'}
        </p>
    );
}
