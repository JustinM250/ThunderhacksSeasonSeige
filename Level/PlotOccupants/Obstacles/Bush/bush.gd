extends PlotOccupant

@onready var sprite: Sprite2D = $Sprite
@onready var berries_sprite: Sprite2D = $BerriesSprite
var has_berries: bool:
	set(v):
		has_berries = v
		
		berries_sprite.visible = v
var berries_growth_timer: float = randf_range(5.0,15.0)

#var r: Level
func _ready() -> void:
	#r = get_tree().current_scene
	super._ready()
	r.season_updated.connect(func(l: SEASONS.LIST):
		_update()
		
		if has_berries and l == SEASONS.LIST.WINTER:
			has_berries = false 
	)
	_update()
	
	has_berries = randi_range(0,1)
	
func _update():
	sprite.texture = _get_seasonal_bush_texture(r.current_season)

func _get_seasonal_bush_texture(l: SEASONS.LIST):
	var t: Texture2D 
	match(l):
		SEASONS.LIST.SPRING: t = TEXTURE_PRELOADER.bush_spring
		SEASONS.LIST.SUMMER: t = TEXTURE_PRELOADER.bush_summer
		SEASONS.LIST.AUTUMN: t = TEXTURE_PRELOADER.bush_autumn
		SEASONS.LIST.WINTER: t = TEXTURE_PRELOADER.bush_winter
	return t
	
func _physics_process(delta: float) -> void:
	if not has_berries:
		if berries_growth_timer >= 0.0:
			berries_growth_timer -= delta
			if berries_growth_timer <= 0.0:
				berries_growth_timer = randf_range(5.0,15.0)
				has_berries = true 
	
var health: int = 1:
	set(v):
		v = clampi(v,0,3)
		health = v
		
		if v == 0:
			destroy()


func _on_hit_area_area_entered(area: Area2D) -> void:
	if "axe_slash" in area:
		if area.axe_slash:
			health -= 1
			r.play_sound(preload("res://SFX/HITTING_TREE.mp3"))
			

	
func destroy():
	if has_berries:
		r.player.add_to_inventory(ITEMS.LIST.BERRIES)
	
	if randf_range(0.0,100.0) > 50.0:
		r.player.add_to_inventory(ITEMS.LIST.SHROOM)
		
	r.play_sound(preload("res://SFX/BUSHWACK.mp3"))
		
	super.destroy()
	
