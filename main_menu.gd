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
