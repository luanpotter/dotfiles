# GCIDE is plain ASCII: every other character is an entity <name/ or an
# escape \'xx (webfont.txt in the data dir). entities(s) decodes them.
# Accented letters are a letter + a mark name (<eacute/, <usdot/), composed
# from M; everything else is in E. Unknown names read as themselves.

BEGIN {
	# marks: letter + mark name -> letter + combining character
	M["acute"] = "́"
	M["grave"] = "̀"
	M["cir"] = "̂"
	M["um"] = "̈"
	M["til"] = "̃"
	M["ring"] = "̊"
	M["mac"] = "̄"
	M["smac"] = "̄"  # "short macron", in poetry meter
	M["sl"] = "̄"    # "semilong", in pronunciations
	M["cr"] = "̆"    # crescent, a breve
	M["dot"] = "̇"
	M["sdot"] = "̣"  # dot below
	M["dd"] = "̤"    # double dot below
	M["sm"] = "̱"    # macron below
	M["car"] = "̌"
	M["ced"] = "̧"
	M["it"] = ""     # italic vowel, in pronunciations

	# spacing and layout
	E["br"] = " "
	E["nbsp"] = " "
	E["colbreak"] = " "
	E["colret"] = " "

	# punctuation and typography
	E["ldquo"] = "“"
	E["rdquo"] = "”"
	E["lsquo"] = "‘"
	E["rsquo"] = "’"
	E["mdash"] = "—"
	E["ndash"] = "–"
	E["hand"] = "☞"
	E["sect"] = "§"
	E["para"] = "¶"
	E["par"] = "‖"
	E["dag"] = "†"
	E["dagger"] = "†"
	E["ddag"] = "‡"
	E["Dagger"] = "‡"
	E["asterism"] = "⁂"
	E["iques"] = "¿"
	E["middot"] = "•"
	E["?"] = "?"     # illegible in the original
	E["and"] = "and" # italic "and"
	E["or"] = "or"   # italic "or"

	# math and units
	E["deg"] = "°"
	E["prime"] = "′"
	E["bprime"] = "″"
	E["sec"] = "″"
	E["Prime"] = "″"
	E["times"] = "×"
	E["divide"] = "÷"
	E["min"] = "−"
	E["gt"] = ">"
	E["lt"] = "<"
	E["root"] = "√"
	E["cuberoot"] = "∛"
	E["nabla"] = "∇"
	E["integral2l"] = "∫"
	E["rarr"] = "→"
	E["pound"] = "£"
	E["ounceap"] = "℥"
	E["frac12"] = "½"
	E["frac13"] = "⅓"
	E["frac23"] = "⅔"
	E["frac14"] = "¼"
	E["frac34"] = "¾"
	E["frac15"] = "⅕"
	E["frac16"] = "⅙"
	E["frac56"] = "⅚"
	E["frac18"] = "⅛"
	E["frac38"] = "⅜"
	E["frac58"] = "⅝"

	# letters and ligatures
	E["ae"] = "æ"
	E["AE"] = "Æ"
	E["oe"] = "œ"
	E["OE"] = "Œ"
	E["aemac"] = "ǣ"
	E["oemac"] = "œ̄"
	E["oomac"] = "o͞o"
	E["oocr"] = "o͝o"
	E["edh"] = "ð"
	E["EDH"] = "Ð"
	E["thorn"] = "þ"
	E["yogh"] = "ȝ"
	E["nsc"] = "ɴ"
	E["schwa"] = "ə"
	E["th"] = "th"   # th ligature, in pronunciations
	E["filig"] = "fi"
	E["fllig"] = "fl"
	E["ffllig"] = "ffl"
	E["Crev"] = "Ↄ"
	E["asper"] = "ʽ"

	# music
	E["sharp"] = "♯"
	E["flat"] = "♭"
	E["natural"] = "♮"
	E["segno"] = "𝄋"
	E["pause"] = "𝄐"
	E["cre"] = "˘"
	E["breve"] = "˘"
	E["umlaut"] = "¨"

	# astronomy
	E["Sun"] = "☉"
	E["Mercury"] = "☿"
	E["Jupiter"] = "♃"
	E["Male"] = "♂"
	E["Aries"] = "♈"
	E["Taurus"] = "♉"
	E["Gemini"] = "♊"
	E["Cancer"] = "♋"
	E["Leo"] = "♌"
	E["Virgo"] = "♍"
	E["Libra"] = "♎"
	E["Scorpio"] = "♏"
	E["Sagittarius"] = "♐"
	E["Capricorn"] = "♑"
	E["Aquarius"] = "♒"
	E["Pisces"] = "♓"

	# Greek, mostly in etymologies
	E["alpha"] = "α"
	E["beta"] = "β"
	E["gamma"] = "γ"
	E["delta"] = "δ"
	E["epsilon"] = "ε"
	E["digamma"] = "ϝ"
	E["zeta"] = "ζ"
	E["eta"] = "η"
	E["theta"] = "θ"
	E["iota"] = "ι"
	E["kappa"] = "κ"
	E["lambda"] = "λ"
	E["mu"] = "μ"
	E["nu"] = "ν"
	E["xi"] = "ξ"
	E["omicron"] = "ο"
	E["pi"] = "π"
	E["rho"] = "ρ"
	E["sigma"] = "σ"
	E["sigmat"] = "ς"
	E["tau"] = "τ"
	E["upsilon"] = "υ"
	E["phi"] = "φ"
	E["chi"] = "χ"
	E["psi"] = "ψ"
	E["omega"] = "ω"
	E["ALPHA"] = "Α"
	E["BETA"] = "Β"
	E["GAMMA"] = "Γ"
	E["DELTA"] = "Δ"
	E["EPSILON"] = "Ε"
	E["ZETA"] = "Ζ"
	E["ETA"] = "Η"
	E["THETA"] = "Θ"
	E["IOTA"] = "Ι"
	E["KAPPA"] = "Κ"
	E["LAMBDA"] = "Λ"
	E["MU"] = "Μ"
	E["NU"] = "Ν"
	E["XI"] = "Ξ"
	E["OMICRON"] = "Ο"
	E["PI"] = "Π"
	E["RHO"] = "Ρ"
	E["SIGMA"] = "Σ"
	E["TAU"] = "Τ"
	E["UPSILON"] = "Υ"
	E["PHI"] = "Φ"
	E["CHI"] = "Χ"
	E["PSI"] = "Ψ"
	E["OMEGA"] = "Ω"
}

function ent(name, mark) {
	if (name in E)
		return E[name]
	mark = substr(name, 2)
	if (mark in M)
		return substr(name, 1, 1) M[mark]
	# other fractions: <frac58/ 5/8, <frac1x20/ 1/20
	if (name ~ /^frac[0-9]+x[0-9]+$/) {
		sub(/^frac/, "", name)
		sub(/x/, "/", name)
		return name
	}
	if (name ~ /^frac[0-9][0-9]$/)
		return substr(name, 5, 1) "/" substr(name, 6, 1)
	return name
}

function entities(s, out) {
	# only legacy \'xx escapes remaining: from MICRA's old custom format
	gsub(/\\'d8/, "", s) # ‖, "adopted unchanged" mark before headwords
	gsub(/\\'94/, "ö", s)
	gsub(/\\'fa/, "·", s)
	out = ""
	while (match(s, /<[A-Za-z0-9?]+\//)) {
		out = out substr(s, 1, RSTART - 1) ent(substr(s, RSTART + 1, RLENGTH - 2))
		s = substr(s, RSTART + RLENGTH)
	}
	return out s
}
