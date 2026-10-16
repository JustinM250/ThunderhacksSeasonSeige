extends Area2D


var damage: float = 10.0

var dir: int 
var speed: float

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	sprite.flip_h = true if dir == -1 else false

func _physics_process(delta: float) -> void:
	global_position.x += dir * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.hit(damage)
		get_tree().current_scene.play_sound(preload("res://SFX/ARROW_HIT.mp3"))
		queue_free()
		


func _on_lifetime_timeout() -> void:
	queue_free()
