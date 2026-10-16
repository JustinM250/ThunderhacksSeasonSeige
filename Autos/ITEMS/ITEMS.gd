extends Node

enum LIST{
	ITEM_NULL,
	SHROOM,
	BERRIES,
	LOG,
	THATCH,
	AXE,
	BOW,
}

func get_item_texture(l: LIST) -> Texture2D:
	match(l):
		LIST.SHROOM: return preload("res://Items/item_shroom.png")
		LIST.BERRIES: return preload("res://Items/item_berries.png")
		LIST.LOG: return preload("res://Items/item_log.png")
		LIST.THATCH: return preload("res://Items/item_thatch.png")
		LIST.AXE: return preload("res://Items/item_axe.png")
		LIST.BOW: return preload("res://Items/item_bow.png")
		_: return null

func get_item_hunger_replenish(l: LIST) -> float:
	match(l):
		LIST.SHROOM: return 15.0
		LIST.BERRIES: return 45.0
		_: return -1.0
