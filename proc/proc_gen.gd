extends Node3D

#gd4
# Add a WorldEnvironment, set New Enviornment with mode = custom color, e.g. #9bbbce

const RoadActor:PackedScene = preload("res://proc/road_actor.tscn")

## How far ahead of the camera will we let a new RoadPoint be added
@export var max_rp_distance: int = 200
## How much buffer around this max dist to avoid adding new RPs
## (this will also define spacing between RoadPoints)
@export var buffer_distance: int = 50

## Node used to calcualte distances
@export var target_node: NodePath

@onready var container: RoadContainer = get_node("RoadManager/Road_001")
@onready var vehicles:Node = get_node("RoadManager/vehicles")
@onready var target: Node = get_node_or_null(target_node)

var Guards = preload("res://proc/guards.tscn")

func _ready() -> void:
	var rev = [0, 0, 1, 1, 1, 2, 3].pick_random()
	var fwd = [2, 2, 2, 3, 3, 4].pick_random()
	var traffic_dir:Array[RoadPoint.LaneDir] = []
	for i in range(rev):
		traffic_dir.push_back(RoadPoint.LaneDir.REVERSE)
	for i in range(fwd):
		traffic_dir.push_back(RoadPoint.LaneDir.FORWARD)
	$RoadManager/Road_001/RP_002.traffic_dir = traffic_dir
	$RoadManager/Road_001/RP_001.traffic_dir = traffic_dir
	$RoadManager/Road_001.update_lane_seg_connections()
	call_deferred("fuck")

func fuck():
	spawn_vehicles_on_lane($RoadManager/Road_001/RP_001, 0)
	spawn_vehicles_on_lane($RoadManager/Road_001/RP_002, 0)
	
var initialized = false

func _physics_process(_delta: float) -> void:
	update_road(initialized)
		#$RoadManager/Road_001/RP_002/CSGPolygon3D.path_node = $RoadManager/Road_001/RP_002.get_node("edge_R").get_path()
	if !initialized:
		initialized = true

func xz_target_distance_to(_target: Node3D) -> float:
	var pos_a := Vector2(target.global_transform.origin.x, target.global_transform.origin.z)
	var pos_b := Vector2(_target.global_transform.origin.x, _target.global_transform.origin.z)
	return pos_a.distance_to(pos_b)


var pieces = 0
## Parent function responsible for processing this road.
func update_road(backward: bool) -> void:

	# Make sure the edges of the Road are all open.
	container.update_edges()
	# TODO: This is overkill as it refreshes all points, in the future we should
	# have the container connection tool handle the responsibility of updating
	# prior/next lane assignments of edge roadPoints so it happens automatically
	container.update_lane_seg_connections()

	if not container.edge_rp_locals:
		print("No edges to add")
		return

	# Iterate over all the RoadPoints with open connections.
	var rp_count:int = container.get_child_count()

	# Cache the initial edges, to avoid referencing export vars on container
	# that get updated as we add new RoadPoints
	var edge_list: Array = container.edge_rp_locals
	var edge_dirs: Array = container.edge_rp_local_dirs

	for _idx in range(len(edge_list)):
		var edge_rp:RoadPoint = container.get_node(edge_list[_idx])
		var dist := xz_target_distance_to(edge_rp)
		# print("Process loop %s with RoadPoint %s with dist %s" % [_idx, edge_rp, dist])
		if dist > max_rp_distance + buffer_distance * 1.5:
			# buffer * factor is to ensure buffer range is wider than the distance between rps,
			# to avoid flicker spawning
			if container.get_child_count() > 2:
				remove_rp(edge_rp)
		elif dist < max_rp_distance:
			var which_edge = edge_dirs[_idx]
			if which_edge == 1:
				pieces += 1
			if which_edge == 0 && backward:
				continue
			add_next_rp(edge_rp, which_edge)
		elif rp_count > 20:
			pass


## Manually clear prior/next points to ensure it gets fully disconnected
func remove_rp(edge_rp: RoadPoint) -> void:
	# No need to manually remove cars, as we use the default: RoadLane.auto_free_vehicles=true
	#despawn_cars(edge_rp)
	edge_rp.prior_pt_init = ""
	edge_rp.next_pt_init = ""
	# Defer to allow time to free cars first, if using despawn_cars above
	edge_rp.call_deferred("queue_free")

@onready var how_long = 5 # randi_range(7, 15)

## Add a new roadpoint in a given direction
func add_next_rp(rp: RoadPoint, dir: int) -> void:
	var mag = 1 if dir == RoadPoint.PointInit.NEXT else -1
	var flip_dir: int = RoadPoint.PointInit.NEXT if dir == RoadPoint.PointInit.PRIOR else RoadPoint.PointInit.PRIOR

	var new_rp := RoadPoint.new()
	var guards = Guards.instantiate()
	container.add_child(new_rp)

	# Copy initial things like lane counts and orientation
	new_rp.copy_settings_from(rp, true)

	# Placement of a new roadpoint with interval no larger than buffer,
	# to avoid flicker removal/adding with the culling system

	# Randomly rotate the offset vector slightly
	var _transform := new_rp.transform
	var random_angle: float = [0.0, 0.0, 0.0, 20.0, -20.0, 10.0, -10.0].pick_random()
	var next = null
	if pieces == how_long && dir == 1:
		random_angle = 0.0
		var off_side = [-1.0, 1.0].pick_random()
		guards.enable_ramp(off_side)
		next = Level.instantiate(0)
		next.to_murder = self
		get_parent().add_child(next)
		next.global_rotation = global_rotation
		next.global_rotation.y -= PI / 2.0 * off_side
		
	var rotation_axis := Vector3(0, 1, 0)
	_transform = _transform.rotated(rotation_axis, deg_to_rad(random_angle))

	var rand_y_offset:float = 0.0 # (randf() - 0.5) * 15
	var offset_pos:Vector3 = _transform.basis.z * buffer_distance * mag + Vector3.UP * rand_y_offset

	new_rp.transform.origin += offset_pos
	if next:
		next.global_position = new_rp.global_position - global_basis.z * 20.0
		next.global_position.y = global_position.y - 5.0

	# Finally, connect them together
	var res = rp.connect_roadpoint(dir, new_rp, flip_dir)
	if res != true:
		print("Failed to connect RoadPoint")
		return

	new_rp.add_child(guards)
	guards.global_transform = new_rp.global_transform
	spawn_vehicles_on_lane(rp, dir)

var Level = preload("res://proc/level.tscn")
var to_murder = null
		
func spawn_vehicles_on_lane(rp: RoadPoint, dir: int) -> void:
	# Now spawn vehicles
	var new_seg = rp.next_seg if dir == RoadPoint.PointInit.NEXT else rp.prior_seg
	if not is_instance_valid(new_seg):
		print("Invalid new segment")
		return
	var new_lanes = new_seg.get_lanes()
	for _lane in new_lanes:
		var spawn_car = func(rng: bool):
			if !is_instance_valid($RoadManager/Road_001):
				return
			if !is_instance_valid(rp):
				return
			var new_instance = RoadActor.instantiate()
			new_instance.container = $RoadManager/Road_001
			vehicles.add_child(new_instance)
			new_instance.agent.current_lane = _lane
			var parts = _lane.name.split("_")
			var lane_dir = 1 if parts[0][1] == "F" else 2
			var lane_idx = int(parts[0].substr(2))
			new_instance.lanes = rp.traffic_dir.count(lane_dir)
			new_instance.my_lane = lane_idx
			new_instance.total_lanes = rp.traffic_dir.size()
			new_instance.lane_dir = lane_dir
			var rand_offset = randf() * _lane.curve.get_baked_length()
			var rand_pos = _lane.curve.sample_baked(rand_offset if rng else _lane.curve.get_baked_length())
			new_instance.global_transform.origin = _lane.to_global(rand_pos)
			_lane.register_vehicle(new_instance)
		_lane.spawn_car = spawn_car
		_lane.spawn_car.call(true)

## Manual way to emvoe all vehicles registered to lanes of this RoadPoint,
## if we didn't use RoadLane.auto_free_vehicles = true
func despawn_cars(road_point:RoadPoint) -> void:
	var lanes:Array = []
	var any_valid := false
	for seg in [road_point.prior_seg, road_point.next_seg]:
		if not is_instance_valid(seg):
			continue
		# Any connected segment is about to be destroyed since this RP is going
		# away, so all adjacent vehicles should all be removed
		lanes.append_array(seg.get_lanes())
		any_valid = true
	if not any_valid:
		print("No segments valid for car despawning")
		return

	for _lane in lanes:
		var this_lane:RoadLane = _lane
		var lane_vehicles = this_lane._vehicles_in_lane #this_lane.get_vehicles()
		for _vehicle in lane_vehicles:
			print("Freeing vehicle ", _vehicle)
			_vehicle.queue_free()


func _on_murderer_body_entered(body):
	if to_murder:
		to_murder.queue_free()
		to_murder = null
