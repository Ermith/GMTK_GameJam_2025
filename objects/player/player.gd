extends Node3D
class_name Player

signal ran_out_of_length
signal looped(snake_mesh: SnakeMesh)

@export var game_stats: GameStats = preload("res://resources/game_stats.tres")

@export var base_turning_speed: float = PI / 2
@export var facing_vector: Vector3 = Vector3(1, 0, 0)
@export var turning_axis: Vector3 = Vector3(0, 0, 1)
@export var point_adding_interval: float = 0.2
@export var collision_radius: float = 0.05
## Fraction of the length that is recovered on collision at the minimum (perpendicular collision)
@export var min_recovery_on_loop: float = 0.5
@export var max_distance_from_start: float = INF

@export var loop_effect_scene: PackedScene = preload("res://objects/player/loop_effect.tscn")
const DEAD_SNAKE: PackedScene = preload("res://objects/player/dead_snake.tscn")

var cur_turning_speed: float = base_turning_speed
var head_position: Vector3 = Vector3(0, 0, 0)
var distance_travelled_since_last_point: float = 0.0
var stored_backup_curve_point: Vector3 = Vector3.ZERO
var collision_cooldown: float = 0.0
var max_colision_cooldown: float = 0.1
var average_turning_speed: float = base_turning_speed
var _last_position: Vector3
var totalLengthLost: float = 0.0

class CutCallback:
	var length: float
	var callback: Callable

	func _init(length_: float, callback_: Callable) -> void:
		self.length = length_
		self.callback = callback_

var cut_callbacks: Array[CutCallback] = []

@onready var snake_mesh: SnakeMesh = $SnakeMesh
@onready var camera: CameraZoom = $Camera3D

func _ready() -> void:
	reset_snake()
	AudioClipManager.play("res://sounds/sfx/breathe.mp3")

func reset_snake() -> void:
	snake_mesh.points.clear()
	snake_mesh.points.append(head_position)
	game_stats.reset()
	distance_travelled_since_last_point = 0.0
	stored_backup_curve_point = Vector3.ZERO
	_last_position = head_position + global_position
	totalLengthLost = 0.0

func get_speed() -> float:
	return game_stats.base_speed

func get_turning_speed() -> float:
	return cur_turning_speed

func swap_direction() -> void:
	cur_turning_speed = -cur_turning_speed

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("swap direction"):
		swap_direction()

static func collision_goodness(angle: float) -> float:
	var raw_damage_fract: float = sin(angle) ** 2
	return clamp((1.0 - (raw_damage_fract - 0.1) / 0.9), 0, 1)

static func goodness_to_color(goodness: float) -> Color:
	var hue: float = lerp(0.0, 0.37, goodness) # red to green
	return Color.from_hsv(hue, 1.0, 1.0)

func collision_scan() -> void:
	if collision_cooldown > 0:
		collision_cooldown -= get_process_delta_time()
		return
	var scan_point: Vector3 = head_position + facing_vector * collision_radius
	if snake_mesh.points.size() < 2:
		return
	var nearest_point: SnakeMesh.PointOnCurve = snake_mesh.closest_point(scan_point)
	if head_position.distance_to(nearest_point.point) > collision_radius / 2 and scan_point.distance_to(nearest_point.point) < collision_radius:
		var collision_angle: float = facing_vector.angle_to(nearest_point.direction)
		var raw_damage_fract: float = sin(collision_angle) ** 2 #1 - abs(cos(collision_angle))
		var col_goodness: float = Player.collision_goodness(collision_angle)
		var recovery_fract: float = clamp(col_goodness * (1 - min_recovery_on_loop) + min_recovery_on_loop, 0.0, 1.0)
		# DebugDraw3D.draw_sphere(nearest_point.point, snake_mesh.radius + 0.1, Color(1, 0, 0), 0)
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
		snake_mesh.refresh_curve()
		
		if col_goodness > 0.66:
			AudioClipManager.play("res://sounds/sfx/eat_self.wav", 0.5)
		elif col_goodness > 0.33:
			AudioClipManager.play("res://sounds/sfx/eat_self2.wav", 0.5)
		else:
			AudioClipManager.play("res://sounds/sfx/eat_self3.wav", 0.5)

		var length_left_intact: float = snake_mesh.curve.get_baked_length()
		for i: int in range(cut_callbacks.size() - 1, -1, -1):
			var callback: CutCallback = cut_callbacks[i]
			if length_left_intact <= callback.length:
				if is_instance_valid(callback.callback.get_object()):
					callback.callback.call(callback.length)
				cut_callbacks.remove_at(i)

		if length_split_off > 0.5:
			var loop_effect: LoopEffect = loop_effect_scene.instantiate()
			get_parent().add_child(loop_effect)
			loop_effect.init(split_off_points, goodness_to_color(col_goodness))
			loop_effect.global_position = global_position
			loop_effect.mesh.radius = snake_mesh.radius
			looped.emit(loop_effect.mesh)

func check_for_escaping_galaxy() -> void:
	if head_position.length() < max_distance_from_start:
		return
	var turning_sign: float = 1.0
	if head_position.cross(facing_vector).dot(turning_axis) < 0:
		turning_sign = -1.0
	else:
		turning_sign = 1.0
	cur_turning_speed = abs(turning_sign * get_turning_speed())

func _physics_process(delta: float) -> void:	
	check_for_escaping_galaxy()
	var moved_length: float = get_speed() * delta
	facing_vector = facing_vector.rotated(turning_axis, get_turning_speed() * delta)
	_last_position = head_position + global_position
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
	var orig_cur_length: float = snake_mesh.curve.get_baked_length()
	snake_mesh.refresh_curve()
	var length_moved_according_to_curve: float = snake_mesh.curve.get_baked_length() - orig_cur_length
	game_stats.remaining_length = max(0, game_stats.remaining_length - length_moved_according_to_curve)
	if game_stats.remaining_length <= 0:
		death()
		ran_out_of_length.emit()

	average_turning_speed = lerp(average_turning_speed, get_turning_speed(), 0.02)

	var future: FutureState = predict_future(120, delta)
	# DebugDraw3D.draw_line(future.head_position, future.head_position + future.facing_vector * 0.5, Color(1, 0, 0))
	snake_mesh.coloring_point = future.head_position
	snake_mesh.coloring_direction = future.facing_vector

	# TODO: optimize
	snake_mesh.refresh_mesh()
	game_stats.current_length = snake_mesh.curve.get_baked_length()

func _process(_delta: float) -> void:
	var shader: ShaderMaterial = snake_mesh.get_material_override() as ShaderMaterial
	if shader:
		shader.set_shader_parameter("lengthOffset", totalLengthLost)
	if snake_mesh.points.size() < 2:
		return
	camera.set_target_position(head_position)

func death() -> void:
	Global.LogInfo("Player has died")
	GameInstance.PlayerDefeated()
	reset_snake()

class FutureState:
	var head_position: Vector3
	var facing_vector: Vector3
	var collided: bool = false


func manual_collision_check(pos: Vector3, facing: Vector3) -> bool:
	var scan_point: Vector3 = pos + facing * collision_radius
	if snake_mesh.points.size() < 2:
		return false
	var nearest_point: SnakeMesh.PointOnCurve = snake_mesh.closest_point(scan_point)
	if pos.distance_to(nearest_point.point) > collision_radius / 2 and head_position.distance_to(nearest_point.point) > collision_radius / 2 and scan_point.distance_to(nearest_point.point) < collision_radius:
		return true
	return false

func predict_future(steps: int, step_size: float) -> FutureState:
	var future_state: FutureState = FutureState.new()
	future_state.head_position = head_position
	future_state.facing_vector = facing_vector
	for i: int in range(steps):
		future_state.head_position += future_state.facing_vector * step_size * get_speed()
		future_state.facing_vector = future_state.facing_vector.rotated(turning_axis, average_turning_speed * step_size)
		if manual_collision_check(future_state.head_position, future_state.facing_vector):
			future_state.collided = true
			break
	return future_state

func register_cut_callback(callback: Callable, length: float = -1) -> float:
	if length < 0:
		length = game_stats.current_length
	
	cut_callbacks.append(CutCallback.new(length, callback))
	return length

func get_current_position2d() -> Vector2:
	var position3d: Vector3 = head_position + global_position
	return Vector2(position3d.x, position3d.y)
	
func get_last_position2d() -> Vector2:
	return Vector2(_last_position.x, _last_position.y)

func cut_off_prefix(length_of_prefix: float) -> void:
	if length_of_prefix <= 0:
		return
	var split_off_points: PackedVector3Array = snake_mesh.split_off_prefix(length_of_prefix)
	snake_mesh.refresh_curve()
	var length_change: float = snake_mesh.curve.get_baked_length() - game_stats.current_length
	game_stats.current_length = snake_mesh.curve.get_baked_length()
	var visited_lanes: Array[HyperLane] = []
	for i: int in range(cut_callbacks.size() - 1, -1, -1):
		var callback: CutCallback = cut_callbacks[i]
		if length_of_prefix >= callback.length:
			if is_instance_valid(callback.callback.get_object()):
				callback.callback.call(callback.length)
			cut_callbacks.remove_at(i)
		else:
			callback.length += length_change
			var callback_obj: HyperLane = callback.callback.get_object() as HyperLane
			if callback_obj:
				if callback_obj not in visited_lanes:
					visited_lanes.append(callback_obj)
					callback_obj.player_cut_length += length_change

	var dead_snake: DeadSnake = DEAD_SNAKE.instantiate()
	dead_snake.lengthOffset = totalLengthLost
	get_parent().add_child(dead_snake)
	dead_snake.snake_mesh.radius = snake_mesh.radius
	dead_snake.init(split_off_points)
	dead_snake.global_position = global_position

	totalLengthLost -= length_change
