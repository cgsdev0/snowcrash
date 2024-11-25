extends Node


var tween
# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.jail.connect(on_jail)
	EventBus.restart.connect(on_restart)
	EventBus.game_over.connect(on_game_over)
	$MenuMusic.play()
	$Ambient.play()
	#$ActionMusic.play()

func on_restart():
	if tween:
		tween.kill()
	# $ActionMusic.pitch_scale = 1.0
	$ActionMusic.play()
	$Ambient.play()

func on_game_over():
	if tween:
		tween.kill()
	# tween = get_tree().create_tween()
	# tween.tween_property($ActionMusic, "pitch_scale", 0.0, 1.0)
	# print("stuff")
	
func on_jail(f):
	$Ambient.stop()
	$ActionMusic.stop()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if EventBus.phase != EventBus.GamePhase.MAIN_MENU && $MenuMusic.is_playing():
		$MenuMusic.stop()
		$ActionMusic.play()
