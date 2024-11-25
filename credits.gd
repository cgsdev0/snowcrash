extends NinePatchRect


# Called when the node enters the scene tree for the first time.
func _ready():
	$MarginContainer/VBoxContainer/RichTextLabel.meta_clicked.connect(on_click)
	pass # Replace with function body.

func on_click(meta):
	OS.shell_open(str(meta))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	visible = EventBus.phase == EventBus.GamePhase.CREDITS
	pass


func _on_back_pressed():
	EventBus.phase = EventBus.GamePhase.MAIN_MENU
