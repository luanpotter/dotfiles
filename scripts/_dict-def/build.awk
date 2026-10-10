# dict-def --build: raw CIDE.A-Z markup (README in the data dir) to the
# lookup files in `out` (see dict-def). Needs entities.awk.
# Records are paragraphs (RS=""); an entry starts at a paragraph opening
# with <p><ent>, one <ent> per headword, and runs until the next one.

BEGIN {
	RS = ""
}

# markup to one line of plain text
function clean(s) {
	gsub(/<--([^-]|-[^-])*-->/, "", s) # page comments
	gsub(/\[<source>[^]]*\]/, "", s)
	gsub(/<rj>/, " — ", s) # right-justified quote attribution
	s = entities(s)
	gsub(/<[^>]*>/, "", s)
	gsub(/[ \t\n]+/, " ", s)
	gsub(/^ | $/, "", s)
	return s
}

# s without its <tag>...</tag> spans
function drop(s, tag, i, j) {
	while ((i = index(s, "<" tag ">")) && (j = index(s, "</" tag ">")) > i)
		s = substr(s, 1, i - 1) substr(s, j + length(tag) + 3)
	return s
}

# the first <tag>'s text
function inner(rec, tag, i, j) {
	if (!(i = index(rec, "<" tag ">")))
		return ""
	i += length(tag) + 2
	j = index(substr(rec, i), "</" tag ">")
	return clean(j ? substr(rec, i, j - 1) : substr(rec, i))
}

# Webster 1913 capitalizes every headword, so its case means nothing; later
# additions (WordNet, volunteers) use real case. A Webster headword gets a
# lowercase first letter unless it's a proper noun or an abbreviation (IQ);
# a `trusted` entry keeps its case.
function cased(name) {
	if (trusted || name ~ /^[A-Z][A-Z0-9.]+$/)
		return name
	return tolower(substr(name, 1, 1)) substr(name, 2)
}

# the finished entry goes to each of its headwords: entries sharing a word
# (set: v. t., v. i., n., a.) merge, listing every part of speech, keeping
# the first definition and the first trusted case
function flush(i, k, p) {
	for (i = 1; i <= nnames; i++) {
		k = tolower(names[i])
		if (!(k in W) || (trusted && !(k in C))) {
			W[k] = names[i]
			if (trusted)
				C[k] = 1
		}
		if (!(k in P)) {
			P[k] = pos
			D[k] = def
			T[k] = text
			continue
		}
		p = ", " P[k] ", "
		if (pos != "" && !index(p, ", " pos ", "))
			P[k] = P[k] == "" ? pos : P[k] ", " pos
		if (D[k] == "")
			D[k] = def
		T[k] = T[k] "\t\t" text
	}
	nnames = 0
}

# opening paragraph: a header line (headwords, part of speech, inflections,
# etymology), then the first sense
/^<p><ent>/ {
	flush()
	pos = inner($0, "pos")
	trusted = inner($0, "source") !~ /Webster/ || index(pos, "prop")
	nnames = split($0, parts, "<ent>") - 1
	for (i = 1; i <= nnames; i++)
		names[i] = cased(clean(substr(parts[i + 1], 1, index(parts[i + 1], "</ent>") - 1)))
	def = ""
	rec = drop(drop(drop($0, "ent"), "hw"), "pr")
	b = index(rec, "<sn>")
	d = index(rec, "<def>")
	if (!b || (d && d < b))
		b = d
	head = clean(b ? substr(rec, 1, b - 1) : rec)
	sub(/^[ ,]+/, "", head)
	text = names[1]
	for (i = 2; i <= nnames; i++)
		text = text ", " names[i]
	if (head != "")
		text = text "  " head
	if (b)
		text = text "\t" clean(substr(rec, b))
}

nnames && !/^<p><ent>/ {
	s = clean($0)
	if (s != "")
		text = text "\t" (/^<p><q>/ ? "    " : "") s
}

# definition start, cut at a word so multibyte characters stay whole
nnames && def == "" && index($0, "<def>") {
	def = inner($0, "def")
	if (length(def) > 200) {
		def = substr(def, 1, 200)
		sub(/ [^ ]*$/, "…", def)
	}
}

END {
	flush()
	icmd = "sort -o '" out "/index.tsv'"
	ecmd = "sort -o '" out "/entries.tsv'"
	wcmd = "sort -t '\t' -k1,1nr | cut -f 2 >'" out "/words.txt'"
	for (k in W) {
		print k "\t" W[k] "\t" P[k] "\t" D[k] | icmd
		print k "\t" T[k] | ecmd
		# entry size stands in for how common a word is
		print length(T[k]) "\t" k | wcmd
	}
	if (close(icmd) || close(ecmd) || close(wcmd))
		exit 1
}
