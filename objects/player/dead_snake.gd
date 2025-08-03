extends Node3D
class_name DeadSnake

@onready var snake_mesh: SnakeMesh = $SnakeMesh

var timer: float = 0.0
var max_timer: float = 1.5
var lengthOffset: float = 0.0

var timeFrozen: float = 0.0

func _ready() -> void:
	snake_mesh.mesh = snake_mesh.mesh.duplicate()
	snake_mesh.material_override = snake_mesh.material_override.duplicate(false)

func init(points: PackedVector3Array) -> void:
	snake_mesh.points = points
	snake_mesh.refresh()
	timeFrozen = Time.get_ticks_msec() / 1000.0

func _process(delta: float) -> void:
	timer += delta
	if timer >= max_timer:
		queue_free()
		return

	var material: ShaderMaterial = snake_mesh.material_override as ShaderMaterial
	var t: float = timer / max_timer
	t = smoothstep(0.0, 1.0, t)
	material.set_shader_parameter("alphaMult", 1.0 - t)
	material.set_shader_parameter("saturation", 1.0 - t)
	material.set_shader_parameter("timeOverride", timeFrozen)
	material.set_shader_parameter("lengthOffset", lengthOffset)
	material.set_shader_parameter("headLength", 0.0)
