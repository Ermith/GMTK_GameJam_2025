extends LevelBase

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	# player_snake.camera.position.z = 10.0 - cos(time / 10.0) * 7
