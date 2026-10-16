extends Node2D
class_name Tile

@onready var sprite: Sprite2D = $Sprite

enum TILE_TYPES_LIST{
	MUD,
	MUD_GRASS,
}
@export var tile_type: TILE_TYPES_LIST

var r: Level
func _ready() -> void:
	r = get_tree().current_scene

	r.season_updated.connect(func(l: SEASONS.LIST):
		_update_seasonal_texture(l)
	)
	_update_seasonal_texture(r.current_season)
	
func _update_seasonal_texture(l: SEASONS.LIST):
	match(tile_type):
		TILE_TYPES_LIST.MUD:
			match(l):
				SEASONS.LIST.SPRING: sprite.texture = TEXTURE_PRELOADER.mud_spring
				SEASONS.LIST.SUMMER: sprite.texture = TEXTURE_PRELOADER.mud_summer
				SEASONS.LIST.AUTUMN: sprite.texture = TEXTURE_PRELOADER.mud_autumn
				_: sprite.texture = TEXTURE_PRELOADER.mud_winter
				
		TILE_TYPES_LIST.MUD_GRASS:
			match(l):
				SEASONS.LIST.SPRING: sprite.texture = TEXTURE_PRELOADER.mud_grass_spring
				SEASONS.LIST.SUMMER: sprite.texture = TEXTURE_PRELOADER.mud_grass_summer
				SEASONS.LIST.AUTUMN: sprite.texture = TEXTURE_PRELOADER.mud_grass_autumn
				_: sprite.texture = TEXTURE_PRELOADER.mud_grass_winter
