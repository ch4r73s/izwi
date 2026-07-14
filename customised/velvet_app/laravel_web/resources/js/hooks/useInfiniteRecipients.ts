import { apiFetch } from '@/lib/apiFetch';
import { Recipient } from '@/types/models';
import { useCallback, useEffect, useRef, useState } from 'react';

const PAGE_SIZE = 20;

/**
 * GET /api/recipients/my has no total-count/pagination envelope — "has
 * more" is inferred from whether a page came back full-size.
 */
export function useInfiniteRecipients(search: string) {
    const [recipients, setRecipients] = useState<Recipient[]>([]);
    const [page, setPage] = useState(1);
    const [hasMore, setHasMore] = useState(true);
    const [loading, setLoading] = useState(false);
    const requestId = useRef(0);

    const fetchPage = useCallback(async (pageToLoad: number, searchTerm: string, append: boolean) => {
        const thisRequest = ++requestId.current;
        setLoading(true);

        try {
            const params = new URLSearchParams({ page: String(pageToLoad), pageSize: String(PAGE_SIZE) });
            if (searchTerm) params.set('search', searchTerm);

            const data = await apiFetch<{ recipients: Recipient[]; hasMore: boolean }>(
                route('recipients.search') + '?' + params.toString(),
            );

            if (thisRequest !== requestId.current) return; // stale response, ignore

            setRecipients((prev) => (append ? [...prev, ...data.recipients] : data.recipients));
            setHasMore(data.hasMore);
            setPage(pageToLoad);
        } finally {
            if (thisRequest === requestId.current) setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchPage(1, search, false);
    }, [search, fetchPage]);

    const loadMore = useCallback(() => {
        if (!loading && hasMore) fetchPage(page + 1, search, true);
    }, [loading, hasMore, page, search, fetchPage]);

    const refresh = useCallback(() => fetchPage(1, search, false), [fetchPage, search]);

    const updateOne = useCallback((updated: Recipient) => {
        setRecipients((prev) => prev.map((r) => (r.id === updated.id ? updated : r)));
    }, []);

    const removeOne = useCallback((id: string) => {
        setRecipients((prev) => prev.filter((r) => r.id !== id));
    }, []);

    return { recipients, loading, hasMore, loadMore, refresh, updateOne, removeOne };
}
