extends Node3D
class_name LevelBase

@export var PreferredUI: UI.Mode = UI.Mode.NONE
@onready var player_snake: Player = $PlayerSnake

func _ready() -> void:
	Global.GetUIManager()._switch_UI(PreferredUI)

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	player_snake.camera.position.z = 10.0 - cos(time / 10.0) * 7
