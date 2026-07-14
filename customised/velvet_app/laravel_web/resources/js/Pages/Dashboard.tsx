import AppLayout from '@/Layouts/AppLayout';
import { PageProps } from '@/types';
import { ClientSummary } from '@/types/models';
import { Head, Link, usePage } from '@inertiajs/react';

function Tile({
    title,
    description,
    href,
    disabled,
}: {
    title: string;
    description: string;
    href?: string;
    disabled?: boolean;
}) {
    const classes =
        'block rounded-lg bg-white p-6 shadow transition hover:shadow-md dark:bg-gray-800' +
        (disabled ? ' opacity-50 cursor-not-allowed' : '');

    const content = (
        <>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">{title}</h3>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{description}</p>
        </>
    );

    if (disabled || !href) {
        return <div className={classes}>{content}</div>;
    }

    return (
        <Link href={href} className={classes}>
            {content}
        </Link>
    );
}

export default function Dashboard({ client }: PageProps<{ client: ClientSummary | null }>) {
    const { auth } = usePage<PageProps>().props;
    const isAdmin = auth.user?.role === 'Admin';

    return (
        <AppLayout header={<h2 className="text-xl font-semibold text-gray-800 dark:text-gray-200">Dashboard</h2>}>
            <Head title="Dashboard" />

            <div className="py-8">
                <div className="mx-auto max-w-5xl space-y-6 px-4 sm:px-6 lg:px-8">
                    {client && (
                        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
                            <div className="rounded-lg bg-white p-4 shadow dark:bg-gray-800">
                                <p className="text-xs text-gray-500 dark:text-gray-400">SMS remaining</p>
                                <p className="text-2xl font-semibold text-gray-900 dark:text-gray-100">
                                    {client.subscription.totalRemaining}
                                </p>
                            </div>
                            <div className="rounded-lg bg-white p-4 shadow dark:bg-gray-800">
                                <p className="text-xs text-gray-500 dark:text-gray-400">SMS used</p>
                                <p className="text-2xl font-semibold text-gray-900 dark:text-gray-100">
                                    {client.subscription.totalConsumed}
                                </p>
                            </div>
                            <div className="rounded-lg bg-white p-4 shadow dark:bg-gray-800">
                                <p className="text-xs text-gray-500 dark:text-gray-400">Plan</p>
                                <p className="truncate text-2xl font-semibold text-gray-900 dark:text-gray-100">
                                    {client.subscription.currentPackage?.name ?? '—'}
                                </p>
                            </div>
                            <div className="rounded-lg bg-white p-4 shadow dark:bg-gray-800">
                                <p className="text-xs text-gray-500 dark:text-gray-400">Mode</p>
                                <p className="text-2xl font-semibold text-gray-900 dark:text-gray-100">{auth.user?.role}</p>
                            </div>
                        </div>
                    )}

                    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <Tile
                            title="Compose & Send"
                            description="Write a message and send it to one or more recipients."
                            href={route('sms.create')}
                        />
                        <Tile
                            title="Recipients"
                            description="Manage your contact list — add, edit, search, and pause recipients."
                            href={route('recipients.index')}
                        />
                        <Tile
                            title="Sent History"
                            description="See what's been sent and each recipient's delivery status."
                            href={route('notifications.index')}
                        />
                        {isAdmin && (
                            <Tile
                                title="Client Management"
                                description="Coming in Phase 2 — create and manage client accounts from the web."
                                disabled
                            />
                        )}
                    </div>
                </div>
            </div>
        </AppLayout>
    );
}
