extends Node
class_name LoopEffect

@onready var mesh: SnakeMesh = $SnakeMesh
@onready var polygon: CSGPolygon3D = $Polygon

var shrink_velocity: float = 0.2
var timer: float = 0.0
var max_timer: float = 0.7
var velocity_mult: float = 1.0
var color: Color = Color(1, 1, 1, 1)
var velocity_acceleration: float = 8.0

func _ready() -> void:
	mesh.mesh = mesh.mesh.duplicate()

func init(points: PackedVector3Array, color_: Color) -> void:
	mesh.points = points
	if mesh.get_clockwiseness() == -1:
		velocity_mult *= -1
	self.color = color_

func update_points() -> void:
	var twodpoints: PackedVector2Array = PackedVector2Array()
	for point: Vector3 in mesh.points:
		twodpoints.append(Vector2(point.x, point.y))
	polygon.polygon = twodpoints
	mesh.refresh()

func time_frac() -> float:
	if timer >= max_timer:
		return 1.0
	return timer / max_timer

func main_alpha_fn(t: float) -> float:
	return 1.0 - smoothstep(0, 1, t)

func polygon_alpha_fn(t: float) -> float:
	var fgdjiojfdgso: float = clamp(t * 5.0, 0.0, 1.0)
	return smoothstep(0.0, 1.0, fgdjiojfdgso) * 0.7

func _process(delta: float) -> void:
	var new_points: PackedVector3Array = PackedVector3Array()
	for i: int in range(mesh.points.size()):
		var prev_i: int = (i - 1 + mesh.points.size()) % mesh.points.size()
		var next_i: int = (i + 1) % mesh.points.size()
		var prev_point: Vector3 = mesh.points[prev_i]
		var point: Vector3 = mesh.points[i]
		var next_point: Vector3 = mesh.points[next_i]
		var direction: Vector3 = (next_point - prev_point).normalized()
		var in_vector: Vector3 = direction.cross(Vector3(0, 0, 1)).normalized() * velocity_mult
		new_points.append(point + in_vector * shrink_velocity * delta)

	mesh.points = new_points
	shrink_velocity += velocity_acceleration * delta
	timer += delta

	var mat: StandardMaterial3D = mesh.material_override as StandardMaterial3D
	mat.albedo_color = color
	mat.albedo_color.a = main_alpha_fn(time_frac())
	mat.emission = color
	mat.emission.a = main_alpha_fn(time_frac())
	var polygon_mat: StandardMaterial3D = polygon.material_override as StandardMaterial3D
	polygon_mat.albedo_color = color
	polygon_mat.albedo_color.a = main_alpha_fn(time_frac()) * polygon_alpha_fn(time_frac())
	polygon_mat.emission = color
	polygon_mat.emission.a = main_alpha_fn(time_frac()) * polygon_alpha_fn(time_frac())

	if timer > max_timer:
		queue_free()
		return

	update_points()
