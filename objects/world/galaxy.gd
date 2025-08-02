extends Node3D
const STAR: PackedScene = preload("res://objects/world/star.tscn")

class Sector:
	var random_pos: Vector2
	var ring: int
	var min_angle: float
	var max_angle: float
	var min_radius: float
	var max_radius: float
	
	func get_random_pos() -> Vector2:
		var angle_width: float = max_angle - min_angle
		var random_angle: float = min_angle + randf() * angle_width
		var dir: Vector2 = Vector2.UP.rotated(deg_to_rad(random_angle))
		
		var height: float = max_radius - min_radius
		var random_height: float = min_radius + randf() * height
		return dir * random_height

func disc_area(radius: float) -> float: return radius * radius * PI

func ring_area(ring: int, radius_min: float, ring_height: float) -> float:
	var inner_disc_area: float = disc_area(radius_min + ring_height * ring)
	var outer_disc_area: float = disc_area(radius_min + ring_height * (ring + 1))
	return outer_disc_area - inner_disc_area

func calculate_sectors(radius: float, radius_min: float, rings: int, first_ring_segments: int) -> Array[Sector]:
	var out_sectors: Array[Sector]
	
	var radius_diff: float = radius - radius_min
	var ring_height: float = radius_diff / rings
	var ideal_sector_area: float = ring_area(0, radius_min, ring_height) / first_ring_segments
	
	for ring_index: int in rings:
		var current_ring_area: float = ring_area(ring_index, radius_min, ring_height)
		var sector_count: int = round(current_ring_area / ideal_sector_area)
		var sector_width: float = 360.0 / sector_count
		
		for sector_index: int in range(sector_count):
			var sector_angle_offset: float = sector_width * sector_index
			var sector: Sector = Sector.new()
			sector.min_angle = sector_angle_offset - sector_width / 2.0
			sector.max_angle = sector_angle_offset + sector_width / 2.0
			sector.min_radius = radius_min + ring_height * ring_index
			sector.max_radius = radius_min + ring_height * (ring_index + 1)
			out_sectors.append(sector)
		
	return out_sectors

func _ready() -> void:
	var sectors: Array[Sector] = calculate_sectors(2.0, 0.5, 5, 30)
	for i: int in range(1):
		for sector: Sector in sectors:
			var pos: Vector2 = sector.get_random_pos()
			var star: Star = STAR.instantiate()
			add_child(star)
			star.global_position = Vector3(pos.x, pos.y, 0.0)
			#star.set_color(Color.from_hsv(randf(), 1.0, 1.0))
			star.set_color(Color.SKY_BLUE)
