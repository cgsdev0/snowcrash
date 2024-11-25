extends Node2D


@onready var player = %Player
@export var draw_color: Color = Color.GREEN
@export var warn_color: Color = Color.RED
@export var cooldown_color: Color = Color.ORANGE
# Called when the node enters the scene tree for the first time.
func _ready():
	$DistLabel.add_theme_color_override("font_color", draw_color)
	pass # Replace with function body.


var indicator_dist = 18
var targeting = null
var eligible = false

func raycast_from_mouse(m_pos, collision_mask):
	var cam = get_viewport().get_camera_3d()
	var ray_start = cam.project_ray_origin(m_pos)
	var ray_end = ray_start + cam.project_ray_normal(m_pos) * player.ray_length * 2.0
	var world3d : World3D = player.get_world_3d()
	var space_state = world3d.direct_space_state
	
	if space_state == null:
		return
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	if result && result.position:
		targeting = result.collider
		eligible = (result.position - cam.global_position).length() <= player.ray_length
		indicator_dist = (targeting.global_position - cam.global_position).length()
		return
	
var targets = []
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	raycast_from_mouse(get_window().get_mouse_position(), 4)
	targets = get_tree().get_nodes_in_group("HUD_target")
	queue_redraw()

func _draw():
	if player.hooked || player.arrested:
		$DistLabel.hide()
		targeting = null
		return
	var cam = get_viewport().get_camera_3d()
	if !is_instance_valid(targeting):
		targeting = null
	else:
		indicator_dist = (targeting.global_position - cam.global_position).length()
		eligible = (targeting.global_position - cam.global_position).length() <= player.ray_length
		if !cam.is_position_in_frustum(targeting.global_position):
			targeting = null
	var farthest = null
	var max_dist = 0.0
	var max_dist2 = 0.0
	if targeting:
		max_dist = indicator_dist
		farthest = targeting
		max_dist2 = farthest.global_position.distance_to(player.global_position)
	else:
		eligible = true
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
	
	var use_color = (draw_color if player.can_hook() else cooldown_color) if eligible else warn_color
	$DistLabel.add_theme_color_override("font_color", use_color)
	
	if farthest != null:
		$DistLabel.show()
		var t = farthest.global_position + Vector3.UP * 0.6
		var dist = t.distance_to(player.global_position)
		$DistLabel.text = "%sm" % str(floor(dist))
		var screen_pos = cam.unproject_position(t)
		var size = Vector2(44.0, 44.0) / max_dist * 32.0
		var w = size.x
		var top_left = screen_pos - size / 2.0
		var rect = Rect2(top_left, size)
		draw_rect(rect, use_color, false, 2.0)
		var corner = top_left + Vector2(w * 0.25, -12.0)
		draw_line(top_left + Vector2(w * 0.25, 0.0), corner, use_color, 1.0)
		var next = corner - Vector2(8.0, 8.0)
		draw_line(corner, next, use_color, 1.0)
		size = Vector2(32.0, 12.0)
		top_left = next - Vector2(size.x + 1.0, size.y / 4.0)
		$DistLabel.global_position = top_left + Vector2(2.0, -1.0)
		draw_rect(Rect2(top_left, size), use_color, false, 1.0)
	else:
		$DistLabel.hide()
