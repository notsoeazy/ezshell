pragma Singleton

import Quickshell

// Pure matching helpers for search. Higher score = better; -1 = no match.
Singleton {
    // Lowercase without accents, so "cafe" finds "café".
    function fold(text: string): string {
        return text.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
    }

    function score(query: string, text: string): real {
        const q = query.toLowerCase();
        const t = text.toLowerCase();
        if (q === "" || t === "")
            return -1;
        if (t.startsWith(q))
            return 4;
        const index = t.indexOf(q);
        if (index > 0)
            return " -_.".includes(t[index - 1]) ? 3 : 2;
        // Characters in order, gaps allowed ("ffx" matches "firefox").
        let matched = 0;
        for (const c of t) {
            if (c === q[matched])
                matched++;
        }
        return matched === q.length ? 1 : -1;
    }
}
