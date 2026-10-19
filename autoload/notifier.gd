extends Node
## Reminders for when you're away, Duolingo style: few, useful, friendly.
## plan() turns the game's state into a short list of reminders (builders
## done, a crate unlocked, earnings at their cap, a streak about to end,
## fresh quests, an event starting, the League week ending), moved out of
## quiet hours and kept to at most one per kind. They're handed to the
## platform when the game goes to the background and cancelled when it
## comes back:
##   web      the browser's Notification API (after you allow it in
##            Settings); fires while the tab stays open in the background
##   Android  a local-notification plugin, if the export has one (a
##   / iOS    singleton named "LocalNotification" with show(), cancel_all())
## Desktop builds have no reminders; the Today tab shows what's waiting.

const MAX := 6

var _scheduled: Array = []
var permission := "default"                 # web: default | granted | denied | unsupported


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		var p = JavaScriptBridge.eval("typeof Notification === 'undefined' ? 'unsupported' : Notification.permission", true)
		permission = str(p) if p != null else "unsupported"


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			schedule()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			cancel()


func enabled() -> bool:
	return bool(Live.notify.get("on", true))


func category_on(c: String) -> bool:
	return enabled() and bool((Live.notify.get("cats", {}) as Dictionary).get(c, true))


## Asks the browser for permission (from a button press).
func request_permission() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		if (typeof Notification !== 'undefined') {
			Notification.requestPermission().then(function (p) { window.__tknPerm = p; });
		}
	""", true)
	permission = "pending"


## Re-reads the browser's answer (call now and then while a panel is open).
func poll_permission() -> String:
	if OS.has_feature("web"):
		var p = JavaScriptBridge.eval("typeof Notification === 'undefined' ? 'unsupported' : Notification.permission", true)
		if p != null:
			permission = str(p)
	elif Engine.has_singleton("LocalNotification"):
		permission = "granted"
	else:
		permission = "unsupported"
	return permission


# ---------------------------------------------------------------- the plan

## The reminders to send if the player left now: [{at, cat, title, body}]
## (at = unix time), soonest first.
func plan(t0 := -1) -> Array:
	if t0 < 0:
		t0 = Live.now()
	var out := []
	var bias := Live.local(t0) - t0
	var lt0 := t0 + bias
	var today := int(floor(lt0 / 86400.0))
	# builders: when the last running job ends (one reminder for all)
	if not Game.jobs.is_empty():
		var last := 0.0
		var what := ""
		for j in Game.jobs:
			var left := Game.job_left(j)
			if left > last:
				last = left
				what = _job_name(j)
		if last > 120.0:
			out.append(_make("builders", t0 + int(last), {"what": what if Game.jobs.size() == 1 else "Every job"}))
	# a crate finishing
	var ci := Live.unlocking()
	if ci >= 0:
		var left2 := Live.crate_left(ci)
		if left2 > 60.0:
			out.append(_make("crate", t0 + int(left2), {"what": LiveDefs.CRATES[Live.crates[ci]["kind"]]["name"]}))
	# earnings reaching their cap
	if Game.recent_income() > 0.0:
		out.append(_make("offline", t0 + int(Bal.offline_cap_hours() * 3600.0), {}))
	# the streak, at 19:30 if today's goal isn't done yet
	if Live.streak > 0 and not Live.goal_is_done:
		var at := today * 86400 + 19 * 3600 + 1800 - bias
		if at > t0 + 600:
			out.append(_make("streak", at, {"n": Live.streak}))
	elif Live.streak > 0:
		# done today: remind tomorrow evening instead
		out.append(_make("streak", (today + 1) * 86400 + 19 * 3600 + 1800 - bias, {"n": Live.streak}))
	# tomorrow's quests at 9:00
	out.append(_make("quests", (today + 1) * 86400 + 9 * 3600 - bias, {}))
	# the next Spotlight Hour or Community Day, 10 minutes before
	for id in ["community", "spotlight"]:
		var w := LiveDefs.event_window(id, lt0)
		if not w.is_empty() and int(w[0]) - 600 > lt0:
			out.append(_make("event", int(w[0]) - 600 - bias, {"what": LiveDefs.EVENTS[id]["name"], "desc": LiveDefs.EVENTS[id]["desc"]}))
	# the League week ending: Sunday 18:00 if you're in it
	if Live.league["joined"]:
		var end := Live.week_start(int(Live.league["week"]) + 1) * 86400 - 6 * 3600 - bias
		if end > t0 + 600:
			out.append(_make("league", end, {"n": Live.my_rank(), "what": Live.league_name()}))
	# three days away: a gentle comeback note
	out.append(_make("comeback", t0 + 3 * 86400, {}))
	var kept := []
	var seen := {}
	out.sort_custom(func(a, b): return a["at"] < b["at"])
	for n in out:
		if seen.has(n["cat"]) or not category_on(n["cat"]):
			continue
		n["at"] = _out_of_quiet(int(n["at"]), bias)
		seen[n["cat"]] = true
		kept.append(n)
		if kept.size() >= MAX:
			break
	kept.sort_custom(func(a, b): return a["at"] < b["at"])
	return kept


func _job_name(j: Dictionary) -> String:
	if j["type"] == "clear":
		return "Clearing"
	var b := Game.building(int(j["uid"]))
	if b.is_empty():
		return "A job"
	var nm: String = Defs.BUILDINGS[b["kind"]]["name"]
	return ("The " + nm) if j["type"] == "build" else ("The %s upgrade" % nm)


## A reminder of a kind with its text filled in (a variation picked by time).
func _make(cat: String, at: int, vars: Dictionary) -> Dictionary:
	var opts: Array = LiveDefs.COPY[cat]
	var pick: Array = opts[absi(int(at / 3600)) % opts.size()]
	return {"at": at, "cat": cat, "title": _fill(pick[0], vars), "body": _fill(pick[1], vars)}


static func _fill(s: String, vars: Dictionary) -> String:
	for k in vars:
		s = s.replace("{%s}" % k, str(vars[k]))
	return s


## Moves a reminder out of quiet hours (22:00-08:00 local) to 08:00.
func _out_of_quiet(at: int, bias: int) -> int:
	if not bool(Live.notify.get("quiet", true)):
		return at
	var lt := at + bias
	var h := float(posmod(lt, 86400)) / 3600.0
	if h >= LiveDefs.QUIET_START:
		return (int(floor(lt / 86400.0)) + 1) * 86400 + LiveDefs.QUIET_END * 3600 - bias
	if h < LiveDefs.QUIET_END:
		return int(floor(lt / 86400.0)) * 86400 + LiveDefs.QUIET_END * 3600 - bias
	return at


# ---------------------------------------------------------------- platforms

func schedule() -> void:
	cancel()
	if not enabled():
		return
	var t0 := Live.now()
	_scheduled = plan(t0)
	if OS.has_feature("web") and permission == "granted":
		var js := "window.__tknTimers = window.__tknTimers || [];"
		for n in _scheduled:
			var ms := maxi(1000, (int(n["at"]) - t0) * 1000)
			if ms > 2147000000:
				continue
			js += "window.__tknTimers.push(setTimeout(function(){ try { new Notification(%s, {body: %s, icon: 'index.144x144.png', tag: %s}); } catch (e) {} }, %d));" % [JSON.stringify(n["title"]), JSON.stringify(n["body"]), JSON.stringify("tkn-" + n["cat"]), ms]
		JavaScriptBridge.eval(js, true)
	elif Engine.has_singleton("LocalNotification"):
		var ln = Engine.get_singleton("LocalNotification")
		var tag := 1
		for n in _scheduled:
			ln.show(n["body"], n["title"], maxi(1, int(n["at"]) - t0), tag)
			tag += 1


func cancel() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(window.__tknTimers || []).forEach(clearTimeout); window.__tknTimers = [];", true)
	elif Engine.has_singleton("LocalNotification"):
		var ln = Engine.get_singleton("LocalNotification")
		if ln.has_method("cancel_all"):
			ln.cancel_all()
	_scheduled = []


## What would be sent, for the Settings preview: [[when text, title], ...]
func preview() -> Array:
	var out := []
	var t0 := Live.now()
	for n in plan(t0):
		out.append([Fmt.time(float(int(n["at"]) - t0)), n["title"]])
	return out
