import RecipientFormModal from '@/Components/recipients/RecipientFormModal';
import { ApiError, apiFetch } from '@/lib/apiFetch';
import AppLayout from '@/Layouts/AppLayout';
import { useDebouncedSearch } from '@/hooks/useDebouncedSearch';
import { useInfiniteRecipients } from '@/hooks/useInfiniteRecipients';
import { PageProps } from '@/types';
import { Recipient } from '@/types/models';
import { Head } from '@inertiajs/react';
import { useState } from 'react';

export default function RecipientsIndex({ pauseEnabled }: PageProps<{ pauseEnabled: boolean }>) {
    const { term, setTerm, debounced } = useDebouncedSearch();
    const { recipients, loading, hasMore, loadMore, refresh, updateOne, removeOne } = useInfiniteRecipients(debounced);

    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState<Recipient | null>(null);
    const [busyId, setBusyId] = useState<string | null>(null);

    const openAdd = () => {
        setEditing(null);
        setModalOpen(true);
    };

    const openEdit = (recipient: Recipient) => {
        setEditing(recipient);
        setModalOpen(true);
    };

    const handleSaved = (recipient: Recipient) => {
        if (editing) {
            updateOne(recipient);
        } else {
            refresh();
        }
    };

    const togglePause = async (recipient: Recipient) => {
        setBusyId(recipient.id);
        try {
            const updated = await apiFetch<Recipient>(route('recipients.update', recipient.id), {
                method: 'PUT',
                body: JSON.stringify({
                    name: recipient.name,
                    phoneNumber: recipient.phoneNumber,
                    email: recipient.email,
                    address: recipient.address,
                    ageRange: recipient.ageRange,
                    gender: recipient.gender,
                    district: recipient.district,
                    isActive: !recipient.isActive,
                }),
            });
            // Paused recipients are filtered out server-side (IsActive=false),
            // so they simply disappear from the list rather than showing a badge.
            if (!updated.isActive) {
                removeOne(recipient.id);
            } else {
                updateOne(updated);
            }
        } catch (err) {
            alert(err instanceof ApiError ? err.message : 'Unable to update recipient.');
        } finally {
            setBusyId(null);
        }
    };

    const remove = async (recipient: Recipient) => {
        if (!confirm(`Delete ${recipient.name}? This can't be undone.`)) return;

        setBusyId(recipient.id);
        try {
            await apiFetch(route('recipients.destroy', recipient.id), { method: 'DELETE' });
            removeOne(recipient.id);
        } catch (err) {
            alert(err instanceof ApiError ? err.message : 'Unable to delete recipient.');
        } finally {
            setBusyId(null);
        }
    };

    return (
        <AppLayout header={<h2 className="text-xl font-semibold text-gray-800 dark:text-gray-200">Recipients</h2>}>
            <Head title="Recipients" />

            <div className="py-8">
                <div className="mx-auto max-w-4xl space-y-4 px-4 sm:px-6 lg:px-8">
                    <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                        <input
                            type="search"
                            placeholder="Search by name, phone, or email…"
                            className="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:max-w-sm dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300"
                            value={term}
                            onChange={(e) => setTerm(e.target.value)}
                        />
                        <button
                            onClick={openAdd}
                            className="inline-flex shrink-0 items-center justify-center rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
                        >
                            + Add recipient
                        </button>
                    </div>

                    <div className="overflow-hidden rounded-lg bg-white shadow dark:bg-gray-800">
                        <ul className="divide-y divide-gray-100 dark:divide-gray-700">
                            {recipients.map((r) => (
                                <li key={r.id} className="flex items-center justify-between gap-4 p-4">
                                    <div className="min-w-0">
                                        <p className="flex items-center gap-2 truncate font-medium text-gray-900 dark:text-gray-100">
                                            {r.name}
                                            {r.district && (
                                                <span className="inline-flex shrink-0 rounded-full bg-gray-100 px-2 py-0.5 text-xs font-normal text-gray-600 dark:bg-gray-700 dark:text-gray-300">
                                                    {r.district}
                                                </span>
                                            )}
                                        </p>
                                        <p className="truncate text-sm text-gray-500 dark:text-gray-400">
                                            {r.phoneNumber}
                                            {r.email ? ` · ${r.email}` : ''}
                                        </p>
                                    </div>
                                    <div className="flex shrink-0 items-center gap-2">
                                        <button
                                            onClick={() => openEdit(r)}
                                            disabled={busyId === r.id}
                                            className="rounded-md px-2 py-1 text-sm font-medium text-indigo-600 hover:bg-indigo-50 disabled:opacity-50 dark:text-indigo-400 dark:hover:bg-indigo-950"
                                        >
                                            Edit
                                        </button>
                                        {pauseEnabled && (
                                            <button
                                                onClick={() => togglePause(r)}
                                                disabled={busyId === r.id}
                                                className="rounded-md px-2 py-1 text-sm font-medium text-amber-600 hover:bg-amber-50 disabled:opacity-50 dark:text-amber-400 dark:hover:bg-amber-950"
                                            >
                                                Pause
                                            </button>
                                        )}
                                        <button
                                            onClick={() => remove(r)}
                                            disabled={busyId === r.id}
                                            className="rounded-md px-2 py-1 text-sm font-medium text-red-600 hover:bg-red-50 disabled:opacity-50 dark:text-red-400 dark:hover:bg-red-950"
                                        >
                                            Delete
                                        </button>
                                    </div>
                                </li>
                            ))}

                            {recipients.length === 0 && !loading && (
                                <li className="p-8 text-center text-sm text-gray-500 dark:text-gray-400">
                                    No recipients found.
                                </li>
                            )}
                        </ul>
                    </div>

                    {hasMore && (
                        <div className="flex justify-center">
                            <button
                                onClick={loadMore}
                                disabled={loading}
                                className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 disabled:opacity-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
                            >
                                {loading ? 'Loading…' : 'Load more'}
                            </button>
                        </div>
                    )}
                </div>
            </div>

            <RecipientFormModal show={modalOpen} recipient={editing} onClose={() => setModalOpen(false)} onSaved={handleSaved} />
        </AppLayout>
    );
}
