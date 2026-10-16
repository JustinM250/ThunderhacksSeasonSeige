#class_name Enemy
#extends Node2D
## Night creatures. Two kinds for now:
##   "draugr"  - the general-season undead (replaces "zombie" for a mythological feel)
##   "wendigo" - tougher, only appears in Autumn
## They walk toward the player, can't enter shelters, and die in traps.
#
#var kind := "draugr"
#var hp := 3.0
#var max_hp := 3.0
#var speed := 70.0
#var damage := 8.0
#var attack_cooldown := 1.2
#var attack_timer := 0.0
#var hit_flash := 0.0
#var player: Player
#var world   # the Main node (gives us is_blocked / try_trap)
#
#func setup(p_kind: String, p_player: Player, p_world) -> void:
	#kind = p_kind
	#player = p_player
	#world = p_world
	#if kind == "wendigo":
		#hp = 8.0
		#speed = 110.0
		#damage = 15.0
		#attack_cooldown = 1.0
	#max_hp = hp
#
#func _ready() -> void:
	#add_to_group("enemies")
#
#func _process(delta: float) -> void:
	#if player == null:
		#return
	#var dx := player.position.x - position.x
	#var dir := signf(dx)
#
	## walk toward the player (unless a shelter wall is in the way)
	#if absf(dx) > 26.0:
		#var nx := position.x + dir * speed * delta
		#if not world.is_blocked(position.x, nx):
			#position.x = nx
#
	## attack (jumping high enough dodges it; shelters make you safe)
	#attack_timer -= delta
	#if absf(dx) <= 32.0 and player.alive and not player.sheltered and player.position.y > player.ground_y - 30.0:
		#if attack_timer <= 0.0:
			#player.take_damage(damage)
			#attack_timer = attack_cooldown
#
	## traps
	#var trap_damage: float = world.try_trap(position.x)
	#if trap_damage > 0.0:
		#take_damage(trap_damage)
#
	#hit_flash = maxf(0.0, hit_flash - delta)
	#queue_redraw()
#
#func take_damage(amount: float) -> void:
	#hp -= amount
	#hit_flash = 0.15
	#if hp <= 0.0:
		#queue_free()
#
#func _draw() -> void:
	#var face := 1.0
	#if player != null and player.position.x < position.x:
		#face = -1.0
#
	#if kind == "wendigo":
		#var c := Color(0.3, 0.2, 0.15)
		#if hit_flash > 0.0:
			#c = Color.WHITE
		#draw_rect(Rect2(-17, -66, 34, 66), c)
		#draw_circle(Vector2(0, -74), 12.0, Color(0.85, 0.85, 0.8))
		## antlers
		#draw_line(Vector2(-6, -84), Vector2(-16, -104), Color(0.8, 0.75, 0.6), 3.0)
		#draw_line(Vector2(6, -84), Vector2(16, -104), Color(0.8, 0.75, 0.6), 3.0)
		#draw_circle(Vector2(face * 5, -76), 3.0, Color(1, 0.1, 0.1))
		#var bar_y := -112.0
		#_draw_hp_bar(bar_y)
	#else:
		#var c2 := Color(0.4, 0.5, 0.4)
		#if hit_flash > 0.0:
			#c2 = Color.WHITE
		#draw_rect(Rect2(-12, -42, 24, 42), c2)
		#draw_circle(Vector2(0, -50), 9.0, Color(0.55, 0.65, 0.55))
		#draw_circle(Vector2(face * 4, -52), 2.5, Color(0.6, 1.0, 0.6))
		#_draw_hp_bar(-66.0)
#
#func _draw_hp_bar(y: float) -> void:
	#draw_rect(Rect2(-14, y, 28, 4), Color(0, 0, 0, 0.6))
	#draw_rect(Rect2(-14, y, 28.0 * clampf(hp / max_hp, 0.0, 1.0), 4), Color(0.9, 0.2, 0.2))
