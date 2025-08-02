extends Node
class_name DebugThingie

func _init() -> void:
	RenderingServer.set_debug_generate_wireframes(true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and Input.is_key_pressed(KEY_P):
		var vp: Viewport = get_viewport()
		var current_debug_draw: int = vp.debug_draw as int
		var next_debug_draw: Viewport.DebugDraw = ((current_debug_draw + 1) % (Viewport.DebugDraw.DEBUG_DRAW_INTERNAL_BUFFER as int)) as Viewport.DebugDraw
		vp.debug_draw = next_debug_draw
