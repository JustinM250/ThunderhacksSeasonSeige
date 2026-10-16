extends Node

enum LIST{
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER,
}

func get_season_name(l: LIST) -> String:
	match(l):
		LIST.SPRING: return "SPRING"
		LIST.SUMMER: return "SUMMER"
		LIST.AUTUMN: return "AUTUMN"
		LIST.WINTER: return "WINTER"
		_: return "NULL"

func get_season_day_color(l: LIST) -> Color:
	match(l):
		LIST.SPRING: return Color(0.0, 0.777, 0.88, 1.0)
		LIST.SUMMER: return Color(0.0, 0.77, 0.878, 1.0)
		LIST.AUTUMN: return Color(0.526, 0.233, 0.75, 1.0)
		LIST.WINTER: return Color(0.72, 0.72, 0.72, 1.0)
		_: return Color.WHITE

func get_season_night_color(l: LIST) -> Color:
	match(l):
		LIST.SPRING: return Color(0.047, 0.156, 0.284, 1.0)
		LIST.SUMMER: return Color(0.066, 0.217, 0.39, 1.0)
		LIST.AUTUMN: return Color(0.161, 0.071, 0.23, 1.0)
		LIST.WINTER: return Color(0.1, 0.1, 0.1, 1.0)
		_: return Color.BLACK
