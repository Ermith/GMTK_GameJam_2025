extends Node

var num_players: int = 8
var bus: String = "master"

var available: Array[AudioStreamPlayer] = []
var queue: Array[SoundQueueItem] = []

var masterVolume: float = 1.0
var sfxVolume: float = 1.0
var musicVolume: float = 1.0

signal volume_settings_changed (newMaster: float, newMusic: float, newSfx: float)

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:    
	for i: int in num_players:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		available.append(player)
		player.volume_linear = 1.0
		player.bus = bus
		player.finished.connect(_on_stream_finished.bind(player, player.volume_linear))
		
func _on_stream_finished(stream: AudioStreamPlayer, base_volume: float) -> void:   
	available.append(stream)
	stream.volume_linear = base_volume
	
func play(sound_path: String, volumeMultiplier: float = 1.0) -> void:
	queue.append(SoundQueueItem.new(sound_path, volumeMultiplier))
	
func set_volume_multipliers(master: float, music: float, sound: float) -> void:
	masterVolume = master
	musicVolume = music
	sfxVolume = sound
	
	volume_settings_changed.emit(masterVolume, musicVolume, sfxVolume)
	
func _process(_delta: float) -> void:
	if not queue.is_empty() and not available.is_empty():
		var q_element: SoundQueueItem = queue.pop_front()
		var clip_path: String = q_element.clip_path
		var volume_mult: float = q_element.volume_mult
		var assigned_stream: AudioStreamPlayer = available[0]
		assigned_stream.stream = load(clip_path)
		assigned_stream.volume_linear *= volume_mult * masterVolume * sfxVolume
		assigned_stream.play()
		available.pop_front()
