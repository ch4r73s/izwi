function getXsrfToken(): string {
    const match = document.cookie.match(/(?:^|; )XSRF-TOKEN=([^;]*)/);
    return match ? decodeURIComponent(match[1]) : '';
}

export class ApiError extends Error {
    status: number;
    errors?: Record<string, string[]>;

    constructor(status: number, data: { message?: string; errors?: Record<string, string[]> }) {
        super(data.message ?? `Request failed with status ${status}`);
        this.status = status;
        this.errors = data.errors;
    }
}

export async function apiFetch<T>(url: string, options: RequestInit = {}): Promise<T> {
    const method = (options.method ?? 'GET').toUpperCase();
    const headers: Record<string, string> = {
        Accept: 'application/json',
        ...(options.headers as Record<string, string> | undefined),
    };

    if (method !== 'GET') {
        headers['X-XSRF-TOKEN'] = getXsrfToken();
        if (options.body && !(options.body instanceof FormData)) {
            headers['Content-Type'] = 'application/json';
        }
    }

    const response = await fetch(url, { ...options, method, headers, credentials: 'same-origin' });

    if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new ApiError(response.status, data);
    }

    if (response.status === 204) {
        return undefined as T;
    }

    return response.json();
}
