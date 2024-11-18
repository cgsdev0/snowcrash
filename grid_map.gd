extends GridMap


@onready var bend = preload("res://traffic/bend.tscn")
@onready var straight = preload("res://traffic/straight.tscn")

func _ready():
	for cell in get_used_cells():
		var pos = Vector3i(cell.x, cell.y, cell.z)
		var item = get_cell_item(pos)
		match item:
			0:
				_add_traffic_nodes(pos, bend)
			2, 8, 9, 16, 17, 18, 26:
				_add_traffic_nodes(pos, straight)

func _add_traffic_nodes(pos, traffic_node):
	var traffic_node_instance = traffic_node.instantiate()
	add_child(traffic_node_instance)
	traffic_node_instance.position = map_to_local(pos)
	traffic_node_instance.basis = get_cell_item_basis(pos)
