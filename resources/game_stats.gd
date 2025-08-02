extends Resource
class_name GameStats

signal length_changed

@export var base_speed: float = 1.5
@export var initial_length: float = 20.0

var _remaining_length: float = initial_length
var remaining_length: float:
	set(value):
		_remaining_length = value
		length_changed.emit()
	get:
		return _remaining_length
		
var _current_length: float = 0.0
var current_length: float:
	set(value):
		_current_length = value
		length_changed.emit()
	get:
		return _current_length

func reset() -> void:
	current_length = 0.0
	remaining_length = initial_length
