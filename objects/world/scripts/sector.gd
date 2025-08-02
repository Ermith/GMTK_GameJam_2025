class_name Sector

var random_pos: Vector2
var ring: int
var min_angle: float
var max_angle: float
var min_radius: float
var max_radius: float
var neighbors: Array[Sector]
var star: Star
var spawn: bool = false

func modulo(x: float) -> float:
	return ((x / 360) - floor(x / 360)) * 360
	
func min_angle_mod() -> float: return modulo(min_angle)
func max_angle_mod() -> float: return modulo(max_angle)

func contains_angle(angle: float) -> bool:
	angle = modulo(angle)
	if min_angle_mod() < max_angle_mod():
		return angle >= min_angle_mod() and angle <= max_angle_mod()
	else:
		return angle >= min_angle_mod() or angle <= max_angle_mod()

func get_random_pos() -> Vector2:
	var angle_width: float = max_angle - min_angle
	var random_angle: float = min_angle + randf() * angle_width
	var dir: Vector2 = Vector2.UP.rotated(deg_to_rad(random_angle))
	
	var height: float = max_radius - min_radius
	var random_height: float = min_radius + randf() * height
	return dir * random_height

func connect_neighbors(neighbor: Sector) -> void:
	neighbors.append(neighbor)
	neighbor.neighbors.append(self)

func can_be_neighbors(neighbor: Sector) -> bool:
	if abs(neighbor.ring - ring) > 1:
		return false
	
	return \
		contains_angle(neighbor.min_angle) or\
		contains_angle(neighbor.max_angle) or\
		neighbor.contains_angle(min_angle) or\
		neighbor.contains_angle(max_angle)
