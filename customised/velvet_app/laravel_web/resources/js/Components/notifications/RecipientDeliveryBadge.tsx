import { RecipientDeliveryStatus } from '@/types/models';

const STYLES: Record<RecipientDeliveryStatus, string> = {
    Sent: 'bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-300',
    Delivered: 'bg-teal-50 text-teal-700 dark:bg-teal-950 dark:text-teal-300',
    Failed: 'bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-300',
    Pending: 'bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-300',
};

export default function RecipientDeliveryBadge({ status }: { status: RecipientDeliveryStatus }) {
    return (
        <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${STYLES[status] ?? STYLES.Pending}`}>
            {status}
        </span>
    );
}
