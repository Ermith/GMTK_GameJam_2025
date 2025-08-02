extends Node3D
class_name Player

signal ran_out_of_length

@export var game_stats: GameStats = preload("res://resources/game_stats.tres")

@export var base_turning_speed: float = PI / 2
@export var facing_vector: Vector3 = Vector3(1, 0, 0)
@export var turning_axis: Vector3 = Vector3(0, 0, 1)
@export var point_adding_interval: float = 0.2
@export var collision_radius: float = 0.1
		
var cur_turning_speed: float = base_turning_speed
var head_position: Vector3 = Vector3(0, 0, 0)
var distance_travelled_since_last_point: float = 0.0
var stored_backup_curve_point: Vector3 = Vector3.ZERO

@onready var snake_mesh: SnakeMesh = $SnakeMesh

func _ready() -> void:
	reset_snake()

func reset_snake() -> void:
	snake_mesh.points.clear()
	snake_mesh.points.append(head_position - facing_vector * snake_mesh.radius)
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
	var scan_point: Vector3 = head_position + facing_vector * collision_radius
	var nearest_point: SnakeMesh.PointOnCurve = snake_mesh.closest_point(scan_point)
	if head_position.distance_to(nearest_point.point) > collision_radius / 2:
		var collision_angle: float = facing_vector.angle_to(nearest_point.direction)
		var damage_fract: float = abs(sin(collision_angle))
		Global.LogInfo("Collision detected with point: " + str(nearest_point.point) + ", angle: " + str(collision_angle) + ", damage fraction: " + str(damage_fract))
		DebugDraw3D.draw_sphere(nearest_point.point, snake_mesh.radius + 0.1, Color(1, 0, 0), 0)

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
