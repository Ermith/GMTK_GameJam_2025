extends Node
# Manages transitions between levels & screens
# class_name GameInstance #Defined as autoloaded Global

# Opted for enum, this makes it less likely to miss-spell 
enum GameLevels {
	MENU,
	GAME,
	TEST
}

@export var CurrentLevel: GameLevels = GameLevels.MENU
# Levels
@export var Levels: Dictionary[GameLevels, String] = {
	GameLevels.MENU: "res://levels/main_menu_level.tscn",
	GameLevels.GAME: "res://levels/game_level.tscn",
	GameLevels.TEST: "res://levels/snake_test.tscn",
}

@export var LevelTransitions: Dictionary[GameLevels, GameLevels] = {
}

@export var CinematicTransitions: Dictionary[GameLevels, bool] = {
}

var preloaded_next_level: PackedScene = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().min_size = Vector2i(1152, 648)

func _notification(what: int) -> void:
	match what:
		#NOTIFICATION_APPLICATION_FOCUS_IN:
		#	ResumeGame()
		# This handles special case, where user can bug the game window out of screenscape
		# as by default game prevents correct moving of window by unintentionally controlling all mouse events
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			#var manager: UIManagerScript = UIManager
			if Global.GetUIManager().IsGame():
				PauseGame()

func _unhandled_input(event: InputEvent) -> void:
	if _try_handle_pause(event):
		return
	if _try_handle_debug(event):
		return

func _try_handle_pause(event: InputEvent) -> bool:
	# We only need to process the navigation between HUD and PAUSE, thus in non menu level.
	# Additionally, we have to exclude win and lose screens
	if not event.is_action_pressed("pause") or not _can_pause():
		return false
	if _is_paused():
		ResumeGame()
	else:
		PauseGame()
	return true
		
func _try_handle_debug(event: InputEvent) -> bool:
	if not event.is_action_pressed("debug") or not Global.enable_debug:
		return false
	# Swift debug tricks here

	return true
		
func _can_pause() -> bool:
	return CurrentLevel != GameLevels.MENU and Global.GetUIManager().IsPauseable()

func _is_paused() -> bool:
	Global.LogInfo(get_tree().get_current_scene())
	return get_tree().paused
	
func _resume() -> void:
	get_tree().paused = false
	
func _pause() -> void:
	get_tree().paused = true

func PlayerDefeated() -> void:
	Global.GetUIManager().SwitchToMode(UI.Mode.DEFEAT)
	_pause()
	
func PlayerVictorious() -> void:
	if CanTravelToNextLevel() and CanCinematic():
		PreloadNextLevel()
		Global.emit_signal("level_end")
		return
	else:
		Global.GetUIManager().SwitchToMode(UI.Mode.VICTORY)
	_pause()
	return

func PreloadNextLevel() -> void:
	preloaded_next_level = ResourceLoader.load(Levels[LevelTransitions[CurrentLevel]])

# Level transition should move player to menu level and set UI as MENU
func TravelToMenu(new_level: GameLevels = GameLevels.MENU) -> void:
	CurrentLevel = new_level
	get_tree().change_scene_to_file(Levels[new_level])
	Global.GetUIManager().SwitchToMode(UI.Mode.MENU)
	_resume()
	
# Level transition should move player to new level and set UI as HUD
func TravelToLevel(new_level: GameLevels) -> void:
	if preloaded_next_level:
		get_tree().change_scene_to_packed(preloaded_next_level)
		preloaded_next_level = null
	else:
		get_tree().change_scene_to_file(Levels[new_level])
	CurrentLevel = new_level
	Global.GetUIManager().SwitchToMode(UI.Mode.HUD)
	_resume()

# This returns value based on CurrentLevel being in LevelTransitions
func CanTravelToNextLevel() -> bool:
	return LevelTransitions.has(CurrentLevel)

func CanCinematic() -> bool:
	return CinematicTransitions.get(CurrentLevel, false)

# This requires some basic setup, see LevelTransitions
func TravelToNextLevel() -> void:
	if not CanTravelToNextLevel():
		Global.LogError("UNVERIFIED ATTEMPT TO ACCESS NEXT LEVEL")
		return
	#Global.phase += 1
	TravelToLevel(LevelTransitions[CurrentLevel])

# Reload the last set scene
func RestartCurrentLevel() -> void:
	get_tree().reload_current_scene()
	Global.GetUIManager().SwitchToMode(UI.Mode.HUD)
	_resume()

func Quit() -> void:
	Global.GetUIManager().SwitchToMode(UI.Mode.NONE)
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func PauseGame() -> void:
	Global.GetUIManager().SwitchToMode(UI.Mode.PAUSE)
	_pause()
	
func ResumeGame() -> void:
	Global.GetUIManager().SwitchToPrevious()
	_resume()
