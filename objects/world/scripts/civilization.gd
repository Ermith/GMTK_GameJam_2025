extends Node3D
class_name Civilization

var owned_stars: Array[Star]
var frontier: Array[Star]
var inner_stars: Array[Star]
var color: Color

@export var expansion_period: float = 5.0
var expansion_timer: float

func initizlize(star: Star, in_color: Color) -> void:
	owned_stars.append(star)
	frontier.append(star)
	color = in_color
	star.civilize(self)

func _ready() -> void:
	expansion_timer = expansion_period

func _process(delta: float) -> void:
	expansion_timer -= delta
	if expansion_timer < 0.0:
		expansion_timer = expansion_period
		expand()

func expand() -> void:
	cleanup_frontier()
	if frontier.is_empty():
		return
	
	var random_index: int = randi() % frontier.size()
	for neighbor: Star in frontier[random_index].neightbors:
		neighbor.civilize(self)
		if neighbor.can_expand():
			frontier.append(neighbor)
		
	frontier.remove_at(random_index)

func cleanup_frontier() -> void:
	var to_remove: Array[Star]
	for star: Star in frontier:
		if not star.can_expand():
			to_remove.append(star)
	
	for star: Star in to_remove:
		frontier.erase(star)
