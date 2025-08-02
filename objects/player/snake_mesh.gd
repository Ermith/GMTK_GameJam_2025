extends MeshInstance3D
class_name SnakeMesh

@export var points: PackedVector3Array = PackedVector3Array()
@export var radius: float = 0.2
@export var ring_interval: float = 0.2
@export var ring_segments: int = 8
@export var tail_length: float = 1.0
@export var curve_param: float = 0.8
@export var cubic_interpolation: bool = true
@export var head_facing: Vector3 = Vector3(0, 0, 0)
@export var looped: bool = false

@export var coloring_point: Vector3 = Vector3.ZERO
@export var coloring_radius: float = 0.0
@export var coloring_direction: Vector3 = Vector3(1, 0, 0)
@export var head_distance_not_colored: float = 1.0
@export var default_color: Color = Color(1, 1, 1, 1)

var curve: Curve3D
var clockwiseness: int = 0 # 1 for clockwise, -1 for counter-clockwise, 0 for unknown

const bake_interval: float = INF

func _ready() -> void:
	curve = Curve3D.new()
	curve.set_bake_interval(bake_interval)
	refresh()

func debug_draw_curve() -> void:
	var baked_points: PackedVector3Array = curve.get_baked_points()
	for i: int in range(baked_points.size() - 1):
		DebugDraw3D.draw_line(baked_points[i], baked_points[i + 1], Color(0, 1, 0), 0.005)
	
	for i: int in range(points.size()):
		var point: Vector3 = points[i]
		var sphere_color: Color = Color(1, 0.5, 0)
		DebugDraw3D.draw_sphere(point, 0.01, sphere_color, 0)

func debug_draw_inside() -> void:
	for point: Vector3 in points:
		var twod_point: Vector2 = Vector2(point.x, point.y)
		twod_point += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		var back_to_3d: Vector3 = Vector3(twod_point.x, twod_point.y, point.z)
		if contains_2dpoint(twod_point):
			DebugDraw3D.draw_sphere(back_to_3d, 0.05, Color(0, 1, 0), 0)
		else:
			DebugDraw3D.draw_sphere(back_to_3d, 0.05, Color(1, 0, 0), 0)

func refresh() -> void:
	refresh_curve()
	refresh_mesh()

# func _process(_delta: float) -> void:
# 	if looped:
# 		debug_draw_inside()
# 	debug_draw_curve()

func refresh_curve() -> void:
	clockwiseness = 0
	if points.size() < 2:
		return
	curve = Curve3D.new()
	curve.closed = looped
	curve.set_bake_interval(bake_interval)
	for i: int in range(points.size()):
		var direction: Vector3 = Vector3.ZERO
		var distance_to_nearest: float = radius
		if i == 0:
			direction = points[i + 1] - points[i]
			distance_to_nearest = min(distance_to_nearest, (points[i + 1] - points[i]).length())
		elif i == points.size() - 1:
			direction = points[i] - points[i - 1]
			distance_to_nearest = min(distance_to_nearest, (points[i] - points[i - 1]).length())
		else:
			direction = points[i + 1] - points[i - 1]
			distance_to_nearest = min(distance_to_nearest, (points[i + 1] - points[i]).length(), (points[i] - points[i - 1]).length())
		direction = direction.normalized()
		var out_vector: Vector3 = direction * curve_param * distance_to_nearest * 0.5
		curve.add_point(points[i], -out_vector, out_vector)

func radius_function(t: float) -> float:
	if looped:
		return radius
	var snake_length: float =  curve.get_baked_length()
	var result: float = radius
	var distance_from_tail: float = snake_length * t
	if distance_from_tail < tail_length:
		var p: float = distance_from_tail / tail_length
		result *= smoothstep(0, 1, p)
	return result

class BakedPoints:
	var points: PackedVector3Array
	var offsets: Array[float]

func get_baked_points() -> BakedPoints:
	var result: BakedPoints = BakedPoints.new()
	result.points = PackedVector3Array()
	result.offsets = []
	var curve_length: float = curve.get_baked_length()
	var offset: float = 0.0
	while offset < curve_length:
		result.points.append(curve.sample_baked(offset, cubic_interpolation))
		result.offsets.append(offset)
		offset += ring_interval
	result.points.append(curve.sample_baked(curve_length, cubic_interpolation))
	result.offsets.append(curve_length)
	return result

func color_at_pos(t: float) -> Color:
	if coloring_radius <= 0:
		return default_color
	var length: float = curve.get_baked_length()
	var point: Vector3 = curve.sample_baked(t * length, cubic_interpolation)
	var distance_to_point: float = point.distance_to(coloring_point)
	if distance_to_point > coloring_radius:
		return default_color
	var distance_from_head: float = length - (t * length)
	var distance_from_head_frac: float = distance_from_head / head_distance_not_colored
	var color_intensity: float = smoothstep(0, 1, 1.0 - (distance_to_point / coloring_radius)) * smoothstep(0, 1, distance_from_head_frac)
	var p_before: Vector3 = curve.sample_baked((t - 0.01) * length, cubic_interpolation)
	var p_after: Vector3 = curve.sample_baked((t + 0.01) * length, cubic_interpolation)
	var direction: Vector3 = (p_after - p_before).normalized()
	var angle: float = direction.angle_to(coloring_direction)
	var goodness: float = Player.collision_goodness(angle)
	var color: Color = Player.goodness_to_color(goodness)
	color = lerp(default_color, color, color_intensity)
	return color

func refresh_mesh() -> void:
	var array_mesh: ArrayMesh = mesh as ArrayMesh
	array_mesh.clear_surfaces()
	if points.size() < 2:
		return

	var surface_array: Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var colors: PackedColorArray = PackedColorArray()
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_COLOR] = colors

	var baked_points: BakedPoints = get_baked_points()
	if baked_points.points.size() < 2:
		return
	#var baked_up_vectors: PackedVector3Array = curve.get_baked_up_vectors()

	var head_center: Vector3 = baked_points.points[-1]
	var tail_vertex_index: int = -100000
	var head_vertex_index: int = -100000
	if not looped:
		tail_vertex_index = 0
		verts.append(baked_points.points[0])
		normals.append((baked_points.points[0] - baked_points.points[1]).normalized())
		uvs.append(Vector2(0, 0))
		colors.append(color_at_pos(0.0))

		head_vertex_index = 1
		verts.append(head_center + head_facing.normalized() * radius_function(1.0))
		normals.append((baked_points.points[-1] - baked_points.points[-2]).normalized())
		uvs.append(Vector2(1, 0))
		colors.append(color_at_pos(1.0))

	for index: int in range(1, baked_points.points.size() - 1):
		var current_point: Vector3 = baked_points.points[index]
		var next_point: Vector3 = baked_points.points[index + 1]
		var prev_point: Vector3 = baked_points.points[index - 1]
		var direction: Vector3 = (next_point - prev_point).normalized()
		# var up_vector: Vector3 = baked_up_vectors[index]
		# backup solution
		var blargh: Vector3 = Vector3(0, 0, -1).cross(direction).normalized()
		var up_vector: Vector3 = blargh.cross(direction).normalized()
		var t: float = baked_points.offsets[index] / curve.get_baked_length()

		var base_vertex_index: int = verts.size()
		for i: int in range(ring_segments):
			var angle: float = (i / float(ring_segments)) * TAU
			var local_offset: Vector3 = Vector3(cos(angle), sin(angle), 0) * radius_function(t)
			var offset: Vector3 = direction.cross(up_vector).normalized() * local_offset.x + up_vector * local_offset.y
			
			var vertex: Vector3 = current_point + offset
			verts.append(vertex)

			var normal: Vector3 = (vertex - current_point).normalized()
			normals.append(normal)
			
			var u: float = t
			var v: float = float(i) / float(ring_segments)
			uvs.append(Vector2(u, v))

			colors.append(color_at_pos(t))
			
			if index == 1:
				if looped:
					var previous_base_index: int = (baked_points.points.size() - 3) * ring_segments
					indices.append(base_vertex_index + i)
					indices.append(previous_base_index + i)
					indices.append(previous_base_index + (i + 1) % ring_segments)

					indices.append(base_vertex_index + (i + 1) % ring_segments)
					indices.append(base_vertex_index + i)
					indices.append(previous_base_index + (i + 1) % ring_segments)
				else:
					indices.append(base_vertex_index + i)
					indices.append(tail_vertex_index)
					indices.append(base_vertex_index + (i + 1) % ring_segments)
			else:
				var previous_base_index: int = base_vertex_index - ring_segments
				indices.append(base_vertex_index + i)
				indices.append(previous_base_index + i)
				indices.append(previous_base_index + (i + 1) % ring_segments)

				indices.append(base_vertex_index + (i + 1) % ring_segments)
				indices.append(base_vertex_index + i)
				indices.append(previous_base_index + (i + 1) % ring_segments)

	if not looped:
		var blargh_head: Vector3 = Vector3(0, 0, -1).cross(head_facing).normalized()
		var up_vector_head: Vector3 = blargh_head.cross(head_facing).normalized()
		var n_head_bits: int = ring_segments - 1
		for head_bit: int in range(n_head_bits):
			var head_angle: float = (1 + head_bit) / float(n_head_bits + 2) * PI / 2
			var base_vertex_index: int = verts.size()
			for i: int in range(ring_segments):
				var angle: float = (i / float(ring_segments)) * TAU
				var local_offset: Vector3 = Vector3(cos(angle) * cos(head_angle), sin(angle) * cos(head_angle), sin(head_angle)) * radius_function(1.0)
				var offset: Vector3 = head_facing.cross(up_vector_head).normalized() * local_offset.x + up_vector_head * local_offset.y + head_facing * local_offset.z
				
				var vertex: Vector3 = head_center + offset
				verts.append(vertex)

				var normal: Vector3 = (vertex - head_center).normalized()
				normals.append(normal)
				
				var u: float = 1.0
				var v: float = float(i) / float(ring_segments)
				uvs.append(Vector2(u, v))

				colors.append(color_at_pos(1.0))

				if head_bit == n_head_bits - 1:
					indices.append(head_vertex_index)
					indices.append(base_vertex_index + i)
					indices.append(base_vertex_index + (i + 1) % ring_segments)
				var previous_base_index: int = base_vertex_index - ring_segments
				indices.append(base_vertex_index + i)
				indices.append(previous_base_index + i)
				indices.append(previous_base_index + (i + 1) % ring_segments)

				indices.append(base_vertex_index + (i + 1) % ring_segments)
				indices.append(base_vertex_index + i)
				indices.append(previous_base_index + (i + 1) % ring_segments)

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)


class PointOnCurve:
	var point: Vector3
	var offset: float
	var direction: Vector3

	func _init(point_: Vector3, offset_: float, direction_: Vector3) -> void:
		self.point = point_
		self.offset = offset_
		self.direction = direction_


func closest_point(reference: Vector3) -> PointOnCurve:
	var offset: float = curve.get_closest_offset(reference)
	var point: Vector3 = curve.sample_baked(offset, cubic_interpolation)
	var prev: Vector3 = curve.sample_baked(offset - 0.01, cubic_interpolation)
	var next: Vector3 = curve.sample_baked(offset + 0.01, cubic_interpolation)
	var direction: Vector3 = (next - prev).normalized()
	return PointOnCurve.new(point, offset, direction)

func split_off_suffix(offset: float, suffix_offset_shift: float = 0) -> PackedVector3Array:
	var new_point_kept: Vector3 = curve.sample_baked(offset, cubic_interpolation)
	var new_point_in_suffix: Vector3 = curve.sample_baked(offset + suffix_offset_shift, cubic_interpolation)
	var last_index_kept: int = 0
	var length_so_far: float = 0.0
	for i: int in range(1, points.size()):
		var point: Vector3 = points[i]
		var prev_point: Vector3 = points[i - 1]
		length_so_far += point.distance_to(prev_point)
		if length_so_far >= offset:
			last_index_kept = i - 1
			break
	
	var new_points: PackedVector3Array = PackedVector3Array()
	new_points.append(new_point_in_suffix)
	for i: int in range(points.size() - 1, last_index_kept, -1):
		new_points.append(points[i])
		points.remove_at(i)

	points.append(new_point_kept)
	return new_points

func get_clockwiseness() -> int:
	if clockwiseness != 0:
		return clockwiseness
	if points.size() < 3:
		return 0
	var p1: Vector2 = Vector2(points[0].x, points[0].y)
	var p2: Vector2 = Vector2(points[1].x, points[1].y)
	var p3: Vector2 = Vector2(points[2].x, points[2].y)
	var dir: Vector2 = (p3 - p1).normalized()
	var test_point: Vector2 = p2 + dir.rotated(-PI / 2) * 0.001
	var test_point2: Vector2 = p2 + dir.rotated(PI / 2) * 0.001
	var result: int = 0
	var winding_number: int = get_raw_winding_number(test_point)
	var winding_number2: int = get_raw_winding_number(test_point2)
	if winding_number != 0:
		result = 1
	elif winding_number2 != 0:
		result = -1
	clockwiseness = result
	return result

func get_raw_winding_number(point: Vector2) -> int:
	if not looped:
		Global.LogError("SnakeMesh.get_raw_winding_number called on non-looping mesh, this is not supported.")
		return 0
	var winding_number: int = 0
	for i: int in range(points.size()):
		var p1: Vector2 = Vector2(points[i].x, points[i].y)
		var p2: Vector2 = Vector2(points[(i + 1) % points.size()].x, points[(i + 1) % points.size()].y)
		if (p1.y <= point.y and p2.y > point.y) or (p2.y <= point.y and p1.y > point.y):
			if abs(p2.y - p1.y) > 1e-10:
				var x_intersection: float = p1.x + (point.y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
				if x_intersection > point.x:
					winding_number += 1 if p2.y > p1.y else -1
	return winding_number

func contains_2dpoint(point: Vector2) -> bool:
	if not looped:
		Global.LogError("SnakeMesh.contains_2dpoint called on non-looping mesh, this is not supported.")
		return false
	var winding_number: int = get_raw_winding_number(point)
	return winding_number != 0

# TODO: Ermith test if this works
func contains_world_coordinates_2dpoint(point: Vector2) -> bool:
	if not looped:
		Global.LogError("SnakeMesh.contains_world_coordinates_2dpoint called on non-looping mesh, this is not supported.")
		return false
	point -= Vector2(global_position.x, global_position.y)
	return contains_2dpoint(point)