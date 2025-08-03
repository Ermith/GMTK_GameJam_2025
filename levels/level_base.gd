extends Node3D
class_name LevelBase

@export var PreferredUI: UI.Mode = UI.Mode.NONE
@onready var player_snake: Player = $PlayerSnake

func _ready() -> void:
	Global.GetUIManager()._switch_UI(PreferredUI)
