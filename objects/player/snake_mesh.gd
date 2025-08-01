extends MeshInstance3D
class_name SnakeMesh

@export var points: PackedVector3Array = PackedVector3Array()
@export var radius: float = 0.2
@export var ring_interval: float = 0.05
@export var ring_segments: int = 8
@export var head_length: float = 0.2
@export var tail_length: float = 1.0
@export var curve_param: float = 0.5

var curve: Curve3D

func _ready() -> void:
	curve = Curve3D.new()
	curve.set_bake_interval(ring_interval)
	refresh()

func debug_draw_curve() -> void:
	var debug_mesh: ImmediateMesh = ImmediateMesh.new()
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var baked_points: PackedVector3Array = curve.get_baked_points()
	for point: Vector3 in baked_points:
		debug_mesh.surface_add_vertex(point)
	debug_mesh.surface_end()
	mesh = debug_mesh

func add_point(point: Vector3) -> void:
	points.append(point)
	refresh()

func refresh() -> void:
	refresh_curve()
	refresh_mesh()

func refresh_curve() -> void:
	curve = Curve3D.new()
	curve.set_bake_interval(ring_interval)
	for i: int in range(points.size()):
		var direction: Vector3 = Vector3.ZERO
		if i == 0:
			direction = points[i + 1] - points[i]
		elif i == points.size() - 1:
			direction = points[i] - points[i - 1]
		else:
			direction = points[i + 1] - points[i - 1]
		direction = direction.normalized()
		var out_vector: Vector3 = direction * curve_param
		curve.add_point(points[i], -out_vector, out_vector)

func radius_function(t: float) -> float:
	var snake_length: float =  curve.get_baked_length()
	var distance_from_head: float = snake_length * (1.0 - t)
	if distance_from_head < head_length:
		var p: float = 1.0 - distance_from_head / head_length
		return radius * sqrt(1 - p * p)
	var distance_from_tail: float = snake_length * t
	if distance_from_tail < tail_length:
		var p: float = distance_from_tail / tail_length
		return radius * (3 * p * p - 2 * p * p * p)
	return radius

func refresh_mesh() -> void:
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

	var baked_points: PackedVector3Array = curve.get_baked_points()
	var baked_up_vectors: PackedVector3Array = curve.get_baked_up_vectors()

	var tail_vertex_index: int = 0
	verts.append(baked_points[0])
	normals.append((baked_points[0] - baked_points[1]).normalized())
	uvs.append(Vector2(0, 0))
	var head_vertex_index: int = 1
	verts.append(baked_points[-1])
	normals.append((baked_points[-1] - baked_points[-2]).normalized())
	uvs.append(Vector2(1, 0))

	for index: int in range(1, baked_points.size() - 1):
		var current_point: Vector3 = baked_points[index]
		var next_point: Vector3 = baked_points[index + 1]
		var prev_point: Vector3 = baked_points[index - 1]
		var direction: Vector3 = (next_point - prev_point).normalized()
		var up_vector: Vector3 = baked_up_vectors[index]
		# backup solution
		#var blargh: Vector3 = Vector3(0, 0, -1).cross(direction).normalized()
		#var up_vector: Vector3 = blargh.cross(direction).normalized()
		var t: float = index / float(baked_points.size() - 1)

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

			if index == baked_points.size() - 2:
				indices.append(head_vertex_index)
				indices.append(base_vertex_index + i)
				indices.append(base_vertex_index + (i + 1) % ring_segments)

	var array_mesh: ArrayMesh = mesh as ArrayMesh
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
