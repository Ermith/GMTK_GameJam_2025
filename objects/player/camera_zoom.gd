extends Camera3D
class_name CameraZoom

@export var zoom_speed: float = 10.0
@export var min_dist: float = 0.5
@export var max_dist: float = 10.0

func _process(delta: float) -> void:
	if Input.is_action_pressed("zoom in"):
		zoom_camera(-zoom_speed * delta)
	elif Input.is_action_pressed("zoom out"):
		zoom_camera(zoom_speed * delta)

func zoom_camera(delta: float) -> void:
	var new_distance: float = position.z + delta
	if new_distance < min_dist:
		new_distance = min_dist
	elif new_distance > max_dist:
		new_distance = max_dist
	position.z = new_distance

func set_target_position(target_position: Vector3) -> void:
	position.x = target_position.x
	position.y = target_position.y
