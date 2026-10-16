extends Node2D
class_name PlotOccupant 

var r: Level
func _ready() -> void:
	r = get_tree().current_scene

func destroy():
	queue_free()
