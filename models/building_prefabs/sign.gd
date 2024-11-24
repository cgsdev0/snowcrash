@tool
extends Sprite3D


enum SignType {
	SIGN_1x1,
	SIGN_2x3,
	SIGN_2x6,
	SIGN_8x3
}
@export var sign_type: SignType = SignType.SIGN_1x1
@export var i: int = 0  : set = _set_i

func _set_i(j):
	i = j
	update_atlas()

var meta = {
	SignType.SIGN_1x1: {
		"x": 5,
		"count": 10
	},
	SignType.SIGN_2x3: {
		"x": 4,
		"count": 9
	},
	SignType.SIGN_2x6: {
		"x": 8,
		"count": 24
	},
	SignType.SIGN_8x3: {
		"x": 3,
		"count": 18
	}
}

func update_atlas():
	var a: AtlasTexture = texture
	var w = meta[sign_type]["x"]
	var x = i % w
	var y = floor(i / w)
	a.region.position.x = a.region.size.x * x
	a.region.position.y = a.region.size.y * y
	
func _ready():
	update_atlas()
	
func shuffle():
	i = randi_range(0, meta[sign_type].count - 1)
