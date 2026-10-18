extends Node
## Dev: prints worker states and building contents every few seconds.

var world: World
var _t := 0.0


func _process(dt: float) -> void:
	_t += dt
	if world == null:
		world = get_tree().current_scene.get("world")
		return
	if fmod(_t, 4.0) < dt:
		var s := "t=%.0f $%s tokens=%d |" % [_t, Fmt.num(Game.money), int(Game.stats["tokens"])]
		for w in world.workers.values():
			s += " %s:%s(%d)" % [w.role, Worker.S.keys()[w.state], w.carry.count()]
		print(s)
		for n in world.bnodes.values():
			var parts := []
			for p in n.ports:
				parts.append("%s%d" % [p["dir"], (p["holder"] as Holder).count()])
			print("   %s %s" % [n.name, " ".join(parts)])
