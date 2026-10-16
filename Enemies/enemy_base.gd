class_name Enemy
extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite
@onready var name_rect: ColorRect = $NameRect
@onready var name_label: Label = $NameLabel

@export var max_health: float = 100.0
var health: float:
	set(v):
		v = clampf(v,0.0,max_health)
		health = v
		if v == 0.0:
			_die()

var r: Level
func _ready() -> void:
	r = get_tree().current_scene
	health = max_health
	r.play_sound(preload("res://SFX/ENEMY_GROAN.mp3"))
	
var facing_dir: int = 0:
	set(v):
		facing_dir = v 
		sprite.flip_h = true if v == -1 else false
	
	
@export var x_speed: float = 10.0
func _physics_process(delta: float) -> void:
	var dir: float = 1 if global_position.x < r.player.global_position.x else -1
	if dir:
		facing_dir = int(dir)
	velocity.x = dir * x_speed
	move_and_slide()
	
	if not is_on_floor():
		velocity.y += 98.8 * delta

func hit(d: float):
	health -= d
	
func _die():
	queue_free()

@export var damage: float = 10.0
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.health -= damage
		r.play_sound(preload("res://SFX/PLAYER_HIT.mp3"))
