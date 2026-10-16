extends CanvasLayer
class_name MainUI

@onready var cycle_label: Label = $C/CycleLabel
@onready var cycle_bar: TextureProgressBar = $C/CycleBar

@onready var health_bar: TextureProgressBar = $C/HealthBar
@onready var hunger_bar: TextureProgressBar = $C/HungerBar
@onready var warmth_bar: TextureProgressBar = $C/WarmthBar

@onready var hotbar_slots: HBoxContainer = $C/HotbarSlots

func update_health_bar(v: float, v_max: float):
	health_bar.value = v / v_max

func update_hunger_bar(v: float, v_max: float):
	hunger_bar.value = v / v_max

func update_warmth_bar(v: float, v_max: float):
	warmth_bar.value = v / v_max

func get_all_hotbar_slots() -> Array[HotbarSlot]:
	var a: Array[HotbarSlot] = []
	for i in hotbar_slots.get_children():
		a.append(i)
	return a


@export var player: Player
func _physics_process(_delta: float) -> void:
	var inv_copy: Array[ITEMS.LIST] = player.inventory.duplicate(true)
	
	var inv_unique: Array[ITEMS.LIST] = []
	
	for i in inv_copy:
		if not inv_unique.has(i):
			inv_unique.append(i)
	
	var inv_numbered: Dictionary = {}
	
	for i in inv_unique:
		inv_numbered[i] = inv_copy.count(i)
	
	var slots := get_all_hotbar_slots()
	for i in slots:
		if inv_numbered.has(i.corresponding_item):
			#i.item_tex.texture = ITEMS.get_item_texture(i.corresponding_item)
			i.held_item = i.corresponding_item
			
			var amount: int = inv_numbered.get(i.corresponding_item)
			
			i.num_label.text = str( amount ) if amount > 1 else ""
	
		##
		
		if i == player.selected_inventory_slot:
			i.modulate = Color.YELLOW
		else:
			i.modulate = Color.WHITE
		
	
	
	#var iterator: int = 0
	#for n in inv_numbered.keys():
		#var s: HotbarSlot = slots.get(iterator)
		#
		#var item: ITEMS.LIST = inv_numbered.get(n)
		#
		#s.held_item = i
		#s.num_label = inv_numbered.get(i)
		#
		#iterator += 1
	
	#var slots := get_all_hotbar_slots()
	#var iterator: int = 0
	#for i in inv_numbered.keys():
		#var s: HotbarSlot = slots.get(iterator)
		#s.held_item = i
		#s.num_label = inv_numbered.get(i)
		#
		#iterator += 1
		
		
		
