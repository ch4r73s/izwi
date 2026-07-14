import { resolveTemplate } from '@/lib/templateResolver';
import { Recipient } from '@/types/models';
import { useMemo } from 'react';

export default function TemplatePreview({ message, recipients }: { message: string; recipients: Recipient[] }) {
    const examples = useMemo(() => {
        if (!message) return [];

        const male = recipients.find((r) => (r.gender ?? '').toLowerCase().startsWith('m'));
        const female = recipients.find((r) => (r.gender ?? '').toLowerCase().startsWith('f'));
        const fallback = recipients[0];

        const picks = [male, female, !male && !female ? fallback : undefined].filter(
            (r, i, arr): r is Recipient => !!r && arr.findIndex((x) => x?.id === r.id) === i,
        );

        return picks.slice(0, 2).map((r) => ({ recipient: r, text: resolveTemplate(message, r.name, r.gender) }));
    }, [message, recipients]);

    if (examples.length === 0) return null;

    return (
        <div className="mt-3 space-y-2 rounded-md bg-gray-50 p-3 dark:bg-gray-900">
            <p className="text-xs font-medium text-gray-500 dark:text-gray-400">Preview</p>
            {examples.map(({ recipient, text }) => (
                <p key={recipient.id} className="text-sm text-gray-700 dark:text-gray-300">
                    <span className="font-medium">{recipient.name}:</span> {text}
                </p>
            ))}
        </div>
    );
}
