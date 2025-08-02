extends MeshInstance3D
class_name SnakeMesh

@export var points: PackedVector3Array = PackedVector3Array()
@export var radius: float = 0.2
@export var ring_interval: float = 0.2
@export var ring_segments: int = 8
@export var tail_length: float = 1.0
@export var curve_param: float = 0.8
@export var cubic_interpolation: bool = true
@export var bake_interval: float = INF
@export var head_facing: Vector3 = Vector3(0, 0, 0)

var curve: Curve3D

func _ready() -> void:
	curve = Curve3D.new()
	curve.set_bake_interval(bake_interval)
	refresh()

func debug_draw_curve() -> void:
	var debug_mesh: ImmediateMesh = ImmediateMesh.new()
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var baked_points: PackedVector3Array = curve.get_baked_points()
	for point: Vector3 in baked_points:
		debug_mesh.surface_add_vertex(point)
	debug_mesh.surface_end()
	debug_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(points.size()):
		# triangle perpendicular to the curve
		var p1: Vector3 = points[i]
		var direction: Vector3 = Vector3(0, 0, 0)
		if i < points.size() - 1:
			direction = (points[i + 1] - p1).normalized()
		elif i > 0:
			direction = (p1 - points[i - 1]).normalized()
		var up_vector: Vector3 = Vector3(0, 1, 0).cross(direction).normalized()
		var right_vector: Vector3 = direction.cross(up_vector).normalized()
		debug_mesh.surface_add_vertex(p1 + right_vector * radius)
		debug_mesh.surface_add_vertex(p1 - right_vector * radius)
		debug_mesh.surface_add_vertex(p1 + up_vector * radius)
	debug_mesh.surface_end()
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.cull_mode = StandardMaterial3D.CULL_DISABLED
	material_override = mat
	mesh = debug_mesh

func refresh() -> void:
	refresh_curve()
	refresh_mesh()
	# debug_draw_curve()

func refresh_curve() -> void:
	if points.size() < 2:
		return
	curve = Curve3D.new()
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
	var snake_length: float =  curve.get_baked_length()
	var result: float = radius
	var distance_from_tail: float = snake_length * t
	if distance_from_tail < tail_length:
		var p: float = distance_from_tail / tail_length
		result *= (3 * p * p - 2 * p * p * p)
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
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices

	var baked_points: BakedPoints = get_baked_points()
	#var baked_up_vectors: PackedVector3Array = curve.get_baked_up_vectors()

	var tail_vertex_index: int = 0
	verts.append(baked_points.points[0])
	normals.append((baked_points.points[0] - baked_points.points[1]).normalized())
	uvs.append(Vector2(0, 0))
	var head_center: Vector3 = baked_points.points[-1]
	var head_vertex_index: int = 1
	verts.append(head_center + head_facing.normalized() * radius_function(1.0))
	normals.append((baked_points.points[-1] - baked_points.points[-2]).normalized())
	uvs.append(Vector2(1, 0))

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
			
			if index == 1:
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
