import RecipientDeliveryBadge from '@/Components/notifications/RecipientDeliveryBadge';
import { NotificationRecord } from '@/types/models';
import { useState } from 'react';

const STATUS_STYLES: Record<string, string> = {
    Sent: 'bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-300',
    Partial: 'bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-300',
    Failed: 'bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-300',
    Pending: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300',
};

function NotificationRow({ notification }: { notification: NotificationRecord }) {
    const [expanded, setExpanded] = useState(false);
    const sentCount = notification.recipients.filter((r) => r.status === 'Sent' || r.status === 'Delivered').length;
    const failedCount = notification.recipients.filter((r) => r.status === 'Failed').length;

    return (
        <li className="p-4">
            <button className="flex w-full items-start justify-between gap-4 text-left" onClick={() => setExpanded((v) => !v)}>
                <div className="min-w-0">
                    <p className="truncate font-medium text-gray-900 dark:text-gray-100">{notification.title || '(no title)'}</p>
                    <p className="truncate text-sm text-gray-500 dark:text-gray-400">{notification.message}</p>
                    <p className="mt-1 text-xs text-gray-400 dark:text-gray-500">
                        {new Date(notification.createdAt).toLocaleString()} · Sent {sentCount}
                        {failedCount > 0 ? `, Failed ${failedCount}` : ''}
                    </p>
                </div>
                <span
                    className={`inline-flex shrink-0 rounded-full px-2 py-0.5 text-xs font-medium ${
                        STATUS_STYLES[notification.deliveryStatus] ?? STATUS_STYLES.Pending
                    }`}
                >
                    {notification.deliveryStatus}
                </span>
            </button>

            {expanded && notification.recipients.length > 0 && (
                <ul className="mt-3 space-y-1 border-t border-gray-100 pt-3 dark:border-gray-700">
                    {notification.recipients.map((r) => (
                        <li key={r.id} className="flex items-center justify-between text-sm">
                            <span className="text-gray-700 dark:text-gray-300">
                                {r.name ?? r.phoneNumber} <span className="text-gray-400">({r.phoneNumber})</span>
                            </span>
                            <RecipientDeliveryBadge status={r.status} />
                        </li>
                    ))}
                </ul>
            )}
        </li>
    );
}

export default function NotificationGroup({ label, notifications }: { label: string; notifications: NotificationRecord[] }) {
    return (
        <div>
            <h3 className="mb-2 text-sm font-semibold text-gray-500 dark:text-gray-400">{label}</h3>
            <ul className="divide-y divide-gray-100 overflow-hidden rounded-lg bg-white shadow dark:divide-gray-700 dark:bg-gray-800">
                {notifications.map((n) => (
                    <NotificationRow key={n.id} notification={n} />
                ))}
            </ul>
        </div>
    );
}
