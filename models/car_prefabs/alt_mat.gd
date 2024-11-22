extends Node3D

@export var alt: StandardMaterial3D

# Called when the node enters the scene tree for the first time.
func _ready():
	if randi_range(0, 1) == 0:
		for c in find_children("*"):
			if c.has_method("set_surface_override_material"):
				c.set_surface_override_material(0, alt)
