extends ScreenBase
class_name PauseableScreenBase
# This screen will work even if the game is paused.

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
