extends Node2D
class_name Level 

@onready var music_player: AudioStreamPlayer = $MusicPlayer

func play_song(m: AudioStreamMP3):
	music_player.stream = m
	music_player.play()
	
@onready var sounds: Node = $Sounds

func play_sound(m: AudioStreamMP3):
	var s := preload("res://SFX/speaker.tscn").instantiate() as AudioStreamPlayer
	s.stream = m
	sounds.add_child(s)
	s.finished.connect(s.queue_free)

var current_season: SEASONS.LIST:
	set(v):
		current_season = v
		season_updated.emit(v)
#@warning_ignore_start("unused_signal")
signal season_updated(l: SEASONS.LIST)

var day: bool:
	set(v):
		day = v
		day_updated.emit(v)
		
		if v == false:
			enemy_timer = 1.0
#@warning_ignore_start("unused_signal")
signal day_updated(b: bool)

@onready var plots: Node2D = $Plots

@onready var camera: Camera2D = $Camera
@onready var player: Player = $Player

func get_plots() -> Array[Plot]:
	var a: Array[Plot] = []
	for i in plots.get_children():
		a.append(i)
	return a
	
func get_availible_plots() -> Array[Plot]:
	var a: Array[Plot] = []
	for i in get_plots().duplicate() as Array[Plot]:
		if i.occupant == null:
			a.append(i)
	return a

@onready var sky_col_rect: ColorRect = $Sky/SkyColRect
@onready var night_darkness_overlay: ColorRect = $Sky/NightDarknessOverlay

func _ready() -> void:
	_initialize_plots()

var campfire = preload("res://Level/PlotOccupants/Campfire/campfire.tscn")
var tree = preload("res://Level/PlotOccupants/Obstacles/Tree/tree.tscn")
var bush = preload("res://Level/PlotOccupants/Obstacles/Bush/bush.tscn")

func _initialize_plots():
	
	get_availible_plots()[10].set_occupant(campfire.instantiate() )
	
	var trees_left: int = 15
	for n in range(trees_left):
		var new_tree: PlotOccupant = tree.instantiate()
		get_availible_plots().pick_random().set_occupant(new_tree)
		trees_left -= 1
		
	var bushes_left: int = 7
	for n in range(bushes_left):
		var new_bush: PlotOccupant = bush.instantiate()
		get_availible_plots().pick_random().set_occupant(new_bush)
		bushes_left -= 1
		
var regrow_timer: float = 10.0
var enemy_timer: float = 5#70.0
func _physics_process(delta: float) -> void:
	if regrow_timer >= 0.0:
		regrow_timer -= delta
		if regrow_timer <= 0.0:
			regrow_timer = randf_range(5.0,10.0)
			get_availible_plots().pick_random().set_occupant(bush.instantiate() if randi_range(0,1) == 0 else tree.instantiate() )
		
	enemy_timer -= delta
	if enemy_timer <= 0.0:
		if day:
			enemy_timer = 70.0
		else:
			enemy_timer = 4.0
		spawn_enemy(_decide_enemy(), Vector2(116*[-1,1].pick_random(),-22) )
		
@onready var projectiles: Node2D = $Projectiles
func spawn_projectile(p: Area2D, pos: Vector2, dir: int, speed: float):
	p.dir = dir
	p.speed = speed
	projectiles.add_child(p)
	p.global_position = pos
	
@onready var enemies: Node2D = $Enemies
func spawn_enemy(e: Enemy, pos: Vector2):
	enemies.add_child(e)
	e.global_position = pos

var husk = preload("res://Enemies/Husk/husk.tscn")
var lich = preload("res://Enemies/Lich/lich.tscn")
var wendigo = preload("res://Enemies/Wendigo/wendigo.tscn")
var draugr = preload("res://Enemies/Draugr/draugr.tscn")

func _decide_enemy() -> Enemy:
	match(current_season):
		SEASONS.LIST.SPRING:
			return husk.instantiate() 
		SEASONS.LIST.SUMMER:
			match(randi_range(1,3)):
				1:
					return husk.instantiate()
				_:
					return lich.instantiate()
		SEASONS.LIST.AUTUMN:
			match(randi_range(1,3)):
				1:
					return wendigo.instantiate()
				2:
					return lich.instantiate()
				_:
					return husk.instantiate()
		_:
			match(randi_range(1,3)):
				1:
					return wendigo.instantiate()
				_:
					return draugr.instantiate()
