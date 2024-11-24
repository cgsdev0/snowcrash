extends Node2D


@onready var player = %Player
@export var draw_color: Color = Color.GREEN
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


var targets = []
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	targets = get_tree().get_nodes_in_group("HUD_target")
	queue_redraw()

func _draw():
	if !player.can_hook():
		return
	var cam = get_viewport().get_camera_3d()
	var farthest = null
	var max_dist = 0.0
	var max_dist2 = 0.0
	for target in targets:
		var dist = target.global_position.distance_to(cam.global_position)
		if dist > 32.0:
			continue
		var t = target.global_position + Vector3.UP * 0.6
		if !cam.is_position_in_frustum(t):
			continue
		if target.global_basis.z.normalized().dot(player.velocity.normalized()) > 0.0:
			continue
		var dist2 = target.global_position.distance_to(player.global_position)
		if dist2 < 5.0:
			continue
		if dist2 > max_dist2:
			max_dist = dist
			max_dist2 = dist2
			farthest = target
	
	if farthest != null:
		var t = farthest.global_position + Vector3.UP * 0.6
		var screen_pos = cam.unproject_position(t)
		var size = Vector2(44.0, 44.0) / max_dist * 32.0
		var rect = Rect2(screen_pos - size / 2.0, size)
		draw_rect(rect, draw_color, false, 2.0)
