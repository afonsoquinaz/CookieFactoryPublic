extends Node
## Prints frame time and draw stats after warm-up (--perf).
var n := 0
var acc := 0.0
func _process(dt):
	n += 1
	if n > 120:
		acc += dt
	if n == 420:
		print("avg frame ms: %.2f" % (acc / 300.0 * 1000.0))
		print("draw calls: ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		print("objects: ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
		print("primitives: ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		print("nodes: ", get_tree().get_node_count())
		get_tree().quit()
