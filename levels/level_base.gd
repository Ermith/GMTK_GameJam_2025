extends Node3D
class_name LevelBase

@export var PreferredUI: UI.Mode = UI.Mode.NONE

func _ready() -> void:
	Global.GetUIManager()._switch_UI(PreferredUI)
