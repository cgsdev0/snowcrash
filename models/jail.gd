extends Node3D


func slam():
	$LoseSlam.play()
	$AnimationPlayer.play("slam")

func _ready():
	EventBus.jail.connect(on_jail)
	
func on_jail(show):
	$"../char".visible = show
	$"../Camera3D".current = true
	$Lose.play()
