extends PathFollow3D

var leftover = 0
@onready var baked_length = get_parent().curve.get_baked_length()

func _process(delta):
	var diff = delta * .8
	
	if progress + diff > baked_length:
		leftover = (progress + diff) - baked_length
	progress += diff
	if $RayCast3D.get_collider() != null:
		new_path = $RayCast3D.get_collider()
	if progress_ratio == 1.0:
		find_new_path()

var new_path = null

func find_new_path():
	var old_path = self.get_parent()
	old_path.remove_child(self)
	if new_path != null:
		new_path.find_child("Path3D").add_child(self)
		baked_length = get_parent().curve.get_baked_length()
		new_path = null
		progress = leftover
