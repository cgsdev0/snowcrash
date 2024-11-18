extends Camera3D


@onready var to = $"../CameraPos2"
@onready var from = $"../CameraPos"

# Called when the node enters the scene tree for the first time.
func _ready():
	look_at_from_position(from.global_position, to.global_position)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	global_position = global_position.lerp(from.global_position, delta * 10.0)
	look_at(to.global_position)
