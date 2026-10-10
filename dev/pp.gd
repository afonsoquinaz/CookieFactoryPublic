extends Node
var t := 0.0
func _physics_process(dt):
	t += dt
	if fmod(t, 2.0) < dt:
		var w = get_tree().current_scene.get("world")
		if w:
			print("t=%.1f pos=%s joy=%s vel=%s" % [t, w.player.global_position, Player.joy, w.player.velocity])
