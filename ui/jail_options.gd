extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	EventBus.jail.connect(on_jail)
	EventBus.restart.connect(on_restart)

var tween

func on_restart():
	if tween:
		tween.kill()
		tween = null
	hide()

@onready var stats = %StatsLabel
@onready var text = %StatsLabel.text

var units = {
	"distance": " meters",
	"top_speed": " m/sec"
}
func on_jail(_stuff):
	var new_text = text
	for k: String in EventBus.stats:
		var v = EventBus.stats[k]
		new_text += "[color=green]" + k.capitalize() + "[/color]" + ": " + str(floor(v * 10.0) / 10.0)
		new_text += units.get(k, "")
		new_text += "\n"
	stats.text = new_text
	modulate = Color.TRANSPARENT
	tween = get_tree().create_tween()
	tween.tween_interval(4.0)
	tween.tween_callback(show)
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	show()


func _on_try_again_pressed():
	hide()
	EventBus.restart.emit()

func _on_quit_pressed():
	get_tree().quit()
