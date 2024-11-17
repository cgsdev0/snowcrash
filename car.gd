extends PathFollow3D


func _process(delta):
	progress += delta * 1.5
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
		new_path = null
		progress_ratio = 0
