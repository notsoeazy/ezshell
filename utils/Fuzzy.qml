pragma Singleton

import Quickshell

// Search ranking for the launcher. Higher is better; 0 means no match.
Singleton {
    // How well `text` matches `query`: the start of the text beats the start
    // of a word, which beats anywhere inside, which beats the letters merely
    // appearing in order.
    function score(query: string, text: string): real {
        const q = query.trim().toLowerCase();
        const t = text.toLowerCase();
        if (q.length === 0)
            return 1;
        if (t.length === 0)
            return 0;

        const at = t.indexOf(q);
        if (at === 0)
            return 100 - Math.min(20, t.length - q.length);
        if (at > 0)
            return (/[\s\-_.]/.test(t[at - 1]) ? 80 : 60) - Math.min(20, at);

        // Letters in order, anywhere.
        let position = 0;
        for (const letter of q) {
            position = t.indexOf(letter, position);
            if (position < 0)
                return 0;
            position++;
        }
        return 20;
    }

    // The best score across several texts, each with a weight (0..1).
    function best(query: string, texts: list<string>, weights: list<real>): real {
        let top = 0;
        for (let i = 0; i < texts.length; i++)
            top = Math.max(top, score(query, texts[i]) * (weights[i] ?? 1));
        return top;
    }
}
