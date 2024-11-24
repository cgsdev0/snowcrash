extends Node3D


func slam():
	$"../dead".visible = false
	$"../char".visible = true
	$LoseSlam.play()
	$AnimationPlayer.play("slam")

func _ready():
	EventBus.jail.connect(on_jail)
	
func on_jail(show):
	$"../char".visible = show
	$"../dead".visible = !show
	if !show:
		$"../dead".flicker()
	$"../Camera3D".current = true
	$Lose.play()
