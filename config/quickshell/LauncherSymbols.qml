import QtQuick
import Quickshell
import Quickshell.Io
import "LauncherMatch.js" as Match

// ":" mode: emoji (Unicode list + CLDR keywords) and HTML entities; Enter
// copies the character.
Scope {
    id: root

    required property int limit

    property var emojis: []

    // emoji list from Unicode (unicode-emoji) with search keywords from CLDR
    FileView {
        id: emojiTest
        path: "/usr/share/unicode/emoji/emoji-test.txt"
        onLoaded: root.buildEmojis()
    }

    FileView {
        id: emojiAnnotations
        path: "/usr/share/unicode/cldr/common/annotations/en.xml"
        onLoaded: root.buildEmojis()
    }

    // CLDR keys usually omit the U+FE0F variation selector
    function emojiKey(emoji) {
        return emoji.replace(/️/g, "");
    }

    function buildEmojis() {
        if (!emojiTest.loaded || !emojiAnnotations.loaded)
            return;

        // <annotation cp="🔥">af | burn | fire | flame</annotation>; the
        // type="tts" variants (just the name again) don't match this pattern
        // (exec loops: Qt's JS engine has no String.matchAll)
        const keywords = new Map();
        const annotationRe = /<annotation cp="([^"]+)">([^<]*)<\/annotation>/g;
        const annotations = emojiAnnotations.text();
        let m;
        while ((m = annotationRe.exec(annotations)) !== null)
            keywords.set(emojiKey(m[1]), m[2].replace(/&amp;/g, "&"));

        // 1F525 ; fully-qualified # 🔥 E0.6 fire
        const list = [];
        const emojiRe = /; fully-qualified\s+# (\S+) E[\d.]+ (.+)$/gm;
        const test = emojiTest.text();
        while ((m = emojiRe.exec(test)) !== null) {
            const [, emoji, name] = m;
            if (!name.includes("skin tone"))
                list.push({ emoji, name, keywords: keywords.get(emojiKey(emoji)) ?? "" });
        }
        root.emojis = list;
    }

    // HTML entity names for accented letters are letter + accent (eacute,
    // ccedil, ...): compose them, keeping the Latin-1 ones (exactly those
    // that have entity names), plus a few common symbols
    readonly property var entities: {
        const marks = { acute: "́", grave: "̀", circ: "̂", uml: "̈", tilde: "̃", cedil: "̧", ring: "̊" };
        const out = [];
        for (const letter of "aeiouycnAEIOUYCN")
            for (const accent in marks) {
                const char = String(letter + marks[accent]).normalize("NFC");
                if (char.length === 1 && char.charCodeAt(0) <= 0xFF)
                    out.push({ name: letter + accent, char });
            }
        const extras = {
            szlig: "ß", aelig: "æ", AElig: "Æ", oslash: "ø", Oslash: "Ø",
            copy: "©", reg: "®", trade: "™", deg: "°", plusmn: "±", times: "×", divide: "÷",
            euro: "€", pound: "£", yen: "¥", cent: "¢", sect: "§", para: "¶", micro: "µ",
            laquo: "«", raquo: "»", iquest: "¿", iexcl: "¡", middot: "·",
            hellip: "…", ndash: "–", mdash: "—", frac12: "½", frac14: "¼", frac34: "¾"
        };
        for (const name in extras)
            out.push({ name, char: extras[name] });
        return out;
    }

    // searchable items, built once (not per keystroke)
    readonly property var symbols: emojis.map(e => ({ name: e.name, nameLc: e.name.toLowerCase(), kwLc: e.keywords.toLowerCase(), char: e.emoji, emoji: true }))
        .concat(entities.map(e => ({ name: e.name, nameLc: e.name.toLowerCase(), kwLc: "", char: e.char })))

    readonly property var cache: ({})

    function rows(text) {
        const raw = text.trim();
        const q = raw.toLowerCase();
        if (!q)
            return [];
        // ":eacute" é before ":Eacute" É
        return Match.ranked(cache, symbols, q, raw).slice(0, limit).map(({ item }) => ({
            label: item.name,
            glyph: item.char,
            emoji: !!item.emoji,
            detail: item.emoji ? "emoji" : "&" + item.name + ";",
            run: () => Quickshell.execDetached(["wl-copy", item.char])
        }));
    }
}
