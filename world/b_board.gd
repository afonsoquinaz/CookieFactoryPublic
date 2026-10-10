class_name BoardB
extends Building
## The Order Board: special orders pinned on a notice board ("40 Sugar
## Cookies"). Deliver them on its pad for a big cash reward and gems.

var inbox: Holder
var _rows: Array[Node3D] = []


func _build() -> void:
	inbox = Holder.new().setup(999, [], Holder.Layout.NONE)
	inbox.accept_fn = func(t): return Game.wanted_items().has(t)
	inbox.position = Vector3(0, 1.2, -0.5)
	add_child(inbox)
	inbox.landed.connect(_on_landed)
	add_port(inbox, null, "in")
	Game.orders_changed.connect(_refresh_rows)
	Game.refill_orders()
	_refresh_rows.call_deferred()


func solid_rects() -> Array[Rect2]:
	return [Rect2(-2.0, -1.0, 4.0, 0.75)]


func _visual(root: Node3D, _t: int) -> void:
	Mats.inst(MeshKit.cached("board", BoardB.mesh), root)


func _on_landed(t: String) -> void:
	inbox.take(t)
	Game.deliver(t)
	bump(0.03)


func need(t: String) -> float:
	return 0.55 if Game.wanted_items().has(t) else 0.0


func _refresh_rows() -> void:
	for r in _rows:
		r.queue_free()
	_rows.clear()
	var i := 0
	for o in Game.orders:
		var n := Node3D.new()
		n.position = Vector3(-1.1 + (i % 2) * 2.2 * 0.5 + 0.55 * 0, 2.3 - (i / 2) * 0.62, -0.55)
		n.position = Vector3(-0.85 + (i % 2) * 1.7, 2.35 - (i / 2) * 0.62, -0.5)
		add_child(n)
		var ic := UI3D.icon(Defs.item_icon(o["item"]), 0.0017)
		ic.position = Vector3(-0.35, 0, 0)
		n.add_child(ic)
		var l := UI3D.label("%d/%d" % [int(o["got"]), int(o["count"])], 26)
		l.position = Vector3(0.2, 0, 0)
		n.add_child(l)
		_rows.append(n)
		i += 1


func status() -> String:
	return "Deliver orders here for cash and gems."


func info() -> Array:
	var out := []
	for o in Game.orders:
		out.append([Defs.item_icon(o["item"]), "%s  %d/%d  ->  $%s + %d gems" % [Defs.item_name(o["item"]), int(o["got"]), int(o["count"]), Fmt.num(o["reward"]), int(o["gems"])]])
	return out


static func mesh() -> Mesh:
	var k := MeshKit.new()
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.14, 2.9, 0.14), 0.03, Pal.WOOD_DARK, MeshKit.at(sx * 1.55, 1.45, -0.55))
	k.rbox(Vector3(3.2, 1.5, 0.12), 0.05, Pal.WOOD, MeshKit.at(0, 2.1, -0.6))
	k.rbox(Vector3(3.0, 1.32, 0.13), 0.04, Color(0.78, 0.64, 0.46), MeshKit.at(0, 2.1, -0.6))
	k.rbox(Vector3(3.5, 0.12, 0.4), 0.03, Pal.TERRACOTTA, MeshKit.at(0, 2.95, -0.6))
	for i in 4:
		k.rbox(Vector3(1.2, 0.5, 0.02), 0.01, Color(0.98, 0.96, 0.9), MeshKit.xf(Vector3(-0.85 + (i % 2) * 1.7, 2.35 - (i / 2) * 0.62, -0.53), Vector3(0, 0, (i - 1.5) * 2.0)))
		k.sphere(0.03, Pal.TERRACOTTA, MeshKit.at(-0.85 + (i % 2) * 1.7, 2.58 - (i / 2) * 0.62, -0.51), 5, 3)
	return k.commit()
