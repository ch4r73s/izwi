import NotificationGroup from '@/Components/notifications/NotificationGroup';
import AppLayout from '@/Layouts/AppLayout';
import { PageProps } from '@/types';
import { NotificationRecord } from '@/types/models';
import { Head } from '@inertiajs/react';
import { useMemo, useState } from 'react';

const GROUPS_PER_PAGE = 3;

function monthLabel(dateIso: string): string {
    return new Date(dateIso).toLocaleDateString(undefined, { month: 'long', year: 'numeric' });
}

export default function NotificationsIndex({ notifications }: PageProps<{ notifications: NotificationRecord[] }>) {
    const [visibleGroups, setVisibleGroups] = useState(GROUPS_PER_PAGE);

    const groups = useMemo(() => {
        const sorted = [...notifications].sort(
            (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
        );

        const byMonth = new Map<string, NotificationRecord[]>();
        for (const n of sorted) {
            const label = monthLabel(n.createdAt);
            if (!byMonth.has(label)) byMonth.set(label, []);
            byMonth.get(label)!.push(n);
        }

        return Array.from(byMonth.entries());
    }, [notifications]);

    return (
        <AppLayout header={<h2 className="text-xl font-semibold text-gray-800 dark:text-gray-200">Sent History</h2>}>
            <Head title="Sent History" />

            <div className="py-8">
                <div className="mx-auto max-w-3xl space-y-6 px-4 sm:px-6 lg:px-8">
                    {groups.length === 0 && (
                        <p className="text-sm text-gray-500 dark:text-gray-400">Nothing sent yet.</p>
                    )}

                    {groups.slice(0, visibleGroups).map(([label, items]) => (
                        <NotificationGroup key={label} label={label} notifications={items} />
                    ))}

                    {visibleGroups < groups.length && (
                        <div className="flex justify-center">
                            <button
                                onClick={() => setVisibleGroups((v) => v + GROUPS_PER_PAGE)}
                                className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
                            >
                                Show more months
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </AppLayout>
    );
}
