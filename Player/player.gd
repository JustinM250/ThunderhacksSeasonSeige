extends CharacterBody2D
class_name Player

var max_health: float = 100.0
var health: float = max_health:
	set(v):
		v = clampf(v,0.0,max_health)
		health = v
		main_ui.update_health_bar(v,max_health)
		if v == 0.0:
			_die()

var max_hunger: float = 100.0
var hunger: float = max_hunger:
	set(v):
		v = clampf(v,0.0,max_hunger)
		hunger = v
		main_ui.update_hunger_bar(v,max_hunger)
var hunger_health_burn: float = 1.0
var hunger_decay_rate: float = 1.0

var max_warmth: float = 1.0
var warmth: float = max_warmth:
	set(v):
		v = clampf(v,0.0,max_warmth)
		warmth = v
		main_ui.update_warmth_bar(v,max_warmth)

var inventory: Array[ITEMS.LIST] = []
var selected_inventory_slot: HotbarSlot = null

func add_to_inventory(l: ITEMS.LIST):
	inventory.append(l)
	
func remove_from_inventory(l: ITEMS.LIST):
	inventory.erase(l)

var x_speed: float = 40.0
@onready var sprite: Sprite2D = $Sprite
@onready var axe_sprite: Sprite2D = $AxeSprite
@onready var bow_sprite: Sprite2D = $BowSprite

@onready var main_ui: MainUI = $MainUI

var facing_dir: int = 0:
	set(v):
		facing_dir = v 
		sprite.flip_h = true if v == -1 else false
		axe_sprite.flip_h = true if v == -1 else false
		bow_sprite.flip_h = true if v == -1 else false

var r: Level

func _ready() -> void:
	r = get_tree().current_scene
	
	add_to_inventory(ITEMS.LIST.AXE)
	add_to_inventory(ITEMS.LIST.BOW)
	#add_to_inventory(ITEMS.LIST.BERRIES)
	#add_to_inventory(ITEMS.LIST.SHROOM)
	#add_to_inventory(ITEMS.LIST.BOW)
	#add_to_inventory(ITEMS.LIST.BOW)
	selected_inventory_slot = main_ui.get_all_hotbar_slots().get(0)

	call_deferred("_pop")
	
func _pop():
	r.play_sound(preload("res://SFX/POP.mp3"))
	

var key_array: Array[Key] = [
	KEY_1,
	KEY_2,
	KEY_3,
	KEY_4,
	KEY_5,
	KEY_6,
	KEY_7,
	KEY_8,
]

func _physics_process(delta: float) -> void:
	var dir: float = Input.get_axis("A","D")
	if dir:
		facing_dir = int(dir)
	velocity.x = dir * x_speed
	move_and_slide()
	
	hunger -= hunger_decay_rate * delta
	if hunger <= 0.0:
		health -= hunger_health_burn * delta
		
	if r.day == false:
		warmth -= 0.01 * delta
	if r.current_season == SEASONS.LIST.WINTER:
		warmth -= 0.03 * delta
	warmth -= 0.01 * delta
		
	if warmth <= 0.0:
		health -= 1.0 * delta
		
	if Input.is_action_just_pressed("UseItem"):
		var item: ITEMS.LIST = selected_inventory_slot.held_item
		#print(item)
		match(item):
			ITEMS.LIST.AXE:
				r.spawn_projectile(preload("res://Player/Weapons/AxeSlash/axe_slash.tscn").instantiate() as Area2D, global_position, facing_dir, 100.0 )
			ITEMS.LIST.BOW:
				r.spawn_projectile(preload("res://Player/Weapons/Arrow/player_arrow.tscn").instantiate() as Area2D, global_position, facing_dir, 100.0 )
			ITEMS.LIST.SHROOM:
				hunger += ITEMS.get_item_hunger_replenish(ITEMS.LIST.SHROOM)
				remove_from_inventory(ITEMS.LIST.SHROOM)
			ITEMS.LIST.BERRIES:
				hunger += ITEMS.get_item_hunger_replenish(ITEMS.LIST.BERRIES)
				remove_from_inventory(ITEMS.LIST.BERRIES)
		
	for k in key_array:
		if Input.is_key_pressed(k):
			selected_inventory_slot = main_ui.get_all_hotbar_slots().get(key_array.find(k) )
			
	
	if selected_inventory_slot:
		axe_sprite.visible = selected_inventory_slot.held_item == ITEMS.LIST.AXE
		bow_sprite.visible = selected_inventory_slot.held_item == ITEMS.LIST.BOW
	else:
		axe_sprite.visible = false
		bow_sprite.visible = false
	
	if abs(global_position.x) > 116.0:
		global_position = Vector2(0,-20)
	
	if not is_on_floor():
		velocity.y += 98.8 * delta
	
func _die():
	get_tree().change_scene_to_file("res://Title/title.tscn")
