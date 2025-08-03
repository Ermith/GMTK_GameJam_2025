extends Node
class_name SoundQueueItem

var clip_path: String
var volume_mult: float

func _init(clip: String, volume_multiplier: float) -> void:
	clip_path = clip
	volume_mult = volume_multiplier
