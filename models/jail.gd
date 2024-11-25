extends Node3D


func slam():
	EventBus.jail.emit(true)
	
func on_restart():
	$AnimationPlayer.play("RESET")

func _ready():
	EventBus.jail.connect(on_jail)
	EventBus.restart.connect(on_restart)
	
func on_jail(show):
	$"../char".visible = show
	$"../dead".visible = !show
	if !show:
		$Lose.play()
		$Flicker.play()
		$"../dead".flicker()
	else:
		$AnimationPlayer.play("slam")
		$LoseSlam.play()
	$"../Camera3D".current = true
