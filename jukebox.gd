extends Node


@onready var action_volume = $ActionMusic.volume_db

var tween
# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.jail.connect(on_jail)
	EventBus.restart.connect(on_restart)
	EventBus.game_over.connect(on_game_over)
	$Ambient.play()
	$ActionMusic.play()

func on_restart():
	if tween:
		tween.kill()
	$ActionMusic.volume_db = action_volume
	$ActionMusic.play()
	$Ambient.play()

func on_game_over():
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property($ActionMusic, "volume_db", action_volume - 10.0, 3.0)
	
func on_jail(f):
	$Ambient.stop()
	$ActionMusic.stop()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
