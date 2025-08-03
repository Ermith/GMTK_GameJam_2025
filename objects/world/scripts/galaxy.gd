extends Node3D

@export var STAR: PackedScene
@export var HYPER_LANE: PackedScene
@export var CIVILIZATION: PackedScene
@export var civilization_spawn_colors: Array[Color]
@export var star_height_dev: float = 0.4

var stars: Array[Star]

func disc_area(radius: float) -> float: return radius * radius * PI

func ring_area(ring: int, radius_min: float, ring_height: float) -> float:
	var inner_disc_area: float = disc_area(radius_min + ring_height * ring)
	var outer_disc_area: float = disc_area(radius_min + ring_height * (ring + 1))
	return outer_disc_area - inner_disc_area

func calculate_sectors(radius: float, radius_min: float, rings: int, first_ring_segments: int) -> Array[Sector]:
	var out_sectors: Array[Sector]
	var non_spawn_sectors: Array[Sector]
	
	var civilization_rings: Array[int]
	var civilization_angles: Array[float]
	var civilization_spawn_count: int = civilization_spawn_colors.size()
	for i: int in range(civilization_spawn_count):
		civilization_rings.append(i)
		civilization_angles.append((360.0 / civilization_spawn_count) * i)
	civilization_rings.shuffle()
	
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
			sector.ring = ring_index
			out_sectors.append(sector)
			
			var civilization_index: int = civilization_rings.find(ring_index)
			if civilization_index != -1 and\
				sector.contains_angle(civilization_angles[civilization_index]):
					sector.spawn = true
					civilization_rings.remove_at(civilization_index)
					civilization_angles.remove_at(civilization_index)
			else:
				non_spawn_sectors.append(sector)
				
	for i: int in range(civilization_rings.size()):
		var random_index: int = randi() % non_spawn_sectors.size()
		non_spawn_sectors[random_index].spawn = true
		non_spawn_sectors.remove_at(random_index)
	
	return out_sectors

func _ready() -> void:
	var sectors: Array[Sector] = calculate_sectors(7.0, 1.3, 8, 15)
	for i: int in range(1):
		for sector: Sector in sectors:
			var pos: Vector2 = sector.get_random_pos()
			var star: Star = STAR.instantiate()
			add_child(star)
			stars.append(star)
			star.global_position = Vector3(pos.x, pos.y, randf() * (2 * star_height_dev) - star_height_dev)
			#star.set_color(Color.from_hsv(randf(), 1.0, 1.0))
			star.set_color(Color.DEEP_SKY_BLUE)
			star.sector = sector
	
	for i: int in range(stars.size()):
		for j: int in range(stars.size()):
			
			if i == j:
				continue
			
			if not stars[i].sector.can_be_neighbors(stars[j].sector):
				continue

			if stars[i] in stars[j].neightbors:
				continue
				
			stars[i].neightbors.append(stars[j])
			stars[j].neightbors.append(stars[i])
			var hyper_lane: HyperLane = HYPER_LANE.instantiate()
			add_child(hyper_lane)
			hyper_lane.set_lane(stars[i], stars[j])
			stars[i].hyper_lanes.append(hyper_lane)
			stars[j].hyper_lanes.append(hyper_lane)
	
	var civilization_index: int = 0
	for star: Star in stars:
		if star.sector.spawn:
			var civilization: Civilization = CIVILIZATION.instantiate()
			civilization.initizlize(star, civilization_spawn_colors[civilization_index])
			civilization_index += 1
			add_child(civilization)
			


func _on_player_snake_looped(snake_mesh: SnakeMesh) -> void:
	var to_remove: Array[Star]
	for star:Star in stars:
		if snake_mesh.contains_world_coordinates_2dpoint(\
			Vector2(star.global_position.x, star.global_position.y)):
				to_remove.append(star)
	
	for star: Star in to_remove:
		stars.erase(star)
		star.destroy()
