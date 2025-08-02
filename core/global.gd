extends Node
# class_name Global
# This is by default static.
# Do not place gameplay functionality here.

signal level_end
@export var enable_debug: bool = true

func GetUIManager() -> UIManagerScript:
	return (UIManager as UIManagerScript)

func LogInfo(log_content: Variant) -> void:
	print_rich("[color=white][INFO] ", log_content)
	
func LogError(log_content: Variant) -> void:
	print_rich("[color=red][ERROR] ", log_content)
