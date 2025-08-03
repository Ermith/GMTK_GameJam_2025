extends Control
class_name ScreenBase
# Common parent for all screens

func _ready()->void:
	var buttons: Array = get_tree().get_nodes_in_group("Button")
	for inst: Button in buttons:
		inst.pressed.connect(on_button_pressed)
		inst.mouse_entered.connect(on_button_mouse_entered)

func on_button_pressed()->void:
	AudioClipManager.play("res://sounds/sfx/FUI_Ease_Into-Position.mp3", 0.6)

func on_button_mouse_entered()->void:
		AudioClipManager.play("res://sounds/sfx/Bluezone_BC0303_futuristic_user_interface_high_tech_beep_038.wav", 0.01)
