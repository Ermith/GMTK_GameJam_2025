extends Node3D
class_name Star

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
var shader_material: ShaderMaterial
@export var STAR_MATERIAL: ShaderMaterial

var neightbors: Array[Star]
var hyper_lanes: Array[HyperLane]
var sector: Sector
var civilization: Civilization
var color: Color

func _ready() -> void:
	mesh_instance_3d.material_override = STAR_MATERIAL.duplicate(false)
	shader_material = mesh_instance_3d.material_override as ShaderMaterial
	mesh_instance_3d.mesh = mesh_instance_3d.mesh.duplicate(false)

func set_color(in_color: Color) -> void:
	shader_material.set_shader_parameter("star_color", in_color)
	color = in_color
	
func civilize(in_civilization: Civilization) -> void:
	civilization = in_civilization
	set_color(civilization.color)
	for hyper_lane: HyperLane in hyper_lanes:
		hyper_lane.civilize(in_civilization, self)

func can_expand() -> bool:
	for hyper_lane: HyperLane in hyper_lanes:
		if hyper_lane.get_other(self).civilization == null:
			return true
			
	return false

func set_size(size: float) -> void:
	var mesh: PlaneMesh = mesh_instance_3d.mesh as PlaneMesh
	mesh.size = Vector2(size, size)