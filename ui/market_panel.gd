class_name MarketPanel
extends Sheet
## The inference market at a glance (see Market): what customers want, what
## your servers can answer, what gets through the gateways, the power grid
## and the cooling loop, your reputation and what's holding you back; then
## your fleet, every server with its throughput; then every model you serve
## with its price (dearer earns more per token but loses customers).

var _live: Array = []           # [Label, Callable -> String]
var _bars: Array = []           # [Panel fill, Panel track, Callable -> float]
var _t := 0.0


func _init() -> void:
	title = "Market"
	title_icon = "gateway"
	height_frac = 0.8


func _build() -> void:
	body.add_child(_summary())
	body.add_child(_advice())
	body.add_child(_fleet())
	var any := false
	for rid in Game.known_list():
		later(body, _model_row.bind(rid))
		any = true
	if not any:
		body.add_child(Kit.label("You don't own a model yet.", 18, Kit.MUTED, 0))
	if Market.orbit_modules > 0 or Game.count_of("launchpad") > 0:
		body.add_child(_orbit())


func _process(dt: float) -> void:
	super(dt)
	_t -= dt
	if _t > 0.0:
		return
	_t = 0.25
	for e in _live:
		if is_instance_valid(e[0]):
			(e[0] as Label).text = (e[1] as Callable).call()
	for b in _bars:
		if is_instance_valid(b[0]):
			var f := clampf(float((b[2] as Callable).call()), 0.0, 1.0)
			(b[0] as Panel).size = Vector2(maxf(12.0, (b[1] as Panel).size.x * f) if f > 0.0 else 0.0, 18)


func _lbl(make: Callable, size := 16, color := Kit.MUTED, bold := false) -> Label:
	var l := Kit.label(make.call(), size, color, 0, bold)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 200
	_live.append([l, make])
	return l


func _bar(f: Callable, green := false) -> Control:
	var track := Panel.new()
	track.add_theme_stylebox_override("panel", Kit.skin("track", 10))
	track.custom_minimum_size = Vector2(0, 18)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := Panel.new()
	fill.add_theme_stylebox_override("panel", Kit.skin("fill_green" if green else "fill_gold", 10))
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	_bars.append([fill, track, f])
	return track


func _stat(icon: String, name: String, val: Callable, bar: Callable, green := false) -> Control:
	var v := Kit.vbox(2)
	var h := Kit.hbox(8)
	v.add_child(h)
	h.add_child(Kit.icon(icon, 30))
	h.add_child(Kit.game(name, 18, Kit.INK, 0))
	var l := _lbl(val, 16, Kit.MUTED, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(l)
	v.add_child(_bar(bar, green))
	return v


func _summary() -> Control:
	var box := Sheet.row_box()
	var v := Kit.vbox(10)
	box.add_child(v)
	v.add_child(_lbl(func(): return "Earning $%s/s  ·  %s tok/s served" % [Fmt.num(Market.income), Fmt.tokens(Market.total(Market.served))], 22, Kit.INK, true))
	v.add_child(_stat("server", "Capacity in use", func(): return "%s of %s tok/s" % [Fmt.tokens(Market.total(Market.served)), Fmt.tokens(Market.total(Market.cap))], func(): return Market.utilisation()))
	v.add_child(_stat("gateway", "Demand answered", func(): return "%s of %s tok/s wanted" % [Fmt.tokens(Market.total(Market.served)), Fmt.tokens(Market.total(Market.demand))],
		func():
			var d := Market.total(Market.demand)
			return Market.total(Market.served) / d if d > 0.0 else 1.0, true))
	v.add_child(_stat("fiber", "Home internet line" if Game.count_ready("gateway") == 0 else "Bandwidth", func(): return "%s of %s tok/s" % [Fmt.tokens(Market.used_bw), Fmt.tokens(Market.bandwidth)], func(): return Market.used_bw / maxf(0.0001, Market.bandwidth)))
	v.add_child(_stat("power", "Power grid", func(): return "%s of %s kW" % [Fmt.num(roundf(Market.power_draw)), Fmt.num(roundf(Market.power_supply))],
		func(): return Market.power_draw / maxf(0.0001, Market.power_supply)))
	if Market.cool_draw > 0.0 or Market.cool_supply > 0.0:
		v.add_child(_stat("coolant", "Cooling loop", func(): return "%s of %s" % [Fmt.num(roundf(Market.cool_draw)), Fmt.num(roundf(Market.cool_supply))],
			func(): return Market.cool_draw / maxf(0.0001, Market.cool_supply)))
	v.add_child(_stat("star", "Reputation", func(): return "%d%%" % roundi(Market.rep * 100), func(): return Market.rep, true))
	v.add_child(_lbl(func():
		var ch := []
		for c in ["api", "cafe", "contract", "agent"]:
			var x := Market.total(Market.by_channel.get(c, {}))
			if x > 0.0:
				ch.append("%s %s" % [{"api": "API", "cafe": "Café", "contract": "Contracts", "agent": "Agents"}[c], Fmt.tokens(x)])
		return "By channel (tok/s): " + ("  ·  ".join(ch) if not ch.is_empty() else "nothing yet"), 15))
	return box


## What's holding the empire back right now.
static func advice() -> String:
	var cap := Market.total(Market.cap)
	var dem := Market.total(Market.demand)
	if Market.power_supply <= 0.0:
		return "No power grid: build a Solar Farm. Its power lines reach every server."
	if cap <= 0.0:
		return "No server is serving: pick a model for it."
	if Market.power_f < 0.98:
		return "The power grid is short (%d%%): every server slows down. Upgrade or build Solar Farms." % roundi(Market.power_f * 100)
	if Market.cool_f < 0.98:
		return "The cooling loop is short (%d%%): GPUs are throttling. Upgrade or build Cooling Towers." % roundi(Market.cool_f * 100)
	var no_gw := Game.count_ready("gateway") == 0
	if Market.used_bw >= Market.bandwidth * 0.98 and Market.bandwidth > 0.0:
		if no_gw:
			return "Your home internet line is full: build an API Gateway for real bandwidth and many more customers."
		return "Your gateways are full: build an API Gateway or rack fiber spools on one (Fiber Hub)."
	if dem > cap * 1.1:
		if not Game.is_open("fab"):
			return "Customers want %s tok/s more than you can answer: upgrade your server, or build a second one." % Fmt.tokens(dem - cap)
		return "Customers want %s tok/s more than you can answer: install GPUs (Chip Fab), add servers, or raise prices." % Fmt.tokens(dem - cap)
	if cap > dem * 1.5:
		if no_gw:
			return "Idle capacity: your home line only reaches a few customers. An API Gateway brings many more."
		return "Idle capacity: more customers would pay for it. API Gateways, a Chat Café, Edge PoPs, contracts, lower prices or a bigger model."
	if Market.rep < 0.6:
		return "Reputation is low because calls go unanswered. Serve what customers want and it climbs back."
	return "Balanced: demand and capacity are close. Grow both, and train a bigger model."


func _advice() -> Control:
	var box := Sheet.row_box()
	var h := Kit.hbox(10)
	box.add_child(h)
	h.add_child(Kit.icon("research", 44))
	var l := _lbl(func(): return MarketPanel.advice(), 17, Kit.INK, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return box


## Your fleet: every server, its throughput, load, GPUs and tune; tap one to go there.
func _fleet() -> Control:
	var box := Sheet.row_box()
	var v := Kit.vbox(6)
	box.add_child(v)
	var servers: Array = []
	var world = get_tree().current_scene.get("world")
	if world:
		for n in world.buildings_of("server"):
			if n is ServerB and not n is SiteB:
				servers.append(n)
	var h := Kit.hbox(8)
	v.add_child(h)
	h.add_child(Kit.icon("server", 34))
	h.add_child(Kit.game("Your fleet: %d server%s" % [servers.size(), "" if servers.size() == 1 else "s"], 20, Kit.INK, 0))
	v.add_child(_lbl(func():
		var g := 0
		var c := 0.0
		for s in servers:
			if is_instance_valid(s):
				g += (s as ServerB).gpus()
				c += (s as ServerB).last_cap
		return "%d GPUs  ·  up to %s tok/s together" % [g, Fmt.tokens(c)], 15))
	for s in servers:
		v.add_child(_server_row(s))
	return box


func _server_row(s: ServerB) -> Control:
	var h := Kit.hbox(8)
	var ic := Kit.icon("tk_" + s.recipe, 40)
	h.add_child(ic)
	var l := _lbl(func():
		if not is_instance_valid(s):
			return ""
		return "Lv %d  ·  %s  ·  %s tok/s  ·  %d%% busy  ·  %d GPU%s%s" % [s.level, Defs.model_name(s.recipe), Fmt.tokens(s.last_cap * s.load_now), roundi(s.load_now * 100), s.gpus(), "" if s.gpus() == 1 else "s", ("  ·  tuned +%d%%" % roundi(Bal.TUNE_BONUS * s.tune * 100)) if s.tune > 0.05 else ""], 14, Kit.INK)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var go := Kit.juicy("Go", Kit.CHARCOAL, Kit.CHARCOAL_EDGE, 16, Vector2(64, 48))
	go.pressed.connect(func():
		var ui = get_tree().current_scene.get("ui")
		if ui and is_instance_valid(s):
			close()
			ui.call("select", s)
			ui.get("world").cam.fly_to(s.global_position + Vector3(0, 0, 2), 0.8))
	h.add_child(go)
	return h


func _model_row(rid: String) -> Control:
	var r := Defs.recipe(rid)
	var box := Sheet.row_box()
	var v := Kit.vbox(6)
	box.add_child(v)
	var h := Kit.hbox(10)
	v.add_child(h)
	h.add_child(Kit.icon("tk_" + rid, 56))
	var nv := Kit.vbox(0)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nv)
	nv.add_child(Kit.game(r["name"], 20, Kit.INK, 0))
	nv.add_child(_lbl(func(): return "$%s per 1K  ·  %d ms  ·  quality %d%%" % [Fmt.num(Market.token_price(rid)), roundi(float(Market.lat.get(rid, r["lat"]))), roundi(Market.quality_of(rid) * 100)], 14))
	var minus := Kit.juicy("-", Kit.CHARCOAL, Kit.CHARCOAL_EDGE, 24, Vector2(56, 56))
	var pl := _lbl(func(): return "x%.2f" % Market.price_of(rid), 18, Kit.INK, true)
	pl.custom_minimum_size.x = 64
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := Kit.juicy("+", Kit.CHARCOAL, Kit.CHARCOAL_EDGE, 24, Vector2(56, 56))
	minus.pressed.connect(func(): Market.set_price(rid, Market.price_of(rid) - 0.1))
	plus.pressed.connect(func(): Market.set_price(rid, Market.price_of(rid) + 0.1))
	h.add_child(minus)
	h.add_child(pl)
	h.add_child(plus)
	v.add_child(_lbl(func():
		var d := float(Market.demand.get(rid, 0.0))
		var c := float(Market.cap.get(rid, 0.0))
		var s := float(Market.served.get(rid, 0.0))
		if c <= 0.0:
			return "Wanted %s tok/s, but no server runs it" % Fmt.tokens(d)
		return "Wanted %s  ·  capacity %s  ·  served %s tok/s" % [Fmt.tokens(d), Fmt.tokens(c), Fmt.tokens(s)], 15, Kit.SAGE_EDGE, true))
	v.add_child(_bar(func():
		var d := float(Market.demand.get(rid, 0.0))
		return float(Market.served.get(rid, 0.0)) / d if d > 0.0 else 0.0, true))
	return box


func _orbit() -> Control:
	var box := Sheet.row_box()
	var v := Kit.vbox(6)
	box.add_child(v)
	var h := Kit.hbox(10)
	v.add_child(h)
	h.add_child(Kit.icon("launchpad", 50))
	h.add_child(Kit.game("Orbital datacenter", 20, Kit.INK, 0))
	v.add_child(_lbl(func():
		if Market.orbit_modules <= 0:
			return "Nothing in orbit yet: the Launch Complex assembles a module from 24 GPUs, 8 HBM stacks and 60 power cells."
		return "%d module%s serving %s: %s tok/s, downlink %s tok/s (Ground Stations)" % [Market.orbit_modules, "s" if Market.orbit_modules > 1 else "", Defs.model_name(Market.orbit_model), Fmt.tokens(Market.orbit_capacity()), Fmt.tokens(Market.downlink())], 15, Kit.INK, true))
	return box
