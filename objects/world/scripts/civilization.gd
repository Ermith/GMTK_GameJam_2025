extends Node3D
class_name Civilization

var owned_stars: Array[Star]
var frontier: Array[Star]
var inner_stars: Array[Star]
var color: Color
var _player: Player

@export var expansion_period: float = 7.5
var expansion_timer: float

func initizlize(star: Star, in_color: Color, player: Player) -> void:
	owned_stars.append(star)
	frontier.append(star)
	color = in_color
	star.civilize(self)
	_player = player

func _ready() -> void:
	expansion_timer = expansion_period

func _process(delta: float) -> void:
	expansion_timer -= delta
	if expansion_timer < 0.0:
		expansion_timer = expansion_period
		expand()
	
	cleanup_stars(owned_stars, false)
	if owned_stars.is_empty():
		_player.game_stats.remaining_length += 10
		queue_free()
		return

func expand() -> void:
	# BECAUSE FUCKING LEAK INVALID VALUES WTF
	cleanup_stars(frontier, true)
	cleanup_stars(owned_stars, false)
	cleanup_stars(inner_stars, false)
	
	if owned_stars.is_empty():
		queue_free()
		return
	
	if frontier.is_empty():
		return
	
	var random_index: int = randi() % frontier.size()
	
	for neighbor: Star in frontier[random_index].neightbors:
		neighbor.civilize(self)
	
	inner_stars.append(frontier[random_index])
	frontier.remove_at(random_index)

func cleanup_stars(stars: Array[Star], cleanup_non_expandable: bool) -> void:
	var index: int = 0
	while index < len(stars):
		if not is_instance_valid(stars[index]) or (cleanup_non_expandable and not stars[index].can_expand()):
			# STAR NOT FUCKING VALID WTF I FUCKING CANT (handled but WHY?!)
			stars.remove_at(index)
		else:
			index += 1

func remove_star(star: Star) -> void:
	owned_stars.erase(star)
	frontier.erase(star)
	inner_stars.erase(star)
