extends Node3D
class_name HyperLane

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
var tube_mesh: TubeTrailMesh
var hyper_lane_material: ShaderMaterial

var from: Star
var to: Star

func _ready() -> void:
	tube_mesh = mesh_instance_3d.mesh.duplicate(false) as TubeTrailMesh
	mesh_instance_3d.mesh = tube_mesh
	hyper_lane_material = tube_mesh.material.duplicate(false) as ShaderMaterial
	tube_mesh.material = hyper_lane_material

func set_lane(source: Star, target: Star) -> void:
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

func set_color(star: Star, color: Color) -> void:
	var color_param: String = "color"
	if star == from:
		color_param = "color2"
	hyper_lane_material.set_shader_parameter(color_param, color)

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
