extends Node3D
class_name Player

@export var base_speed: float = 0.5
@export var base_turning_speed: float = 0.5
@export var facing_vector: Vector3 = Vector3(1, 0, 0)
@export var turning_axis: Vector3 = Vector3(0, 0, 1)
@export var point_adding_interval: float = 0.2

var cur_turning_speed: float = base_turning_speed
var head_position: Vector3 = Vector3(0, 0, 0)
var distance_travelled_since_last_point: float = 0.0
var stored_backup_curve_point: Vector3 = Vector3.ZERO

@onready var snake_mesh: SnakeMesh = $SnakeMesh

func _ready() -> void:
	snake_mesh.points.append(head_position - facing_vector * snake_mesh.radius)
	snake_mesh.points.append(head_position)

func get_speed() -> float:
	return base_speed

func get_turning_speed() -> float:
	return cur_turning_speed

func swap_direction() -> void:
	cur_turning_speed = -cur_turning_speed

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("swap direction"):
		swap_direction()

func _physics_process(delta: float) -> void:
	facing_vector = facing_vector.rotated(turning_axis, get_turning_speed() * delta)
	head_position += facing_vector * get_speed() * delta
	if distance_travelled_since_last_point >= point_adding_interval:
		snake_mesh.points[-1] = stored_backup_curve_point
		stored_backup_curve_point = Vector3.ZERO
		snake_mesh.points.append(head_position)
		distance_travelled_since_last_point = 0.0
	else:
		snake_mesh.points[-1] = head_position
		distance_travelled_since_last_point += get_speed() * delta
		if distance_travelled_since_last_point > point_adding_interval * 0.7 and stored_backup_curve_point == Vector3.ZERO:
			stored_backup_curve_point = head_position
	snake_mesh.head_facing = facing_vector
	# TODO: optimize
	snake_mesh.refresh()
