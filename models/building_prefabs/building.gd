extends Node3D


@export var mesh: NodePath
@export var alt: StandardMaterial3D
var signs = []
func _ready():
	if !mesh.is_empty() && randi_range(0, 1) == 0:
		get_node(mesh).set_surface_override_material(0, alt)
	signs = find_children("Sign*")
	for sign in signs:
		sign.visible = randi_range(0, 1)
		if sign.visible:
			for c in sign.get_children():
				c.shuffle()

var dead = false	
func _physics_process(delta):
	if $StaticBody3D/Area3D.is_colliding():
		var who = $StaticBody3D/Area3D.get_collider(0)
		if is_instance_valid(who):
			var why = who.get_parent()
			if (!why.has_method("aw_dang_it") || why.dead != true):
				aw_dang_it()

func aw_dang_it():
	dead = true
	hide()
	queue_free()
