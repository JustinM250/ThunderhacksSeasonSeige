extends PlotOccupant

@onready var sprite: Sprite2D = $Sprite

var health: int = 3:
	set(v):
		v = clampi(v,0,3)
		health = v
		
		if v == 0:
			destroy()

#var r: Level
func _ready() -> void:
	super._ready()
	#r = get_tree().current_scene
	r.season_updated.connect(func(_l: SEASONS.LIST):
		_update()
	)
	_update()
	
func _update():
	sprite.texture = _get_seasonal_tree_texture(r.current_season)

func _get_seasonal_tree_texture(l: SEASONS.LIST):
	var t: Texture2D 
	match(l):
		SEASONS.LIST.SPRING: t = TEXTURE_PRELOADER.tree_spring
		SEASONS.LIST.SUMMER: t = TEXTURE_PRELOADER.tree_summer
		SEASONS.LIST.AUTUMN: t = TEXTURE_PRELOADER.tree_autumn
		SEASONS.LIST.WINTER: t = TEXTURE_PRELOADER.tree_winter
	return t

func _on_hit_area_area_entered(area: Area2D) -> void:
	if "axe_slash" in area:
		if area.axe_slash:
			health -= 1
			r.play_sound(preload("res://SFX/HITTING_TREE.mp3"))
			
func destroy():
	for n in range(3):
		r.player.add_to_inventory(ITEMS.LIST.LOG)
	for n in range(1):
		r.player.add_to_inventory(ITEMS.LIST.THATCH)
	r.play_sound(preload("res://SFX/BUSHWACK.mp3"))
	
	super.destroy()
