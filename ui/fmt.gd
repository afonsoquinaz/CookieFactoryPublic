class_name Fmt
## Number formatting: 950, 1.2K, 34.5K, 1.20M ...

static func num(v: float) -> String:
	var a := absf(v)
	var s := "-" if v < 0 else ""
	if a < 1000.0:
		return s + str(int(a))
	var units := ["K", "M", "B", "T", "Qa", "Qi"]
	var u := -1
	while a >= 1000.0 and u < units.size() - 1:
		a /= 1000.0
		u += 1
	var txt := ("%.2f" % a) if a < 10.0 else (("%.1f" % a) if a < 100.0 else str(int(a)))
	if txt.contains("."):
		txt = txt.rstrip("0").rstrip(".")
	return s + txt + units[u]


static func time(sec: float) -> String:
	var s := int(ceil(sec))
	if s < 60:
		return "%ds" % s
	if s < 3600:
		return "%dm %02ds" % [s / 60, s % 60]
	if s < 86400:
		return "%dh %02dm" % [s / 3600, (s % 3600) / 60]
	return "%dd %dh" % [s / 86400, (s % 86400) / 3600]
