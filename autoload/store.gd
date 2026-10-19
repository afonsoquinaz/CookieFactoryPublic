extends Node
## The sparks shop: real-money spark packs, a one-time Starter Pack, and the
## Spark Exchange (in-game money for sparks, dearer with every trade today).
##
## Payments go through the platform's store, never through the game:
##   Android  the Google Play Billing plugin (Engine singleton
##            "GodotGooglePlayBilling", add it to the Android export)
##   iOS      StoreKit through the InAppStore plugin (singleton "InAppStore")
## Anywhere else (desktop, the web demo) there is no store: the shop says so
## and only the Spark Exchange works. Product ids are the PACKS ids below;
## create the same ids (consumables, plus "starter" as a one-time
## consumable) in Play Console and App Store Connect.
## Sparks are granted when the store reports a completed purchase; a
## production release should also check receipts on a server.
## `sandbox` (debug builds, tests) completes purchases at once, for free.

signal changed
signal purchased(id: String, reward: Dictionary)
signal failed(id: String, why: String)

const PACKS := [
	{"id": "sparks_80", "gems": 80, "usd": "$0.99", "tag": ""},
	{"id": "sparks_500", "gems": 500, "usd": "$4.99", "tag": "+25%"},
	{"id": "sparks_1200", "gems": 1200, "usd": "$9.99", "tag": "Popular"},
	{"id": "sparks_2600", "gems": 2600, "usd": "$19.99", "tag": "+60%"},
	{"id": "sparks_7000", "gems": 7000, "usd": "$49.99", "tag": "Best value"},
]
const STARTER := {"id": "starter", "usd": "$2.99", "reward": {"gems": 400, "warp60": 3, "crate": "lab"}}
## Spark Exchange: 10 sparks for about 15 minutes of income, x1.8 per trade
## today, five trades a day.
const EXCHANGE_GEMS := 10
const EXCHANGE_SECONDS := 900.0
const EXCHANGE_GROWTH := 1.8
const EXCHANGE_MAX := 5

var backend := ""                # "play" | "appstore" | "" (no store)
var connected := false               # the store answered and products are known
var sandbox := false
var prices := {}                 # product id -> localized price text
var starter_bought := false
var exchange_day := -1
var exchange_n := 0
var bought := []                 # [{id, t}] receipts of what was granted
var _play: Object
var _ios: Object
var _pending := {}               # Play purchase tokens being consumed -> id


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sandbox = OS.is_debug_build() and OS.get_cmdline_user_args().has("--store-sandbox")
	if Engine.has_singleton("GodotGooglePlayBilling"):
		_play = Engine.get_singleton("GodotGooglePlayBilling")
		backend = "play"
		_connect_play()
	elif Engine.has_singleton("InAppStore"):
		_ios = Engine.get_singleton("InAppStore")
		backend = "appstore"
		_ios.call("set_auto_finish_transaction", true)
		_ios.call("request_product_info", {"product_ids": product_ids()})


func reset_state() -> void:
	starter_bought = false
	exchange_day = -1
	exchange_n = 0
	bought = []


func product_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for p in PACKS:
		out.append(p["id"])
	out.append(STARTER["id"])
	return out


## Whether real-money purchases can happen here.
func available() -> bool:
	return sandbox or (backend != "" and connected)


## Why the shop can't sell sparks right now ("" when it can).
func unavailable_reason() -> String:
	if available():
		return ""
	if backend == "":
		return "Spark packs are sold in the Android and iPhone apps. Here, trade money for sparks at the Spark Exchange."
	return "Connecting to the %s..." % ("Play Store" if backend == "play" else "App Store")


func price_text(id: String) -> String:
	if prices.has(id):
		return prices[id]
	for p in PACKS:
		if p["id"] == id:
			return p["usd"]
	return STARTER["usd"] if id == STARTER["id"] else ""


func pack(id: String) -> Dictionary:
	for p in PACKS:
		if p["id"] == id:
			return p
	return {}


func reward_of(id: String) -> Dictionary:
	if id == STARTER["id"]:
		return STARTER["reward"]
	var p := pack(id)
	return {"gems": int(p["gems"])} if not p.is_empty() else {}


## Starts buying a product. The reward arrives with `purchased`.
func buy(id: String) -> bool:
	if reward_of(id).is_empty() or (id == STARTER["id"] and starter_bought):
		return false
	if sandbox:
		_grant(id)
		return true
	if not available():
		failed.emit(id, unavailable_reason())
		return false
	match backend:
		"play":
			_play.call("purchase", id)
		"appstore":
			_ios.call("purchase", {"product_id": id})
	return true


func _grant(id: String) -> void:
	var r := reward_of(id)
	if r.is_empty():
		return
	if id == STARTER["id"]:
		if starter_bought:
			return
		starter_bought = true
	bought.append({"id": id, "t": int(Time.get_unix_time_from_system())})
	Live.grant(r)
	Game.track("purchases")
	purchased.emit(id, r)
	changed.emit()
	Game.save_game()


# ---------------------------------------------------------------- Spark Exchange

func _today() -> int:
	return Live.today()


func exchange_left() -> int:
	if exchange_day != _today():
		return EXCHANGE_MAX
	return maxi(0, EXCHANGE_MAX - exchange_n)


func exchange_price() -> float:
	var n := exchange_n if exchange_day == _today() else 0
	var base := maxf(500.0, Live.ref_income * EXCHANGE_SECONDS)
	return LiveDefs.snap(base * pow(EXCHANGE_GROWTH, n))


func exchange() -> bool:
	if exchange_left() <= 0 or not Game.spend(exchange_price()):
		return false
	if exchange_day != _today():
		exchange_day = _today()
		exchange_n = 0
	exchange_n += 1
	Game.add_gems(EXCHANGE_GEMS)
	Game.track("exchanges")
	changed.emit()
	return true


# ---------------------------------------------------------------- saving

func to_dict() -> Dictionary:
	return {"starter": starter_bought, "xday": exchange_day, "xn": exchange_n, "bought": bought.slice(-50)}


func from_dict(d: Dictionary) -> void:
	starter_bought = bool(d.get("starter", false))
	exchange_day = int(d.get("xday", -1))
	exchange_n = int(d.get("xn", 0))
	bought = d.get("bought", [])


# ---------------------------------------------------------------- Google Play

func _connect_play() -> void:
	for sig in [["connected", _on_play_connected], ["disconnected", _on_play_disconnected],
			["product_details_query_completed", _on_play_details], ["query_product_details_response", _on_play_details_dict],
			["purchases_updated", _on_play_purchases], ["purchase_error", _on_play_error],
			["purchase_consumed", _on_play_consumed]]:
		if _play.has_signal(sig[0]):
			_play.connect(sig[0], sig[1])
	_play.call("startConnection")


func _on_play_connected() -> void:
	connected = true
	if _play.has_method("querySkuDetails"):
		_play.call("querySkuDetails", product_ids(), "inapp")
	elif _play.has_method("queryProductDetails"):
		_play.call("queryProductDetails", product_ids(), "inapp")
	# purchases made while the game was closed
	if _play.has_method("queryPurchases"):
		var res = _play.call("queryPurchases", "inapp")
		if res is Dictionary and res.has("purchases"):
			_on_play_purchases(res["purchases"])
	changed.emit()


func _on_play_disconnected() -> void:
	connected = false
	changed.emit()
	get_tree().create_timer(10.0).timeout.connect(func(): _play.call("startConnection"))


func _on_play_details(details: Array) -> void:
	for d in details:
		var id := str(d.get("sku", d.get("product_id", d.get("id", ""))))
		var p := str(d.get("price", d.get("formatted_price", "")))
		if id != "" and p != "":
			prices[id] = p
	changed.emit()


func _on_play_details_dict(res: Dictionary) -> void:
	_on_play_details(res.get("product_details", res.get("details", [])))


func _on_play_purchases(purchases: Array) -> void:
	for p in purchases:
		var state := int(p.get("purchase_state", 1))
		if state != 1:
			continue                 # pending (e.g. cash payments): granted when it completes
		var token := str(p.get("purchase_token", ""))
		var ids: Array = p.get("products", p.get("skus", [p.get("sku", "")]))
		if token == "" or ids.is_empty():
			continue
		_pending[token] = str(ids[0])
		_play.call("consumePurchase", token)


## Consuming confirms the purchase with Google; then the reward is granted
## (so a purchase is never granted twice, or lost).
func _on_play_consumed(token: String) -> void:
	if _pending.has(token):
		_grant(_pending[token])
		_pending.erase(token)


func _on_play_error(code: int, msg: String) -> void:
	if code != 1:                    # 1 = the player cancelled
		failed.emit("", "The Play Store said: %s" % msg)


# ---------------------------------------------------------------- App Store

func _process(_dt: float) -> void:
	if _ios == null:
		return
	while int(_ios.call("get_pending_event_count")) > 0:
		var e: Dictionary = _ios.call("pop_pending_event")
		match str(e.get("type", "")):
			"product_info":
				if str(e.get("result", "")) == "ok":
					connected = true
					var ids: Array = e.get("ids", [])
					var ps: Array = e.get("localized_prices", e.get("prices", []))
					for i in mini(ids.size(), ps.size()):
						prices[str(ids[i])] = str(ps[i])
					changed.emit()
			"purchase":
				if str(e.get("result", "")) == "ok":
					_grant(str(e.get("product_id", "")))
				elif str(e.get("result", "")) == "error":
					failed.emit(str(e.get("product_id", "")), "The App Store couldn't complete the purchase.")
