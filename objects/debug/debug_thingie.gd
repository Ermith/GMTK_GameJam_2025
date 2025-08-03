extends Node
class_name DebugThingie

func _init() -> void:
	RenderingServer.set_debug_generate_wireframes(true)

class TracePoint:
	var position: Vector3

	func on_explode() -> void:
		DebugDraw3D.draw_sphere(position, 0.3, Color(1, 0, 0), 0)

var trace_points: Array[TracePoint] = []
var player: Player = null

func get_player() -> Player:
	if player == null:
		for child: Variant in get_parent().get_children():
			if child is Player:
				player = child
				break
	return player

func _input(event: InputEvent) -> void:
	if event is InputEventKey and Input.is_key_pressed(KEY_P):
		var vp: Viewport = get_viewport()
		var current_debug_draw: int = vp.debug_draw as int
		var next_debug_draw: Viewport.DebugDraw = ((current_debug_draw + 1) % (Viewport.DebugDraw.DEBUG_DRAW_INTERNAL_BUFFER as int)) as Viewport.DebugDraw
		vp.debug_draw = next_debug_draw
	if event is InputEventKey and Input.is_key_pressed(KEY_T):
		var trace_point: TracePoint = TracePoint.new()
		trace_points.append(trace_point)
		trace_point.position = get_player().head_position + get_player().global_position
		var callback: Callable = func() -> void:
			trace_point.on_explode()
			trace_points.erase(trace_point)
		get_player().register_cut_callback(callback)

func _process(_delta: float) -> void:
	for trace_point: TracePoint in trace_points:
		DebugDraw3D.draw_sphere(trace_point.position, 0.1, Color(0, 0, 1), 0)
