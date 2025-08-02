extends Node3D
class_name Player

signal ran_out_of_length

@export var base_speed: float = 0.5
@export var base_turning_speed: float = 0.5
@export var facing_vector: Vector3 = Vector3(1, 0, 0)
@export var turning_axis: Vector3 = Vector3(0, 0, 1)
@export var point_adding_interval: float = 0.2
@export var initial_length: float = 20.0

var remaining_length: float = initial_length
var cur_turning_speed: float = base_turning_speed
var head_position: Vector3 = Vector3(0, 0, 0)
var distance_travelled_since_last_point: float = 0.0
var stored_backup_curve_point: Vector3 = Vector3.ZERO
var current_length: float = 0.0

@onready var snake_mesh: SnakeMesh = $SnakeMesh

func _ready() -> void:
	reset_snake()

func reset_snake() -> void:
	snake_mesh.points.clear()
	snake_mesh.points.append(head_position - facing_vector * snake_mesh.radius)
	snake_mesh.points.append(head_position)
	current_length = 0.0
	remaining_length = initial_length
	distance_travelled_since_last_point = 0.0
	stored_backup_curve_point = Vector3.ZERO

func get_speed() -> float:
	return base_speed

func get_turning_speed() -> float:
	return cur_turning_speed

func swap_direction() -> void:
	cur_turning_speed = -cur_turning_speed

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("swap direction"):
		swap_direction()

func collision_scan() -> void:
	var epsilon: float = 0.001
	var scan_point: Vector3 = snake_mesh.tip() + facing_vector * epsilon
	var nearest_point: SnakeMesh.PointOnCurve = snake_mesh.closest_point(scan_point)
	if snake_mesh.tip().distance_to(nearest_point.point) > epsilon / 2:
		var collision_angle: float = facing_vector.angle_to(nearest_point.direction)
		var damage_fract: float = abs(sin(collision_angle))
		Global.LogInfo("Collision detected with point: " + str(nearest_point.point) + ", angle: " + str(collision_angle) + ", damage fraction: " + str(damage_fract))
	# DebugDraw3D.draw_sphere(nearest_point.point, snake_mesh.radius + 0.1, Color(1, 0, 0), 0)

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
	current_length += moved_length
	remaining_length = max(0, remaining_length - moved_length)
	if remaining_length <= 0:
		death()
		ran_out_of_length.emit()
	# TODO: optimize
	snake_mesh.refresh()

func death() -> void:
	Global.LogInfo("Player has died")
	reset_snake()
