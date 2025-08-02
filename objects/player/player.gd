extends Node3D
class_name Player

signal ran_out_of_length

@export var game_stats: GameStats = preload("res://resources/game_stats.tres")

@export var base_turning_speed: float = PI / 2
@export var facing_vector: Vector3 = Vector3(1, 0, 0)
@export var turning_axis: Vector3 = Vector3(0, 0, 1)
@export var point_adding_interval: float = 0.2
@export var collision_radius: float = 0.1
## Fraction of the length that is recovered on collision at the minimum (perpendicular collision)
@export var min_recovery_on_loop: float = 0.5

var cur_turning_speed: float = base_turning_speed
var head_position: Vector3 = Vector3(0, 0, 0)
var distance_travelled_since_last_point: float = 0.0
var stored_backup_curve_point: Vector3 = Vector3.ZERO
var current_length: float = 0.0
var collision_cooldown: float = 0.0
var max_colision_cooldown: float = 0.1

@onready var snake_mesh: SnakeMesh = $SnakeMesh

func _ready() -> void:
	reset_snake()

func reset_snake() -> void:
	snake_mesh.points.clear()
	snake_mesh.points.append(head_position)
	game_stats.reset()
	distance_travelled_since_last_point = 0.0
	stored_backup_curve_point = Vector3.ZERO

func get_speed() -> float:
	return game_stats.base_speed

func get_turning_speed() -> float:
	return cur_turning_speed

func swap_direction() -> void:
	cur_turning_speed = -cur_turning_speed

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("swap direction"):
		swap_direction()

func collision_scan() -> void:
	if collision_cooldown > 0:
		collision_cooldown -= get_process_delta_time()
		return
	var scan_point: Vector3 = head_position + facing_vector * collision_radius
	var nearest_point: SnakeMesh.PointOnCurve = snake_mesh.closest_point(scan_point)
	if head_position.distance_to(nearest_point.point) > collision_radius / 2:
		var collision_angle: float = facing_vector.angle_to(nearest_point.direction)
		var raw_damage_fract: float = sin(collision_angle) ** 2 #1 - abs(cos(collision_angle))
		var recovery_fract: float = clamp((1.0 - (raw_damage_fract - 0.1) / 0.9) * (1 - min_recovery_on_loop) + min_recovery_on_loop, 0.0, 1.0)
		DebugDraw3D.draw_sphere(nearest_point.point, snake_mesh.radius + 0.1, Color(1, 0, 0), 0)
		var split_off_points: PackedVector3Array = snake_mesh.split_off_suffix(nearest_point.offset)
		distance_travelled_since_last_point = 0.0
		stored_backup_curve_point = Vector3.ZERO

		var length_split_off: float = 0.0
		for i: int in range(1, split_off_points.size()):
			length_split_off += split_off_points[i - 1].distance_to(split_off_points[i])
		Global.LogInfo("Collision detected with point: " + str(nearest_point.point) + ", angle: " + str(collision_angle) + ", damage fraction: " + str(raw_damage_fract) + ", length split off: " + str(length_split_off))
		var recovered_length: float = length_split_off * recovery_fract
		Global.LogInfo("Recovered length: " + str(recovered_length))
		game_stats.remaining_length += recovered_length
		collision_cooldown = max_colision_cooldown
		head_position = nearest_point.point

func _physics_process(delta: float) -> void:
	var moved_length: float = get_speed() * delta
	facing_vector = facing_vector.rotated(turning_axis, get_turning_speed() * delta)
	head_position += facing_vector * moved_length
	collision_scan()
	if distance_travelled_since_last_point >= point_adding_interval:
		snake_mesh.points[-1] = stored_backup_curve_point
		stored_backup_curve_point = Vector3.ZERO
		snake_mesh.points.append(head_position)
		distance_travelled_since_last_point = 0.0
	else:
		snake_mesh.points[-1] = head_position
		distance_travelled_since_last_point += moved_length
		if distance_travelled_since_last_point > point_adding_interval * 0.7 and stored_backup_curve_point == Vector3.ZERO:
			stored_backup_curve_point = head_position
	snake_mesh.head_facing = facing_vector
	game_stats.current_length += moved_length
	game_stats.remaining_length = max(0, game_stats.remaining_length - moved_length)
	if game_stats.remaining_length <= 0:
		death()
		ran_out_of_length.emit()
	# TODO: optimize
	snake_mesh.refresh()

func death() -> void:
	Global.LogInfo("Player has died")
	#GameInstance.PlayerDefeated()
	reset_snake()
