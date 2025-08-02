extends GameScreenBase
class_name GameHudScreen

@onready var current_label: Label = $PanelContainer/VBoxContainer/CurrentLabel
@onready var remaining_label: Label = $PanelContainer/VBoxContainer/RemainingLabel
@onready var progress_bar: ProgressBar = $PanelContainer/VBoxContainer/ProgressBar

@export var game_stats: GameStats = preload("res://resources/game_stats.tres")

func _ready() -> void:
	game_stats.length_changed.connect(update_snake_stats)
	update_snake_stats()

func update_snake_stats() -> void:
	current_label.text = String.num(game_stats.current_length, 2)
	remaining_label.text =  String.num(game_stats.remaining_length, 2)
	
