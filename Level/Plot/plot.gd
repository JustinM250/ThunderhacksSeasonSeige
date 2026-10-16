extends Node2D
class_name Plot

var occupant: PlotOccupant = null

func set_occupant(p: PlotOccupant):
	if occupant:
		occupant.queue_free()
	occupant = p
	add_child(p)
