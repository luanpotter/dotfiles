.pragma library

// Launcher matching, shared by its modules. Items have name plus lowercase
// nameLc/kwLc (built once), so a keystroke only compares strings.

// name vs lowercase query; lower is better, -1 = no match:
// exact, prefix, word start, substring, then fuzzy (chars in order)
function nameScore(n, q) {
    if (n === q)
        return 0;
    const i = n.indexOf(q);
    if (i === 0)
        return 1;
    if (i > 0)
        return /[\s\-_.]/.test(n[i - 1]) ? 2 : 3;
    let j = 0;
    for (let k = 0; k < n.length && j < q.length; k++)
        if (n[k] === q[j])
            j++;
    return j === q.length ? 4 : -1;
}

// keywords only match as substrings (fuzzy over long keyword lists is slow
// and noisy), and rank below name matches
function itemScore(item, q) {
    const s = nameScore(item.nameLc, q);
    if (s >= 0 && s < 4 || !item.kwLc)
        return s;
    const i = item.kwLc.indexOf(q);
    if (i < 0)
        return s;
    const k = i === 0 || /[\s|]/.test(item.kwLc[i - 1]) ? 4 : 5;
    return s < 0 ? k : Math.min(s, k);
}

// cache: an object the caller keeps per source, holding the last query and
// its matches. A longer query can only match a subset of what its prefix
// matched, so typing narrows instead of rescanning everything.
// raw (optional): a name equal to it, case included, wins ties.
function ranked(cache, items, q, raw) {
    const last = cache.last;
    const pool = last && last.items === items && last.q && q.startsWith(last.q) ? last.matched : items;
    const hits = [];
    for (const item of pool) {
        const s = itemScore(item, q);
        if (s >= 0)
            hits.push({ item, s });
    }
    cache.last = { items, q, matched: hits.map(h => h.item) };
    hits.sort((a, b) => a.s - b.s
        || (b.item.name === raw) - (a.item.name === raw)
        || a.item.name.length - b.item.name.length);
    return hits;
}
