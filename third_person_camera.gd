extends Camera3D


@onready var to = $"../CameraPos2"
@onready var from = $"../CameraPos"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = global_position.move_toward(from.global_position, delta * 50.0)
	global_position = from.global_position
	look_at(to.global_position)
