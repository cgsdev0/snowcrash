extends Node3D


func slam():
	EventBus.jail.emit(true)
	

func _ready():
	EventBus.jail.connect(on_jail)
	
func on_jail(show):
	$AnimationPlayer.play("RESET")
	$"../char".visible = show
	$"../dead".visible = !show
	if !show:
		$Lose.play()
		$"../dead".flicker()
	else:
		$AnimationPlayer.play("slam")
		$LoseSlam.play()
	$"../Camera3D".current = true
