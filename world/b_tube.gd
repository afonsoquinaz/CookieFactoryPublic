class_name TubeB
extends LineModule
## A plain stretch of glass tube that joins line parts. A Hopper can be
## placed right on top of a tube to replace it.


func _visual(root: Node3D, _t: int) -> void:
	_tube(root, size_m().x)


func status() -> String:
	return "Part of a line" if line else "Not part of a line yet"
