extends Node3D
class_name HyperLane

@export var cut_player_delay: float = 6.0
@export var cut_color: Color = Color.RED

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

var tube_mesh: TubeTrailMesh
var hyper_lane_material: ShaderMaterial

var from: Star
var to: Star
var _player: Player
var player_cut_length: float
var _cut_player_timer: float
var _intersects_player: bool = false
var _default_radius: float

func _ready() -> void:
	tube_mesh = mesh_instance_3d.mesh.duplicate(false) as TubeTrailMesh
	mesh_instance_3d.mesh = tube_mesh
	hyper_lane_material = tube_mesh.material.duplicate(false) as ShaderMaterial
	tube_mesh.material = hyper_lane_material
	_default_radius = tube_mesh.radius

func set_lane(source: Star, target: Star, player: Player) -> void:
	global_position = source.global_position
	var displacement: Vector3 = target.global_position - source.global_position
	var dir: Vector3 = displacement.normalized()
	var new_right: Vector3 = Vector3.FORWARD.cross(dir)
	global_basis = Basis(new_right, dir, global_basis.z).orthonormalized();
	
	mesh_instance_3d.position = Vector3.UP * displacement.length() / 2
	tube_mesh.section_length = displacement.length() / tube_mesh.sections
	global_position.z -= 0.03; # To push it into background
	
	from = source
	to = target
	set_color(from, from.color)
	set_color(to, from.color)
	set_player(player)

func set_color(star: Star, color: Color) -> void:
	var color_param: String = "color"
	if star == from:
		color_param = "color2"
	hyper_lane_material.set_shader_parameter(color_param, color)

func _process(delta: float) -> void:
	update_planned_cut(delta)
	if from.civilization != null and to.civilization != null and from.civilization == to.civilization:
		check_player_intersection()

func check_player_intersection() -> void:	
	var pos1: Vector2 = Vector2(from.global_position.x, from.global_position.y)
	var pos2: Vector2 = Vector2(to.global_position.x, to.global_position.y)
	var player_from: Vector2 = _player.get_last_position2d()
	var player_to: Vector2 = _player.get_current_position2d()
	
	var intersection_nullable: Variant = \
		Geometry2D.segment_intersects_segment(pos1, pos2, player_from, player_to)
	
	if intersection_nullable is Vector2:
		var intersection: Vector2 = intersection_nullable
		plan_cut_player(intersection)

func cut_player(length: float) -> void:
	_player.cut_off_prefix(length)

func plan_cut_player(intersection: Vector2) -> void:
	var player_displacement: Vector2 = \
		_player.get_current_position2d() - _player.get_last_position2d()
	
	var intersection_relative_to_player: Vector2 = \
		intersection - _player.get_current_position2d()
	
	# inverse, because we don't have previous length,
	# so we need subtract from the current length
	var inverse_length_delta_percent: float = \
		intersection_relative_to_player.dot(player_displacement)
		
	var inverse_length_delta: float = \
		player_displacement.length() * inverse_length_delta_percent
		
	player_cut_length = \
		_player.game_stats.current_length - inverse_length_delta
	
	# Save the exact float it saved, so we can compare equality later
	player_cut_length = _player.register_cut_callback(cancel_planned_cut, player_cut_length)
	if not _intersects_player:
		_cut_player_timer = cut_player_delay
		_intersects_player = true

func civilize(civilization: Civilization, star: Star) -> void:
	var color: Color = civilization.color
	if civilization == null:
		color.a = 0.3
	else:
		color.a = 0.69
	set_color(star, color)

func get_other(this_star: Star) -> Star:
	if this_star == from: return to
	else: return from

func set_player(player: Player) -> void:
	_player = player

func cancel_planned_cut(length: float) -> void:
	# the place we had to cut disappeared, we want to cancel the cut
	# if the player passed through us multiple times,
	# cancel only the latest cut
	if length == player_cut_length:
		_intersects_player = false

func update_planned_cut(delta: float) -> void:
	if not _intersects_player:
		cut_color.a = 0.0
		hyper_lane_material.set_shader_parameter("color_override", cut_color)
		tube_mesh.radius = _default_radius
		return
	
	if _cut_player_timer >= 0.0:
		_cut_player_timer -= delta
		cut_color.a = 1.0 - _cut_player_timer / cut_player_delay
		hyper_lane_material.set_shader_parameter("color_override", cut_color)
		tube_mesh.radius = lerp(_default_radius, _default_radius * 20, cut_color.a)
		
	if _intersects_player and _cut_player_timer < 0.0: 
		cut_player(player_cut_length)
		_intersects_player = false
