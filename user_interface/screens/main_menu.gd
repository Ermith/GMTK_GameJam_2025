extends ScreenBase
class_name MainMenuScreen

func _on_play_button_pressed() -> void:
	GameInstance.TravelToLevel(GameInstance.GameLevels.GAME)

func _on_quit_button_pressed() -> void:
	GameInstance.Quit()
