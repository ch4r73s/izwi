import Modal from '@/Components/Modal';
import PrimaryButton from '@/Components/PrimaryButton';
import SecondaryButton from '@/Components/SecondaryButton';
import { useDebouncedSearch } from '@/hooks/useDebouncedSearch';
import { useInfiniteRecipients } from '@/hooks/useInfiniteRecipients';
import { fetchAllRecipientsByDistrict, fetchDistricts } from '@/lib/recipients';
import { Recipient } from '@/types/models';
import { useEffect, useState } from 'react';

export default function RecipientPicker({
    show,
    initiallySelected,
    onClose,
    onConfirm,
}: {
    show: boolean;
    initiallySelected: Recipient[];
    onClose: () => void;
    onConfirm: (recipients: Recipient[]) => void;
}) {
    const { term, setTerm, debounced } = useDebouncedSearch();
    const { recipients, loading, hasMore, loadMore } = useInfiniteRecipients(debounced);
    const [selected, setSelected] = useState<Map<string, Recipient>>(new Map());
    const [districts, setDistricts] = useState<string[]>([]);
    const [checkedDistricts, setCheckedDistricts] = useState<Set<string>>(new Set());
    const [selectingDistrict, setSelectingDistrict] = useState(false);

    useEffect(() => {
        if (show) {
            setSelected(new Map(initiallySelected.map((r) => [r.id, r])));
            setCheckedDistricts(new Set());
            fetchDistricts()
                .then(setDistricts)
                .catch(() => setDistricts([]));
        }
    }, [show, initiallySelected]);

    const toggle = (recipient: Recipient) => {
        setSelected((prev) => {
            const next = new Map(prev);
            if (next.has(recipient.id)) {
                next.delete(recipient.id);
            } else {
                next.set(recipient.id, recipient);
            }
            return next;
        });
    };

    const selectAllLoaded = () => {
        setSelected((prev) => {
            const next = new Map(prev);
            recipients.forEach((r) => next.set(r.id, r));
            return next;
        });
    };

    const toggleDistrictChecked = (district: string) => {
        setCheckedDistricts((prev) => {
            const next = new Set(prev);
            if (next.has(district)) {
                next.delete(district);
            } else {
                next.add(district);
            }
            return next;
        });
    };

    const addCheckedDistricts = async () => {
        if (checkedDistricts.size === 0) return;

        setSelectingDistrict(true);
        try {
            const results = await Promise.all(
                Array.from(checkedDistricts).map((d) => fetchAllRecipientsByDistrict(d)),
            );
            setSelected((prev) => {
                const next = new Map(prev);
                results.flat().forEach((r) => next.set(r.id, r));
                return next;
            });
            setCheckedDistricts(new Set());
        } finally {
            setSelectingDistrict(false);
        }
    };

    return (
        <Modal show={show} onClose={onClose} maxWidth="lg">
            <div className="flex max-h-[80vh] flex-col p-6">
                <h2 className="text-lg font-medium text-gray-900 dark:text-gray-100">Select recipients</h2>

                <input
                    type="search"
                    placeholder="Search by name, phone, or email…"
                    className="mt-4 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300"
                    value={term}
                    onChange={(e) => setTerm(e.target.value)}
                />

                {districts.length > 0 && (
                    <div className="mt-2 rounded-md border border-gray-200 p-3 dark:border-gray-700">
                        <p className="text-xs font-medium text-gray-500 dark:text-gray-400">
                            Select all in district(s)
                        </p>
                        <div className="mt-2 flex flex-wrap gap-x-4 gap-y-2">
                            {districts.map((d) => (
                                <label key={d} className="flex cursor-pointer items-center gap-1.5 text-sm">
                                    <input
                                        type="checkbox"
                                        className="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500 dark:border-gray-700"
                                        checked={checkedDistricts.has(d)}
                                        onChange={() => toggleDistrictChecked(d)}
                                    />
                                    <span className="text-gray-700 dark:text-gray-300">{d}</span>
                                </label>
                            ))}
                        </div>
                        {checkedDistricts.size > 0 && (
                            <button
                                onClick={addCheckedDistricts}
                                disabled={selectingDistrict}
                                className="mt-3 text-sm font-medium text-indigo-600 hover:underline disabled:opacity-50 dark:text-indigo-400"
                            >
                                {selectingDistrict
                                    ? 'Adding…'
                                    : `Add ${checkedDistricts.size} district${checkedDistricts.size === 1 ? '' : 's'}`}
                            </button>
                        )}
                    </div>
                )}

                <div className="mt-2 flex items-center justify-between text-sm">
                    <button onClick={selectAllLoaded} className="font-medium text-indigo-600 hover:underline dark:text-indigo-400">
                        Select all loaded ({recipients.length})
                    </button>
                    <span className="text-gray-500 dark:text-gray-400">{selected.size} selected</span>
                </div>

                <div className="mt-3 flex-1 overflow-y-auto rounded-md border border-gray-200 dark:border-gray-700">
                    <ul className="divide-y divide-gray-100 dark:divide-gray-700">
                        {recipients.map((r) => (
                            <li key={r.id}>
                                <label className="flex cursor-pointer items-center gap-3 p-3 hover:bg-gray-50 dark:hover:bg-gray-900">
                                    <input
                                        type="checkbox"
                                        className="rounded border-gray-300 text-indigo-600 shadow-sm focus:ring-indigo-500 dark:border-gray-700"
                                        checked={selected.has(r.id)}
                                        onChange={() => toggle(r)}
                                    />
                                    <div className="min-w-0">
                                        <p className="truncate text-sm font-medium text-gray-900 dark:text-gray-100">{r.name}</p>
                                        <p className="truncate text-xs text-gray-500 dark:text-gray-400">{r.phoneNumber}</p>
                                    </div>
                                </label>
                            </li>
                        ))}

                        {recipients.length === 0 && !loading && (
                            <li className="p-6 text-center text-sm text-gray-500 dark:text-gray-400">No recipients found.</li>
                        )}
                    </ul>

                    {hasMore && (
                        <div className="p-3 text-center">
                            <button
                                onClick={loadMore}
                                disabled={loading}
                                className="text-sm font-medium text-indigo-600 hover:underline disabled:opacity-50 dark:text-indigo-400"
                            >
                                {loading ? 'Loading…' : 'Load more'}
                            </button>
                        </div>
                    )}
                </div>

                <div className="mt-4 flex justify-end gap-3">
                    <SecondaryButton onClick={onClose}>Cancel</SecondaryButton>
                    <PrimaryButton onClick={() => onConfirm(Array.from(selected.values()))}>
                        Confirm ({selected.size})
                    </PrimaryButton>
                </div>
            </div>
        </Modal>
    );
}
