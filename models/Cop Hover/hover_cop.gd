extends Node3D


@export var offset = 0.0


var t = 0.0
func _process(delta):
	t += delta
	$Node.position.y = sin(t * 2.0 + offset) * 0.2
