class_name HutB
extends Building
## A Builder's Hut: home of one builder, who walks out to build and upgrade
## things and comes back to rest by the sawhorse.


func _visual(root: Node3D, _t: int) -> void:
	Mats.inst(MeshKit.cached("hut", TownArt.hut), root)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-1.6, -1.9, 2.8, 1.9)]


## Where the builder rests.
func rest_spot() -> Vector3:
	return to_world(0.9, 0.35)


func status() -> String:
	return "Builders: %d / %d busy" % [Game.jobs.size(), Game.builders()]


func info() -> Array:
	return [["builder", "Houses one builder"], ["hammer", status()]]
