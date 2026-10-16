extends Area2D

var axe_slash: bool = true

var damage: float = 5.0

var dir: int 
var speed: float = 10.0

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	sprite.flip_h = true if dir == -1 else false

func _physics_process(delta: float) -> void:
	global_position.x += dir * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.hit(damage)
		queue_free()


func _on_lifetime_timeout() -> void:
	queue_free()
