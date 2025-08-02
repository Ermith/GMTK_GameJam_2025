extends PauseableScreenBase
class_name VictoryScreen 

func _on_restart_button_pressed() -> void:
	GameInstance.TravelToLevel(GameInstance.GameLevels.GAME)

func _on_menu_button_pressed() -> void:
	GameInstance.TravelToMenu()
