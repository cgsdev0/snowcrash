extends Node3D


var signs = []
func _ready():
	signs = find_children("Sign*")
	for sign in signs:
		sign.visible = randi_range(0, 1)
		if sign.visible:
			sign.get_node("Sprite3D").shuffle()
		
func _physics_process(delta):
	if $Area3D.is_colliding():
		print($Area3D.get_collider(0))
		aw_dang_it()

func aw_dang_it():
	hide()
	queue_free()
