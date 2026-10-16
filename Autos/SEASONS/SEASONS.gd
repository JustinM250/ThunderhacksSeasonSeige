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
