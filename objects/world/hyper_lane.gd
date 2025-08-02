extends Node3D
class_name HyperLane

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
var tube_mesh: TubeTrailMesh

var from: Vector3
var to: Vector3

func _ready() -> void:
	tube_mesh = mesh_instance_3d.mesh.duplicate() as TubeTrailMesh
	mesh_instance_3d.mesh = tube_mesh

func set_lane(source_position: Vector3, target_position: Vector3) -> void:
	global_position = source_position
	var displacement: Vector3 = target_position - source_position
	var dir: Vector3 = displacement.normalized()
	var new_right: Vector3 = Vector3.FORWARD.cross(dir)
	global_basis = Basis(new_right, dir, global_basis.z).orthonormalized();
	
	mesh_instance_3d.position = Vector3.UP * displacement.length() / 2
	tube_mesh.section_length = displacement.length() / tube_mesh.sections
	global_position.z -= 0.03; # To push it into background
