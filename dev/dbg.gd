extends Node
var n := 0
func _process(_d):
	n += 1
	if n == 60:
		var hud = get_parent().ui
		print("hud ", hud.size, " ", hud.get_global_rect())
		for c in hud.get_children():
			if c is Sheet:
				print("sheet ", c.size, " panel ", c.panel.get_global_rect(), " anchors ", c.panel.anchor_top, " ", c.panel.offset_top, " ", c.panel.offset_bottom)
		get_tree().quit()
