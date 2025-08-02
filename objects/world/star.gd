extends Node3D
class_name Star
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
var shader_material: ShaderMaterial

var neightbors: Array[Star]

func _ready() -> void:
	mesh_instance_3d.material_override = mesh_instance_3d.mesh.surface_get_material(0).duplicate(false)
	shader_material = mesh_instance_3d.material_override as ShaderMaterial
	
	var color: Color
	color = Color.from_hsv(randf(), 1.0, 1.0)
	set_color(color)
	pass

func set_color(color: Color) -> void:
	shader_material.set_shader_parameter("star_color", color)
