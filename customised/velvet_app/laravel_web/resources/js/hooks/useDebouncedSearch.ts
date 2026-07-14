import { useEffect, useState } from 'react';

export function useDebouncedSearch(delayMs = 400) {
    const [term, setTerm] = useState('');
    const [debounced, setDebounced] = useState('');

    useEffect(() => {
        const timer = setTimeout(() => setDebounced(term), delayMs);
        return () => clearTimeout(timer);
    }, [term, delayMs]);

    return { term, setTerm, debounced };
}
