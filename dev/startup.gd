extends Node
## Prints how long the world took to build (--startup).
func _ready():
	print("startup ms: ", Time.get_ticks_msec())
	await get_tree().process_frame
	print("first frame ms: ", Time.get_ticks_msec())
	get_tree().quit()
