extends PanelContainer
class_name HotbarSlot

@onready var item_tex: TextureRect = $ItemTex
@onready var num_label: Label = $NumLabel

@export var corresponding_item: ITEMS.LIST

var held_item: ITEMS.LIST = ITEMS.LIST.ITEM_NULL:
	set(v):
		held_item = v
		item_tex.texture = ITEMS.get_item_texture(v)
		
var inv_slot: int = 0
func _ready() -> void:
	inv_slot = get_index()+1
	num_label.text = ""
