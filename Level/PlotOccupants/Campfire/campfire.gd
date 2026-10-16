extends PlotOccupant
class_name Campfire 

@onready var sprite: Sprite2D = $Sprite
@onready var flame_sprite: Sprite2D = $FlameSprite

#var r: Level
#func _ready() -> void:
	#r = get_tree().current_scene
	#r.season_updated.connect(func(_l: SEASONS.LIST):
		#_update()
	#)
	#_update()
	
const log_cost: int = 3
	
var active: bool = false:
	set(v):
		active = v
		flame_sprite.visible = v 
var active_timer: float = -1.0
		
func _ready() -> void:
	super._ready()
	active = false
	in_radius = false
		
var flame_t: float = 0.0
var flame_toggle: float = 0.0
func _physics_process(delta: float) -> void:
	flame_t -= delta 
	if flame_t <= 0.0:
		flame_t = 0.12
		flame_sprite.texture = _get_flame_texture(flame_toggle)
		flame_toggle = !flame_toggle
	
	if active_timer >= 0.0:
		active_timer -= delta
		if active_timer <= 0.0:
			active = false 
	
	if Input.is_action_just_pressed("E"):
		if in_radius and r.player.inventory.count(ITEMS.LIST.LOG) >= log_cost and not active:
			for n in range(log_cost):
				r.player.remove_from_inventory(ITEMS.LIST.LOG)
			active = true
			active_timer = 30.0
			_set_prompt(false)
	
			r.play_sound(preload("res://SFX/POP.mp3"))
	
	if in_radius:
		r.player.warmth += 0.04 * delta 
	
#func _update():
	#sprite.texture = _get_seasonal_tree_texture(r.current_season)

func _get_flame_texture(b: bool):
	return preload("res://Level/PlotOccupants/Campfire/campfire_flame_A.png") if b else preload("res://Level/PlotOccupants/Campfire/campfire_flame_B.png")


var in_radius: bool = false:
	set(v):
		in_radius = v
		if not active and r.player.inventory.count(ITEMS.LIST.LOG) >= log_cost:
			_set_prompt(v)
		

@onready var prompt: Control = $Prompt
func _set_prompt(b: bool):
	prompt.visible = b
	


func _on_a_body_entered(body: Node2D) -> void:
	in_radius = true


func _on_a_body_exited(body: Node2D) -> void:
	in_radius = false
