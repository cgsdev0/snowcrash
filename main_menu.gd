extends NinePatchRect


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	visible = EventBus.phase == EventBus.GamePhase.MAIN_MENU
	pass


func _on_quit_pressed():
	get_tree().quit()


func _on_credits_pressed():
	EventBus.phase = EventBus.GamePhase.CREDITS


func _on_start_pressed():
	EventBus.phase = EventBus.GamePhase.INTRO
	EventBus.game_start.emit()


func _on_fullscreen_pressed():
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)



func _on_fullscreen_mouse_entered():
	EventBus.easter_egg = true

func _on_fullscreen_mouse_exited():
	EventBus.easter_egg = false


func _on_quit_mouse_entered():
	EventBus.sad = true


func _on_quit_mouse_exited():
	EventBus.sad = false
