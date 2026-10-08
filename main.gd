extends Node
## Game root: the world and the UI on top.

var world: World
var ui: Control


func _ready() -> void:
	var a := Shot.args()
	if a.has("fresh"):
		Game.reset_state()
	if a.has("money"):
		Game.money = int(a["money"])
	if a.has("level"):
		Game.level = int(a["level"])
	for b in a.get("build", "").split(",", false):
		Game.buildings[b] = true
	world = World.new()
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	if ResourceLoader.exists("res://ui/hud.gd"):
		ui = load("res://ui/hud.gd").new()
		ui.set("world", world)
		layer.add_child(ui)
	Sfx.start_music()
	if a.has("cam"):
		var p: PackedStringArray = a["cam"].split(",")
		world.player.global_position = Vector3(float(p[0]), 0, float(p[1]))
		world.cam.snap()
	if a.has("zoom"):
		world.cam.zoom = float(a["zoom"])
	if a.has("bot"):
		var bot := Bot.new()
		bot.world = world
		add_child(bot)
	Shot.attach(self)
