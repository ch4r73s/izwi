import { apiFetch } from '@/lib/apiFetch';
import { Recipient } from '@/types/models';

export function fetchDistricts(): Promise<string[]> {
    return apiFetch<string[]>(route('recipients.districts'));
}

/**
 * Pages through every recipient in `district` via the server-side filter
 * (not just what's currently loaded in the UI) — used for the one-click
 * "select all in district" action.
 */
export async function fetchAllRecipientsByDistrict(district: string): Promise<Recipient[]> {
    const pageSize = 100;
    let page = 1;
    const all: Recipient[] = [];

    while (true) {
        const params = new URLSearchParams({ page: String(page), pageSize: String(pageSize), district });
        const data = await apiFetch<{ recipients: Recipient[]; hasMore: boolean }>(
            route('recipients.search') + '?' + params.toString(),
        );

        all.push(...data.recipients);

        if (!data.hasMore) break;
        page++;
    }

    return all;
}
