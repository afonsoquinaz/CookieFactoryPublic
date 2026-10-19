class_name LivePanel
extends Sheet
## The daily layer in one sheet (see Live), six tabs:
##   Today   inbox, streak and daily goal, login calendar, quests,
##           Breakthrough stamps, crates, boosters
##   League  this week's Benchmark League table
##   Pass    the Lab Pass season track, free and premium
##   Events  what's on now and next (Spotlight Hour, Community Day...)
##   Album   badges and model mastery
##   Me      profile, friend code, sharing, reminders

static var last_tab := "today"
var tab := ""
var _tabs := {}
var _dirty := false
var _rebuild_t := 0.0
var _clocks: Array = []                     # [[Label, Callable -> String]]
var _clock_t := 0.0
var hud


func _init() -> void:
	title = "Lab HQ"
	title_icon = "calendar"
	height_frac = 0.8


func _header(v: VBoxContainer) -> void:
	var h := Kit.hbox(4)
	v.add_child(h)
	for t in [["today", "calendar", "Today"], ["league", "shield", "League"], ["pass", "pass", "Pass"], ["events", "event", "Events"], ["album", "album", "Album"], ["me", "profile", "Me"]]:
		var b := Kit.juicy("", Kit.PAPER_DARK, Kit.LINE, 14, Vector2(0, 74))
		b.sound = "click"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.row.queue_free()
		var bv := Kit.vbox(-6)
		bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bv.offset_bottom = -8
		b.add_child(bv)
		var ic := Kit.icon(t[1], 40)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if t[0] == "league":
			ic.modulate = LiveDefs.LEAGUES[int(Live.league["tier"])]["color"].lightened(0.2)
		bv.add_child(ic)
		var l := Kit.game(t[2], 15, Kit.INK, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(l)
		b.row = Kit.hbox()
		b.pressed.connect(func(): select(t[0]))
		h.add_child(b)
		_tabs[t[0]] = b
	Live.changed.connect(func(): _dirty = true)


func _build() -> void:
	select(last_tab)


func select(t: String) -> void:
	var keep := scroll.scroll_vertical if t == tab else 0
	tab = t
	last_tab = t
	for k in _tabs:
		_tabs[k].set_colors(Kit.BRASS if k == t else Kit.PAPER_DARK, Kit.BRASS_EDGE if k == t else Kit.LINE)
	for c in body.get_children():
		c.queue_free()
	_clocks.clear()
	match t:
		"today": _today()
		"league": _league()
		"pass": _pass()
		"events": _events()
		"album": _album()
		"me": _me()
	_dirty = false
	await get_tree().process_frame
	if is_instance_valid(scroll):
		scroll.scroll_vertical = keep


func _process(dt: float) -> void:
	super(dt)
	_rebuild_t -= dt
	if _dirty and _rebuild_t <= 0.0:
		_rebuild_t = 0.6
		select(tab)
	_clock_t -= dt
	if _clock_t <= 0.0:
		_clock_t = 1.0
		for c in _clocks:
			if is_instance_valid(c[0]):
				(c[0] as Label).text = (c[1] as Callable).call()


# ---------------------------------------------------------------- widgets

func _card(head: String, icon := "", sub := "") -> VBoxContainer:
	var box := Sheet.row_box()
	body.add_child(box)
	var v := Kit.vbox(8)
	box.add_child(v)
	if head != "":
		var h := Kit.hbox(10)
		v.add_child(h)
		if icon != "":
			h.add_child(Kit.icon(icon, 46))
		var hv := Kit.vbox(0)
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(hv)
		hv.add_child(Kit.game(head, 25, Kit.INK, 0))
		if sub != "":
			var s := Kit.label(sub, 15, Kit.MUTED, 0, false)
			s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			s.custom_minimum_size.x = 260
			hv.add_child(s)
	return v


func _bar(f: float, w := 0.0, green := false) -> Control:
	var track := Panel.new()
	track.add_theme_stylebox_override("panel", Kit.skin("track", 10))
	track.custom_minimum_size = Vector2(w, 18)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL if w <= 0.0 else Control.SIZE_SHRINK_BEGIN
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := Panel.new()
	fill.add_theme_stylebox_override("panel", Kit.skin("fill_green" if green else "fill_gold", 10))
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	var ff := clampf(f, 0.0, 1.0)
	track.resized.connect(func(): fill.size = Vector2(maxf(12.0, track.size.x * ff) if ff > 0.0 else 0.0, 18))
	return track


func _clock_label(make: Callable, size := 15, color := Kit.MUTED) -> Label:
	var l := Kit.label(make.call(), size, color, 0, false)
	_clocks.append([l, make])
	return l


func _btn(text: String, face: Color, edge: Color, on_press: Callable, w := 150.0, icon := "") -> JuicyButton:
	var b := Kit.juicy(text, face, edge, 18, Vector2(w, 56))
	if icon != "":
		b.set_icon(icon, 26)
	b.sound = ""
	b.pressed.connect(func():
		var ok = on_press.call()
		if ok is Array and not (ok as Array).is_empty():
			Sfx.play("cash")
			_show_items(ok)
		elif ok is bool and ok:
			Sfx.play("upgrade")
		elif (ok is bool and not ok) or (ok is Array):
			Sfx.play("deny")
			Kit.shake(b)
		_dirty = true)
	return b


func _claim_btn(on_press: Callable, ready: bool, text := "Claim") -> JuicyButton:
	var b := _btn(text, Kit.SAGE if ready else Kit.GREY, Kit.SAGE_EDGE if ready else Kit.GREY_EDGE, on_press, 120)
	return b


## Pops what a claim gave as a little toast list.
func _show_items(items: Array) -> void:
	if hud == null:
		return
	for it in items:
		hud.toast("+ " + str(it[1]), it[0])


func _row(icon: String, text: String, sub := "", icon_mod := Color.WHITE) -> HBoxContainer:
	var h := Kit.hbox(10)
	var ic := Kit.icon(icon, 46)
	ic.modulate = icon_mod
	h.add_child(ic)
	var v := Kit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := Kit.label(text, 17, Kit.INK, 0)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size.x = 200
	v.add_child(t)
	if sub != "":
		var s := Kit.label(sub, 14, Kit.MUTED, 0, false)
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.custom_minimum_size.x = 200
		v.add_child(s)
	return h


static func _when(lt: int) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(lt)
	var days := ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	return "%s %d/%d %02d:%02d" % [days[int(dt["weekday"])], int(dt["day"]), int(dt["month"]), int(dt["hour"]), int(dt["minute"])]


# ---------------------------------------------------------------- Today

func _today() -> void:
	# messages with something to claim
	var pending := []
	for m in Live.inbox:
		if not m["claimed"]:
			pending.append(m)
	if not pending.is_empty():
		var iv := _card("Inbox", "mail", "%d message%s for you" % [pending.size(), "s" if pending.size() > 1 else ""])
		for m in pending:
			var r := _row(m["icon"], m["title"], "%s\n%s" % [m["body"], Live.describe(m["reward"])])
			var id := int(m["id"])
			r.add_child(_claim_btn(func(): return Live.claim_msg(id), true))
			iv.add_child(r)
	_streak_card()
	_login_card()
	_quests_card()
	_crates_card()
	_boosters_card()


func _streak_card() -> void:
	var sub := "Serve %s tokens today to keep it going." % Fmt.num(Live.goal)
	if Live.goal_is_done:
		sub = "Today's goal done. See you tomorrow!"
	var v := _card("%d-day streak" % Live.streak, "flame", sub)
	var ic: TextureRect = (v.get_child(0) as HBoxContainer).get_child(0)
	ic.modulate = LiveDefs.flame_color(Live.streak, Live.goal_is_done)
	var gh := Kit.hbox(10)
	v.add_child(gh)
	gh.add_child(_bar(float(Live.goal_got) / maxf(1.0, Live.goal), 0.0, Live.goal_is_done))
	gh.add_child(Kit.label("%s / %s" % [Fmt.num(mini(Live.goal_got, Live.goal)), Fmt.num(Live.goal)], 16, Kit.INK, 0))
	# the last seven days
	var week := Kit.hbox(6)
	week.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(week)
	var t := Live.today()
	var names := ["S", "M", "T", "W", "T", "F", "S"]
	for k in range(6, -1, -1):
		var d := t - k
		var dv := Kit.vbox(0)
		var mark := Live.day_mark(d)
		var di := Kit.icon("freeze" if mark == "freeze" else "flame", 42)
		di.modulate = LiveDefs.flame_color(Live.streak, true) if mark == "goal" else (Color.WHITE if mark == "freeze" else Color(0.75, 0.77, 0.8, 0.45))
		dv.add_child(di)
		var wd := int(Time.get_datetime_dict_from_unix_time(d * 86400)["weekday"])
		var dl := Kit.label(names[wd], 14, Kit.INK if d == t else Kit.MUTED, 0)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dv.add_child(dl)
		week.add_child(dv)
	var fh := Kit.hbox(10)
	v.add_child(fh)
	fh.add_child(Kit.icon("freeze", 34))
	var fl := Kit.label("Streak Freezes %d/%d  ·  best streak %d" % [Live.freezes, LiveDefs.MAX_FREEZES, Live.streak_best], 15, Kit.MUTED, 0, false)
	fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fh.add_child(fl)
	if Live.freezes < LiveDefs.MAX_FREEZES:
		fh.add_child(_btn(str(LiveDefs.FREEZE_PRICE), Kit.CHARCOAL, Kit.CHARCOAL_EDGE, func(): return Live.buy_freeze(), 110, "gem"))
	if Live.can_repair():
		var rv := _row("flame", "Your %d-day streak ended" % Live.lost_streak, "Repair it before tomorrow ends and keep counting.", Color(0.62, 0.64, 0.68))
		rv.add_child(_btn(str(Live.repair_price()), Kit.TERRACOTTA, Kit.TERRACOTTA_EDGE, func(): return Live.repair_streak(), 120, "gem"))
		v.add_child(rv)
	v.add_child(_clock_label(func(): return "Day ends in %s" % Fmt.time(Live.to_midnight())))


func _login_card() -> void:
	var v := _card("Daily bonus", "gift", "A gift every day you open the lab. Day 7 is a Server Crate.")
	var g := HFlowContainer.new()
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	v.add_child(g)
	var cur := Live.login_idx % 7
	for i in 7:
		var r: Dictionary = LiveDefs.LOGIN[i]
		var p := PanelContainer.new()
		var today_tile := (i == cur and not Live.login_claimed) or (Live.login_claimed and i == posmod(cur - 1, 7))
		p.add_theme_stylebox_override("panel", Kit.skin("card_dark" if today_tile else "card", 24, Vector4(8, 6, 8, 8)))
		p.custom_minimum_size = Vector2(88, 0)
		var pv := Kit.vbox(0)
		pv.alignment = BoxContainer.ALIGNMENT_CENTER
		p.add_child(pv)
		var dl := Kit.label("Day %d" % (i + 1), 13, Kit.WHITE if today_tile else Kit.MUTED, 0)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pv.add_child(dl)
		var icn := "coin"
		if r.has("gems"):
			icn = "gem"
		elif r.has("warp15"):
			icn = "clock"
		elif r.has("overclock"):
			icn = "boost"
		elif r.has("crate"):
			icn = "crate_" + r["crate"]
		var ii := Kit.icon(icn, 40)
		ii.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var got_it := i < cur or (Live.login_claimed and i == posmod(cur - 1, 7))
		if got_it and not (Live.login_claimed and i == posmod(cur - 1, 7) and cur == 0):
			ii.modulate = Color(1, 1, 1, 0.4)
		pv.add_child(ii)
		var rl := Kit.label(r["label"], 12, Kit.WHITE if today_tile else Kit.INK, 0)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pv.add_child(rl)
		g.add_child(p)
	if not Live.login_claimed:
		v.add_child(_btn("Claim today's gift", Kit.SAGE, Kit.SAGE_EDGE, func(): return Live.claim_login(), 0))
	else:
		v.add_child(_clock_label(func(): return "Next gift in %s" % Fmt.time(Live.to_midnight())))


func _quests_card() -> void:
	var v := _card("Daily quests", "calendar", "Finish all three for a Supply Crate and a Breakthrough stamp.")
	for i in Live.quests.size():
		var q: Dictionary = Live.quests[i]
		var d: Dictionary = LiveDefs.QUESTS[q["id"]]
		var qv := Kit.vbox(4)
		v.add_child(qv)
		var r := _row(d["icon"], Live.quest_text(q), Live.describe(Live.quest_reward(q)))
		qv.add_child(r)
		var idx := i
		if q["claimed"]:
			r.add_child(Kit.glyph("check", 40, Kit.SAGE))
		elif Live.quest_ready(q):
			r.add_child(_claim_btn(func(): return Live.claim_quest(idx), true))
		elif not Live.rerolled:
			var rb := _btn("", Kit.PAPER_DARK, Kit.LINE, func(): return Live.reroll(idx), 64)
			rb.set_glyph("rotate", 26)
			r.add_child(rb)
		var ph := Kit.hbox(8)
		qv.add_child(ph)
		ph.add_child(_bar(float(Live.quest_progress(q)) / maxf(1.0, int(q["n"])), 0.0, q["claimed"]))
		ph.add_child(Kit.label("%s / %s" % [Fmt.num(Live.quest_progress(q)), Fmt.num(int(q["n"]))], 14, Kit.MUTED, 0))
	# Breakthrough
	var bh := Kit.hbox(6)
	v.add_child(bh)
	bh.add_child(Kit.label("Breakthrough", 16, Kit.INK, 0))
	for i in 7:
		var s := Kit.icon("star", 32)
		s.modulate = Color.WHITE if i < Live.stamps else Color(0.6, 0.62, 0.66, 0.4)
		bh.add_child(s)
	if Live.breakthrough_ready():
		bh.add_child(_claim_btn(func(): return Live.claim_breakthrough(), true, "Open"))
	if Live.rerolled:
		v.add_child(Kit.label("You've used today's swap.", 14, Kit.MUTED, 0, false))
	v.add_child(_clock_label(func(): return "New quests in %s" % Fmt.time(Live.to_midnight())))


func _crates_card() -> void:
	var v := _card("Crates", "crate_server", "Crates unlock one at a time. Start one before you go!")
	var g := HBoxContainer.new()
	g.add_theme_constant_override("separation", 6)
	v.add_child(g)
	for i in LiveDefs.CRATE_SLOTS:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Kit.skin("card", 24, Vector4(6, 6, 6, 8)))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pv := Kit.vbox(2)
		pv.alignment = BoxContainer.ALIGNMENT_CENTER
		p.add_child(pv)
		g.add_child(p)
		if i >= Live.crates.size():
			var e := Kit.label("Empty", 14, Kit.MUTED, 0)
			e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			e.custom_minimum_size = Vector2(0, 120)
			e.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pv.add_child(e)
			continue
		var c: Dictionary = Live.crates[i]
		var ci := Kit.icon("crate_" + c["kind"], 64)
		ci.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pv.add_child(ci)
		var nm := Kit.label(LiveDefs.CRATES[c["kind"]]["name"], 12, Kit.INK, 0)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pv.add_child(nm)
		var idx := i
		match c["state"]:
			"ready":
				pv.add_child(_btn("Open!", Kit.SAGE, Kit.SAGE_EDGE, func(): return _open_crate(idx), 0))
			"unlocking":
				var cl := _clock_label(func(): return Fmt.time(Live.crate_left(idx)) if idx < Live.crates.size() else "", 13, Kit.INK)
				cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				pv.add_child(cl)
				pv.add_child(_btn(str(Live.crate_skip_price(idx)), Kit.CHARCOAL, Kit.CHARCOAL_EDGE, func(): return _open_crate(idx), 0, "gem"))
			_:
				var tl := Kit.label(Fmt.time(float(LiveDefs.CRATES[c["kind"]]["time"])), 13, Kit.MUTED, 0)
				tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				pv.add_child(tl)
				if Live.unlocking() < 0:
					pv.add_child(_btn("Unlock", Kit.BRASS, Kit.BRASS_EDGE, func(): return Live.start_unlock(idx), 0))
				else:
					pv.add_child(_btn(str(Live.crate_skip_price(idx)), Kit.GREY, Kit.GREY_EDGE, func(): return _open_crate(idx), 0, "gem"))


func _open_crate(i: int) -> Array:
	var kind: String = Live.crates[i]["kind"] if i < Live.crates.size() else "supply"
	var items := Live.open_crate(i)
	if not items.is_empty() and hud:
		hud.crate_popup(kind, items)
		return []
	return items


func _boosters_card() -> void:
	var have := false
	for b in ["warp15", "warp60", "overclock"]:
		if int(Live.boosters.get(b, 0)) > 0:
			have = true
	if not have:
		return
	var v := _card("Boosters", "boost", "Time Warps show up on a builder's job. Overclock Charges skip the cooldown.")
	for b in ["warp15", "warp60", "overclock"]:
		var n := int(Live.boosters.get(b, 0))
		if n <= 0:
			continue
		var d: Dictionary = LiveDefs.BOOSTERS[b]
		var r := _row(d["icon"], "%s  x%d" % [d["name"], n], d["desc"])
		if b == "overclock":
			r.add_child(_btn("Use", Kit.TERRACOTTA, Kit.TERRACOTTA_EDGE, func(): return Live.use_overclock(), 100))
		v.add_child(r)


# ---------------------------------------------------------------- League

func _league() -> void:
	var t := int(Live.league["tier"])
	var lg: Dictionary = LiveDefs.LEAGUES[t]
	var v := _card("%s League" % lg["name"], "shield", "Rival AI labs race for benchmark points all week. Top %d move up, bottom %d move down." % [LiveDefs.PROMOTE, LiveDefs.DEMOTE])
	((v.get_child(0) as HBoxContainer).get_child(0) as TextureRect).modulate = (lg["color"] as Color).lightened(0.15)
	v.add_child(_clock_label(func(): return "Week ends in %s" % Fmt.time(Live.league_left()), 16, Kit.INK))
	# the ten leagues
	var ladder := Kit.hbox(2)
	ladder.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(ladder)
	for i in LiveDefs.LEAGUES.size():
		var s := Kit.icon("shield", 40 if i == t else 28)
		s.modulate = (LiveDefs.LEAGUES[i]["color"] as Color) if i <= t else Color(0.6, 0.62, 0.66, 0.35)
		ladder.add_child(s)
	if not Live.league["joined"]:
		v.add_child(Kit.label("Earn points to join this week's league: serve tokens, finish quests, upgrade, hit your daily goal.", 15, Kit.TERRACOTTA_EDGE, 0, false))
		(v.get_child(v.get_child_count() - 1) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	var rows := Live.standings()
	var tv := _card("", "")
	for i in rows.size():
		var r: Dictionary = rows[i]
		if i == LiveDefs.PROMOTE and t < LiveDefs.LEAGUES.size() - 1:
			tv.add_child(_zone("Promotion zone ↑", Kit.SAGE))
		if i == LiveDefs.LEAGUE_SIZE - LiveDefs.DEMOTE and t > 0:
			tv.add_child(_zone("Demotion zone ↓", Kit.TERRACOTTA))
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Kit.box(Color(1.0, 0.92, 0.7) if r["me"] else Color(0, 0, 0, 0), 12))
		var h := Kit.hbox(10)
		p.add_child(h)
		var rk := Kit.game(str(i + 1), 20, Kit.BRASS_EDGE if i < 3 else Kit.INK, 0)
		rk.custom_minimum_size.x = 36
		h.add_child(rk)
		var dot := Panel.new()
		dot.add_theme_stylebox_override("panel", Kit.box(r["color"], 15))
		dot.custom_minimum_size = Vector2(30, 30)
		h.add_child(dot)
		var nm := Kit.label(r["name"] + ("  (you)" if r["me"] else ""), 17, Kit.INK, 0)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nm)
		h.add_child(Kit.label("%d pts" % int(r["points"]), 16, Kit.MUTED, 0))
		tv.add_child(p)
	if not Live.league_history.is_empty():
		var hv := _card("Past weeks", "trophy")
		for i in range(Live.league_history.size() - 1, maxi(-1, Live.league_history.size() - 6), -1):
			var e: Dictionary = Live.league_history[i]
			var mv: String = ["stayed", "promoted", "relegated"][int(e["move"]) if int(e["move"]) >= 0 else 2]
			hv.add_child(Kit.label("#%d in %s  ·  %d pts  ·  %s" % [int(e["rank"]), LiveDefs.LEAGUES[int(e["tier"])]["name"], int(e["points"]), mv], 15, Kit.MUTED, 0, false))


func _zone(text: String, c: Color) -> Control:
	var l := Kit.label(text, 14, c, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


# ---------------------------------------------------------------- Pass

func _pass() -> void:
	var tier := Live.pass_tier()
	var sp := int(Live.season["sp"])
	var v := _card("Lab Pass: " + Live.season_name(), "pass", "Quests, daily goals and events earn Pass points. Every %d points is a tier." % LiveDefs.PASS_TIER_SP)
	v.add_child(_clock_label(func(): return "Season ends in %s" % Fmt.time(Live.season_left()), 16, Kit.INK))
	var ph := Kit.hbox(8)
	v.add_child(ph)
	ph.add_child(Kit.game("Tier %d" % tier, 22, Kit.INK, 0))
	ph.add_child(_bar(float(sp % LiveDefs.PASS_TIER_SP) / LiveDefs.PASS_TIER_SP if tier < LiveDefs.PASS_TIERS else 1.0))
	ph.add_child(Kit.label("%d pts" % sp, 15, Kit.MUTED, 0))
	if not Live.season["premium"]:
		var pr := _row("pass", "Premium track", "More rewards on every tier, a Hologram Assistant at tier 15 and a Lab Crate at the end.")
		pr.add_child(_btn(str(LiveDefs.PASS_PRICE), Kit.BRASS, Kit.BRASS_EDGE, func(): return Live.buy_premium(), 130, "gem"))
		v.add_child(pr)
	var lv := _card("", "")
	var head := Kit.hbox(8)
	lv.add_child(head)
	var a := Kit.label("Tier", 14, Kit.MUTED, 0)
	a.custom_minimum_size.x = 50
	head.add_child(a)
	var b := Kit.label("Free", 14, Kit.MUTED, 0)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(b)
	var c := Kit.label("Premium", 14, Kit.BRASS_EDGE, 0)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(c)
	for i in LiveDefs.PASS_TIERS:
		var h := Kit.hbox(8)
		lv.add_child(h)
		var n := Kit.game(str(i + 1), 20, Kit.INK if i < tier else Kit.MUTED, 0)
		n.custom_minimum_size.x = 50
		h.add_child(n)
		for prem in [false, true]:
			h.add_child(_pass_cell(i, prem))


func _pass_cell(i: int, prem: bool) -> Control:
	var r := LiveDefs.pass_reward(i, prem)
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", Kit.skin("card", 20, Vector4(8, 6, 8, 6)))
	var h := Kit.hbox(6)
	p.add_child(h)
	var icn := "coin"
	if r.has("decor"):
		icn = Defs.BUILDINGS[r["decor"]]["icon"]
	elif r.has("crate"):
		icn = "crate_" + r["crate"]
	elif r.has("gems"):
		icn = "gem"
	elif r.has("warp15") or r.has("warp60"):
		icn = "clock"
	var ic := Kit.icon(icn, 34)
	h.add_child(ic)
	var l := Kit.label(Live.describe(r), 13, Kit.INK, 0, false)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 80
	h.add_child(l)
	var claimed := (Live.season["prem" if prem else "free"] as Array).has(i)
	if claimed:
		h.add_child(Kit.glyph("check", 28, Kit.SAGE))
	elif Live.pass_claimable(i, prem):
		h.add_child(_claim_btn(func(): return Live.claim_pass(i, prem), true, "Get"))
	elif prem and not Live.season["premium"]:
		h.add_child(Kit.glyph("lock", 24, Kit.MUTED))
		ic.modulate = Color(1, 1, 1, 0.5)
	elif i >= Live.pass_tier():
		ic.modulate = Color(1, 1, 1, 0.5)
	return p


# ---------------------------------------------------------------- Events

func _events() -> void:
	var act := Live.active_events()
	for id in act:
		var d: Dictionary = LiveDefs.EVENTS[id]
		var desc: String = d["desc"]
		if id == "spotlight":
			desc = "%s sells for 3x right now." % Defs.recipe(Live.spotlight_model())["name"]
		var v := _card(d["name"] + "  ·  live now", d["icon"], desc)
		var w := Live.event_window(id)
		v.add_child(_clock_label(func(): return "Ends in %s" % Fmt.time(float(int(w[1]) - Live.local())) if not w.is_empty() else "", 16, Kit.TERRACOTTA_EDGE))
		if id == "community":
			var l: Array = Live.event_quests["list"]
			for i in l.size():
				var q: Dictionary = l[i]
				var qd: Dictionary = LiveDefs.QUESTS[q["id"]]
				var r := _row(qd["icon"], Live.quest_text(q), "%s / %s  ·  %s" % [Fmt.num(Live.quest_progress(q)), Fmt.num(int(q["n"])), Live.describe(Live.quest_reward(q))])
				var idx := i
				if q["claimed"]:
					r.add_child(Kit.glyph("check", 36, Kit.SAGE))
				else:
					r.add_child(_claim_btn(func(): return Live.claim_event_quest(idx), Live.event_quest_ready(idx)))
				v.add_child(r)
	var up := _card("Coming up", "calendar", "Events run on your local clock, and every lab sees the same ones.")
	var lt := Live.local()
	var next := []
	for id in LiveDefs.EVENT_ORDER:
		if act.has(id):
			continue
		var w2 := LiveDefs.event_window(id, lt)
		if not w2.is_empty():
			next.append([int(w2[0]), id])
	next.sort()
	for e in next:
		var d2: Dictionary = LiveDefs.EVENTS[e[1]]
		var start := int(e[0])
		var r2 := _row(d2["icon"], d2["name"], d2["desc"])
		var tv := Kit.vbox(0)
		tv.add_child(Kit.label(_when(start), 14, Kit.INK, 0))
		tv.add_child(_clock_label(func(): return "in " + Fmt.time(float(start - Live.local())), 13))
		r2.add_child(tv)
		up.add_child(r2)


# ---------------------------------------------------------------- Album

func _album() -> void:
	var v := _card("Badges", "trophy", "Each badge has five tiers, each with sparks.")
	for id in LiveDefs.BADGE_ORDER:
		var d: Dictionary = LiveDefs.BADGES[id]
		var t := Live.badge_tier(id)
		var claimed := int(Live.badges.get(id, 0))
		var tiers: Array = d["tiers"]
		var next_i := mini(t, tiers.size() - 1)
		var sub := "Tier %s  ·  %s" % [LiveDefs.TIER_NAMES[t - 1] if t > 0 else "-", Live.badge_text(id, next_i) if t < tiers.size() else "All tiers done!"]
		var r := _row(d["icon"], d["name"], sub)
		var stars := Kit.hbox(0)
		for i in 5:
			stars.add_child(Kit.glyph("star", 18, Kit.BRASS if i < t else Kit.LINE))
		(r.get_child(1) as VBoxContainer).add_child(stars)
		if t < tiers.size():
			var f := Live.badge_value(id) / float(tiers[next_i])
			(r.get_child(1) as VBoxContainer).add_child(_bar(f, 220))
		if t > claimed:
			r.add_child(_claim_btn(func(): return Live.claim_badge(id), true, "+%d" % LiveDefs.BADGE_GEMS[claimed]))
		v.add_child(r)
	var mv := _card("Model mastery", "recipe", "Serve a model's tokens for mastery stars: sparks, and +%d%% on its price per star." % roundi(LiveDefs.MASTERY_PRICE * 100))
	for r in Defs.RECIPES:
		var rid: String = r["id"]
		var known := Game.known_recipes.has(rid)
		var s := Live.stars(rid)
		var served := int(Live.mastery.get(rid, 0))
		var next_t: int = LiveDefs.MASTERY[mini(s, LiveDefs.MASTERY.size() - 1)]
		var row := _row("tk_" + rid, r["name"] if known else "???", ("%s tokens served  ·  next star at %s" % [Fmt.num(served), Fmt.num(next_t)]) if known else "Not served yet", Color.WHITE if known else Color(0, 0, 0, 0.45))
		var st := Kit.hbox(0)
		for i in 4:
			st.add_child(Kit.glyph("star", 18, Kit.BRASS if i < s else Kit.LINE))
		(row.get_child(1) as VBoxContainer).add_child(st)
		if Live.mastery_claimable(rid):
			row.add_child(_claim_btn(func(): return Live.claim_mastery(rid), true, "+%d" % LiveDefs.MASTERY_GEMS[int(Live.mastery_claimed.get(rid, 0))]))
		mv.add_child(row)


# ---------------------------------------------------------------- Me

func _me() -> void:
	var v := _card(Live.profile["name"], "profile", "Lab level %d  ·  %s League  ·  %d-day streak" % [Game.level, Live.league_name(), Live.streak])
	var nh := Kit.hbox(8)
	v.add_child(nh)
	var le := LineEdit.new()
	le.text = Live.profile["name"]
	le.max_length = 24
	le.placeholder_text = "Your lab's name"
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.add_theme_font_size_override("font_size", 20)
	nh.add_child(le)
	nh.add_child(_btn("Rename", Kit.SAGE, Kit.SAGE_EDGE, func():
		Live.set_lab_name(le.text)
		return true, 120))
	var cols := Kit.hbox(6)
	v.add_child(cols)
	cols.add_child(Kit.label("Logo", 15, Kit.MUTED, 0))
	for i in 8:
		var c := LiveDefs.rival_color(i * 997 + 11)
		var b := Button.new()
		b.custom_minimum_size = Vector2(40, 40)
		b.flat = true
		var sb := Kit.box(c, 20, 4 if int(Live.profile.get("logo", 0)) == i else 0, Kit.INK)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		var idx := i
		b.pressed.connect(func():
			Live.profile["logo"] = idx
			Live.save_live()
			Sfx.play("click")
			_dirty = true)
		cols.add_child(b)
	# friends
	var fv := _card("Friends", "hire", "Share your code. A friend who enters it gets a welcome gift.")
	var ch := Kit.hbox(8)
	fv.add_child(ch)
	var code := Kit.game(Live.friend_code(), 24, Kit.INK, 0)
	code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch.add_child(code)
	ch.add_child(_btn("Copy", Kit.CHARCOAL, Kit.CHARCOAL_EDGE, func():
		DisplayServer.clipboard_set(Live.friend_code())
		if hud:
			hud.toast("Code copied", "hire")
		return true, 100))
	fv.add_child(_btn("Invite friends", Kit.SAGE, Kit.SAGE_EDGE, func(): return Share.invite(hud), 0, "share"))
	if str(Live.profile.get("referral", "")) == "":
		var rh := Kit.hbox(8)
		fv.add_child(rh)
		var re := LineEdit.new()
		re.placeholder_text = "TKN-XXXXXXXX-XXXX"
		re.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		re.add_theme_font_size_override("font_size", 18)
		rh.add_child(re)
		rh.add_child(_btn("Redeem", Kit.BRASS, Kit.BRASS_EDGE, func():
			var err := Live.redeem(re.text)
			if hud:
				hud.toast(err if err != "" else "Gift in your inbox!", "gift")
			return err == "", 120))
	# share
	var sv := _card("Show off your lab", "share", "Saves a picture of your lab with its stats, ready to post.")
	sv.add_child(_btn("Share a snapshot", Kit.BRASS, Kit.BRASS_EDGE, func(): return Share.snapshot(hud), 0, "share"))
	# stats
	var st := _card("Lab records", "star")
	var s: Dictionary = Game.stats
	var joined := Time.get_date_string_from_unix_time(int(Live.profile.get("joined", 0)))
	for line in ["Tokens served: %s" % Fmt.num(int(s["tokens"])), "Money earned: $%s" % Fmt.num(float(s["earned"])),
			"Best streak: %d days" % Live.streak_best, "Best league: %s" % LiveDefs.LEAGUES[int(Live.league["best"])]["name"],
			"Quests finished: %d" % int(Live.counters.get("quests", 0)), "Crates opened: %d" % int(Live.counters.get("crates", 0)),
			"Models served: %d / %d" % [Game.known_recipes.size(), Defs.RECIPES.size()], "Time played: %s" % Fmt.time(float(s["play_time"])),
			"Lab founded: %s" % joined]:
		st.add_child(Kit.label(line, 16, Kit.MUTED, 0, false))
	_reminders()


func _reminders() -> void:
	var v := _card("Reminders", "mail", "A few friendly nudges when something is ready. Never between 22:00 and 08:00 unless you say so.")
	v.add_child(_switch("Reminders", Live.notify.get("on", true), func(on): Live.notify["on"] = on))
	v.add_child(_switch("Quiet hours (22:00-08:00)", Live.notify.get("quiet", true), func(on): Live.notify["quiet"] = on))
	var names := {"builders": "Builders finished", "crate": "Crates unlocked", "offline": "Earnings full", "streak": "Streak reminders",
		"quests": "New daily quests", "event": "Events starting", "league": "League week ending", "comeback": "Miss-you notes"}
	for c in names:
		v.add_child(_switch(names[c], (Live.notify["cats"] as Dictionary).get(c, true), func(on): Live.notify["cats"][c] = on, 15))
	if OS.has_feature("web"):
		var p := Notifier.poll_permission()
		if p == "default" or p == "pending":
			v.add_child(_btn("Allow browser notifications", Kit.SAGE, Kit.SAGE_EDGE, func():
				Notifier.request_permission()
				return true, 0))
		elif p == "denied":
			v.add_child(Kit.label("Notifications are blocked in your browser settings.", 14, Kit.TERRACOTTA_EDGE, 0, false))
		elif p == "unsupported":
			v.add_child(Kit.label("This browser can't show notifications.", 14, Kit.MUTED, 0, false))
	var pv := Notifier.preview()
	if not pv.is_empty():
		v.add_child(Kit.label("If you left now:", 15, Kit.INK, 0))
		for e in pv:
			v.add_child(Kit.label("in %s  ·  %s" % [e[0], e[1]], 14, Kit.MUTED, 0, false))


func _switch(text: String, on: bool, apply: Callable, size := 18) -> Control:
	var h := Kit.hbox(8)
	var l := Kit.label(text, size, Kit.INK, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b := Kit.juicy("On" if on else "Off", Kit.GREEN if on else Kit.GREY, Kit.GREEN_EDGE if on else Kit.GREY_EDGE, 16, Vector2(90, 46))
	var state := [on]
	b.pressed.connect(func():
		state[0] = not state[0]
		apply.call(state[0])
		b.set_text_value("On" if state[0] else "Off")
		b.set_colors(Kit.GREEN if state[0] else Kit.GREY, Kit.GREEN_EDGE if state[0] else Kit.GREY_EDGE)
		Live.save_live())
	h.add_child(b)
	return h
