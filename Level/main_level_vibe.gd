extends Node2D
# The whole game on one screen: 30 plots, trees/bushes/well, building,
# night spawns, season effects, HUD, and the day/night overlay.

enum Plot { EMPTY, TREE, BUSH, SHELTER, TRAP, WELL }

const PLOT_COUNT := 30
const PLOT_W := 40.0
const LEFT := 40.0
const GROUND_Y := 560.0
const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const WELL_PLOT := 4

const LOGS_PER_TREE := 3
const BERRIES_PER_BUSH := 2
const SHELTER_COST := 10     # logs, occupies 3 plots
const TRAP_COST := 3         # logs, occupies 1 plot
const MAX_LEVEL := 3

# Upgrade costs in logs: index 0 = level 1 -> 2, index 1 = level 2 -> 3
const SHELTER_UPGRADE_COSTS := [15, 25]
const TRAP_UPGRADE_COSTS := [5, 8]

# Per-level stats (index 0 = level 1)
const SLEEP_SPEEDS := [10.0, 14.0, 20.0]     # how fast time runs while sleeping in a shelter
const SHELTER_HEAL := [0.0, 2.0, 5.0]        # hp/sec healed while inside
const TRAP_DAMAGES := [5.0, 8.0, 12.0]
const TRAP_CHARGES := [1, 2, 3]              # enemies a trap can hit before it breaks
const TRAP_COOLDOWN := 0.8                   # seconds between trap triggers

const SHELTER_PERKS := ["", "Shelter level 2: heals you inside, and you sleep faster.", "Shelter level 3: strong healing, fastest sleep."]
const TRAP_PERKS := ["", "Trap level 2: 8 damage, 2 charges.", "Trap level 3: 12 damage, 3 charges."]

const ROOF_COLORS := [Color(0.35, 0.2, 0.1), Color(0.4, 0.4, 0.45), Color(0.15, 0.4, 0.45)]
const WALL_COLORS := [Color(0.5, 0.33, 0.17), Color(0.55, 0.5, 0.45), Color(0.6, 0.55, 0.45)]
const TRAP_COLORS := [Color(0.3, 0.3, 0.32), Color(0.55, 0.6, 0.7), Color(0.85, 0.25, 0.2)]
const PLAYER_DAMAGE := 2.0

const SKY_COLORS := [Color(0.6, 0.82, 0.95), Color(0.5, 0.8, 1.0), Color(0.85, 0.7, 0.55), Color(0.75, 0.82, 0.9)]
const GROUND_COLORS := [Color(0.35, 0.55, 0.25), Color(0.55, 0.6, 0.25), Color(0.55, 0.38, 0.2), Color(0.9, 0.93, 0.97)]
const LEAF_COLORS := [Color(0.4, 0.75, 0.35), Color(0.2, 0.6, 0.2), Color(0.85, 0.45, 0.15), Color(0.8, 0.88, 0.92)]
const SEASON_TIPS := [
	"Spring - trees and bushes regrow quickly.",
	"Summer - it's hot. Thirst drains faster.",
	"Autumn - food rots, and the Wendigo hunts at night.",
	"Winter - nothing regrows and hunger bites harder.",
]

var plots: Array[int] = []
var shelters: Array[Dictionary] = []   # each: {left, right, level}
var traps: Dictionary = {}             # plot index -> {level, charges, cooldown}
var player: Player
var game_over := false

var spawn_timer := 2.0
var regrow_timer := 4.0
var decay_timer := 12.0
var message_timer := 0.0
var overlay_alpha := 0.0

# UI nodes
var overlay: ColorRect
var hud: CanvasLayer
var health_bar: ProgressBar
var hunger_bar: ProgressBar
var thirst_bar: ProgressBar
var inventory_label: Label
var status_label: Label
var season_label: Label
var survived_label: Label
var objective_label: Label
var message_label: Label
var controls_label: Label
var game_over_label: Label

func _ready() -> void:
	randomize()
	Clock.reset()
	Clock.night_started.connect(_on_night_started)
	Clock.day_started.connect(_on_day_started)
	Clock.season_changed.connect(_on_season_changed)

	_generate_world()

	player = Player.new()
	player.position = Vector2(LEFT + 15.5 * PLOT_W, GROUND_Y)
	player.ground_y = GROUND_Y
	player.died.connect(_on_player_died)
	add_child(player)

	_build_ui()
	show_message(SEASON_TIPS[0], 5.0)

# ---------------------------------------------------------------- world

func _generate_world() -> void:
	plots.clear()
	shelters.clear()
	traps.clear()
	for i in PLOT_COUNT:
		plots.append(Plot.EMPTY)
	plots[WELL_PLOT] = Plot.WELL

	var slots: Array = range(PLOT_COUNT)
	slots.erase(WELL_PLOT)
	slots.shuffle()
	for i in 12:
		plots[slots[i]] = Plot.TREE
	for i in range(12, 16):
		plots[slots[i]] = Plot.BUSH

func plot_x(i: int) -> float:
	return LEFT + i * PLOT_W

func plot_index_at(x: float) -> int:
	return clampi(int((x - LEFT) / PLOT_W), 0, PLOT_COUNT - 1)

func _is_interactable(p: int) -> bool:
	return p == Plot.TREE or p == Plot.BUSH or p == Plot.WELL

# The plot the player would interact with: the one underfoot, else the one they face.
func target_plot() -> int:
	var i := plot_index_at(player.position.x)
	if _is_interactable(plots[i]):
		return i
	var j := clampi(i + player.facing, 0, PLOT_COUNT - 1)
	if _is_interactable(plots[j]):
		return j
	return i

func shelter_index_at(x: float, margin: float = 0.0) -> int:
	for i in shelters.size():
		var s: Dictionary = shelters[i]
		if x > float(s["left"]) - margin and x < float(s["right"]) + margin:
			return i
	return -1

func _is_sheltered(x: float) -> bool:
	return shelter_index_at(x) != -1

# Called by enemies: would moving from from_x to to_x walk them into a shelter?
func is_blocked(from_x: float, to_x: float) -> bool:
	for s in shelters:
		var l: float = s["left"]
		var r: float = s["right"]
		if from_x > l and from_x < r:
			continue   # already inside somehow; don't get stuck
		if to_x > l and to_x < r:
			return true
	return false

# Called by enemies each frame. Returns the damage dealt to the enemy (0.0 if no trap
# fired). Each trap has charges and a short cooldown; it breaks when charges run out.
func try_trap(x: float) -> float:
	if x < LEFT or x > LEFT + PLOT_COUNT * PLOT_W:
		return 0.0
	var i := plot_index_at(x)
	if plots[i] != Plot.TRAP or not traps.has(i):
		return 0.0
	var t: Dictionary = traps[i]
	if float(t["cooldown"]) > 0.0:
		return 0.0
	t["cooldown"] = TRAP_COOLDOWN
	t["charges"] = int(t["charges"]) - 1
	var dmg: float = TRAP_DAMAGES[int(t["level"]) - 1]
	if int(t["charges"]) <= 0:
		plots[i] = Plot.EMPTY
		traps.erase(i)
	return dmg

# The trap plot underfoot, or the one the player is facing; -1 if none.
func trap_plot_near() -> int:
	var i := plot_index_at(player.position.x)
	if plots[i] == Plot.TRAP:
		return i
	var j := clampi(i + player.facing, 0, PLOT_COUNT - 1)
	if plots[j] == Plot.TRAP:
		return j
	return -1

# ---------------------------------------------------------------- input / actions

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if game_over:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		return
	if player.sleeping and event.keycode != KEY_Z:
		return   # while asleep, only Z (wake up) works
	match event.keycode:
		KEY_E: _interact()
		KEY_F: _attack()
		KEY_1: _eat()
		KEY_2: _drink()
		KEY_3: _build_shelter()
		KEY_4: _build_trap()
		#KEY_5: _upgrade_shelter()
		#KEY_6: _upgrade_trap()
		#KEY_Z: _toggle_sleep()

func _interact() -> void:
	var i := target_plot()
	match plots[i]:
		Plot.TREE:
			plots[i] = Plot.EMPTY
			player.add_item(Items.Item.LOG, LOGS_PER_TREE)
			show_message("+%d logs" % LOGS_PER_TREE)
		Plot.BUSH:
			plots[i] = Plot.EMPTY
			player.add_item(Items.Item.BERRIES, BERRIES_PER_BUSH)
			show_message("+%d berries" % BERRIES_PER_BUSH)
		Plot.WELL:
			player.add_item(Items.Item.WATER)
			show_message("+1 water")
		_:
			show_message("Nothing to interact with here.")

func _attack() -> void:
	if player.attack_timer > 0.0:
		return
	player.attack_timer = 0.35
	player.swing_flash = 0.12
	for e in get_tree().get_nodes_in_group("enemies"):
		var dx: float = e.position.x - player.position.x
		if absf(dx) < 75.0 and dx * player.facing >= -10.0:
			e.take_damage(PLAYER_DAMAGE)

func _eat() -> void:
	var what := player.consume(true)
	show_message("Nothing to eat." if what == "" else "Ate %s" % what)

func _drink() -> void:
	var what := player.consume(false)
	show_message("Nothing to drink." if what == "" else "Drank %s" % what)

func _build_shelter() -> void:
	var logs := player.count(Items.Item.LOG)
	if logs < SHELTER_COST:
		show_message("A shelter needs %d logs (you have %d)." % [SHELTER_COST, logs])
		return
	var start := clampi(plot_index_at(player.position.x) - 1, 0, PLOT_COUNT - 3)
	for k in 3:
		if plots[start + k] != Plot.EMPTY:
			show_message("Need 3 empty plots in a row here.")
			return
	player.remove_items(Items.Item.LOG, SHELTER_COST)
	for k in 3:
		plots[start + k] = Plot.SHELTER
	shelters.append({"left": plot_x(start), "right": plot_x(start) + PLOT_W * 3.0, "level": 1})
	show_message("Shelter built! Stand inside to be safe from creatures.")

func _build_trap() -> void:
	var logs := player.count(Items.Item.LOG)
	if logs < TRAP_COST:
		show_message("A trap needs %d logs (you have %d)." % [TRAP_COST, logs])
		return
	var i := plot_index_at(player.position.x)
	if plots[i] != Plot.EMPTY:
		show_message("This plot isn't empty.")
		return
	player.remove_items(Items.Item.LOG, TRAP_COST)
	plots[i] = Plot.TRAP
	traps[i] = {"level": 1, "charges": TRAP_CHARGES[0], "cooldown": 0.0}
	show_message("Trap set.")

# ---------------------------------------------------------------- per-frame logic

#func _process(delta: float) -> void:
func _physics_process(delta: float) -> void:
	if not game_over:
		player.sheltered = _is_sheltered(player.position.x)
		#_update_sleep()
		var game_delta := delta * Clock.time_scale   # world time (fast while sleeping)
		if not player.sleeping:
			_update_spawning(delta)
		_update_regrow(game_delta)
		_update_decay(game_delta)
		#_update_traps(delta)
		#_update_shelter_heal(delta)

	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message_label.text = ""

	var target_alpha := 0.6 if Clock.is_night else 0.0
	if player.sleeping:
		target_alpha = 0.85
	overlay_alpha = lerpf(overlay_alpha, target_alpha, minf(1.0, delta * 1.5))
	overlay.color = Color(0.02, 0.03, 0.14, overlay_alpha)

	_update_hud()
	queue_redraw()

func _update_spawning(delta: float) -> void:
	if not Clock.is_night:
		return
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	var cap := 6 + Clock.seasons_survived * 2
	if get_tree().get_nodes_in_group("enemies").size() < cap:
		_spawn_enemy()
	spawn_timer = maxf(1.5, 7.0 - Clock.seasons_survived * 0.7)

func _spawn_enemy() -> void:
	var kind := "draugr"
	if Clock.season == Clock.Season.AUTUMN and randf() < 0.3:
		kind = "wendigo"
	var e := Enemy.new()
	e.setup(kind, player, self)
	e.position = Vector2(-30.0 if randf() < 0.5 else SCREEN_W + 30.0, GROUND_Y)
	add_child(e)

func _update_regrow(delta: float) -> void:
	regrow_timer -= delta
	if regrow_timer > 0.0:
		return
	regrow_timer = 4.0
	if Clock.season == Clock.Season.WINTER:
		return   # winter: farming is disabled
	var chance: float = 0.6 if Clock.season == Clock.Season.SPRING else 0.3
	if randf() > chance:
		return
	var empties: Array = []
	for i in PLOT_COUNT:
		if plots[i] == Plot.EMPTY:
			empties.append(i)
	if empties.is_empty():
		return
	var pick: int = empties.pick_random()
	plots[pick] = Plot.TREE if randf() < 0.7 else Plot.BUSH

func _update_decay(delta: float) -> void:
	decay_timer -= delta
	if decay_timer > 0.0:
		return
	decay_timer = 12.0
	if Clock.season == Clock.Season.AUTUMN and player.remove_items(Items.Item.BERRIES, 1):
		show_message("A berry rotted away...")

# ---------------------------------------------------------------- signals

func _on_night_started() -> void:
	spawn_timer = 2.0
	show_message("Night falls... creatures are stirring. Get to a shelter!", 4.0)

func _on_day_started() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	if player.sleeping:
		player.sleeping = false
		show_message("You wake at dawn, rested. The creatures retreat.", 3.5)
	else:
		show_message("Dawn breaks. The creatures retreat.", 3.0)

func _on_season_changed(new_season: int) -> void:
	show_message(SEASON_TIPS[new_season], 5.0)

func _on_player_died() -> void:
	game_over = true
	player.sleeping = false
	Clock.running = false
	game_over_label.text = "YOU DIED\n\nYou survived %d season%s.\nPress R to try again." % [Clock.seasons_survived, "" if Clock.seasons_survived == 1 else "s"]
	game_over_label.visible = true

func show_message(text: String, duration: float = 2.5) -> void:
	message_label.text = text
	message_timer = duration

# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 1
	add_child(overlay_layer)
	overlay = ColorRect.new()
	overlay.size = Vector2(SCREEN_W, SCREEN_H)
	overlay.color = Color(0.02, 0.03, 0.14, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(overlay)

	hud = CanvasLayer.new()
	hud.layer = 2
	add_child(hud)

	health_bar = _make_bar("Health", Vector2(20, 20), Color(0.85, 0.2, 0.2))
	hunger_bar = _make_bar("Hunger", Vector2(20, 46), Color(0.9, 0.6, 0.15))
	thirst_bar = _make_bar("Thirst", Vector2(20, 72), Color(0.25, 0.6, 0.95))

	inventory_label = _make_label(Vector2(20, 100), Vector2(500, 30), 20)
	status_label = _make_label(Vector2(20, 128), Vector2(500, 30), 18)
	season_label = _make_label(Vector2(440, 14), Vector2(400, 40), 28, HORIZONTAL_ALIGNMENT_CENTER)
	survived_label = _make_label(Vector2(940, 14), Vector2(320, 40), 24, HORIZONTAL_ALIGNMENT_RIGHT)
	objective_label = _make_label(Vector2(240, 56), Vector2(800, 30), 18, HORIZONTAL_ALIGNMENT_CENTER)
	message_label = _make_label(Vector2(190, 160), Vector2(900, 40), 24, HORIZONTAL_ALIGNMENT_CENTER)
	controls_label = _make_label(Vector2(20, 610), Vector2(1240, 100), 17)
	controls_label.text = "Move: A/D or arrows   Jump: W/Space   Interact (chop / pick / draw water): E   Attack: F   Eat: 1   Drink: 2\nBuild shelter (10 logs, 3 plots): 3   Build trap (3 logs, 1 plot): 4   Upgrade shelter: 5 (15/25 logs)   Upgrade trap: 6 (5/8 logs)\nStand at a shelter/trap to upgrade it. Sleep through the night inside a shelter: Z (hunger and thirst drain faster while asleep).\nStay in a shelter at night, or fight with F. Traps hit creatures that walk over them."
	game_over_label = _make_label(Vector2(240, 220), Vector2(800, 260), 36, HORIZONTAL_ALIGNMENT_CENTER)
	game_over_label.visible = false

func _make_label(pos: Vector2, label_size: Vector2, font_size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = label_size
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	hud.add_child(l)
	return l

func _make_bar(label_text: String, pos: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(200, 18)
	bar.max_value = 100.0
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	hud.add_child(bar)
	_make_label(pos + Vector2(208, -5), Vector2(120, 26), 18).text = label_text
	return bar

func _update_hud() -> void:
	health_bar.value = player.health
	hunger_bar.value = player.hunger
	thirst_bar.value = player.thirst
	inventory_label.text = "Logs: %d    Berries: %d    Water: %d" % [
		player.count(Items.Item.LOG), player.count(Items.Item.BERRIES), player.count(Items.Item.WATER)]
	if player.sleeping:
		status_label.text = "Sleeping... (move or press Z to wake)"
	elif player.sheltered:
		status_label.text = "In shelter - safe"
	elif player.hunger < 10.0 or player.thirst < 10.0:
		status_label.text = "STARVING! Eat or drink!"
	else:
		status_label.text = ""
	season_label.text = "%s   %s   %s" % [Clock.season_name(), Clock.clock_text(), "(Night)" if Clock.is_night else "(Day)"]
	survived_label.text = "Seasons survived: %d" % Clock.seasons_survived
	if Clock.elapsed < 45.0:
		objective_label.text = "Survive the increasingly harsh natural cycle for as long as possible."
	else:
		objective_label.text = ""

# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var sky: Color = SKY_COLORS[Clock.season]
	var ground: Color = GROUND_COLORS[Clock.season]
	var leaf: Color = LEAF_COLORS[Clock.season]

	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), sky)
	_draw_sun_or_moon()
	draw_rect(Rect2(0, GROUND_Y, SCREEN_W, SCREEN_H - GROUND_Y), ground)

	for i in PLOT_COUNT:
		var x := plot_x(i)
		var cx := x + PLOT_W / 2.0
		draw_line(Vector2(x, GROUND_Y), Vector2(x, GROUND_Y + 14), Color(0, 0, 0, 0.25), 1.0)
		match plots[i]:
			Plot.TREE:
				draw_rect(Rect2(cx - 4, GROUND_Y - 50, 8, 50), Color(0.4, 0.27, 0.15))
				draw_circle(Vector2(cx, GROUND_Y - 62), 22.0, leaf)
			Plot.BUSH:
				draw_circle(Vector2(cx, GROUND_Y - 10), 14.0, leaf.darkened(0.2))
				draw_circle(Vector2(cx - 5, GROUND_Y - 12), 2.5, Color(0.85, 0.1, 0.2))
				draw_circle(Vector2(cx + 4, GROUND_Y - 8), 2.5, Color(0.85, 0.1, 0.2))
				draw_circle(Vector2(cx + 1, GROUND_Y - 17), 2.5, Color(0.85, 0.1, 0.2))
			Plot.WELL:
				draw_rect(Rect2(cx - 15, GROUND_Y - 24, 30, 24), Color(0.5, 0.5, 0.52))
				draw_rect(Rect2(cx - 11, GROUND_Y - 24, 22, 7), Color(0.2, 0.5, 0.9))
				draw_line(Vector2(cx - 13, GROUND_Y - 24), Vector2(cx - 13, GROUND_Y - 52), Color(0.4, 0.27, 0.15), 3.0)
				draw_line(Vector2(cx + 13, GROUND_Y - 24), Vector2(cx + 13, GROUND_Y - 52), Color(0.4, 0.27, 0.15), 3.0)
				draw_colored_polygon(PackedVector2Array([Vector2(cx - 20, GROUND_Y - 52), Vector2(cx, GROUND_Y - 68), Vector2(cx + 20, GROUND_Y - 52)]), Color(0.55, 0.3, 0.2))
			Plot.TRAP:
				var trap: Dictionary = traps[i]
				var spike_color: Color = TRAP_COLORS[int(trap["level"]) - 1]
				for k in 3:
					var sx := x + 6.0 + k * 11.0
					draw_colored_polygon(PackedVector2Array([Vector2(sx, GROUND_Y), Vector2(sx + 5, GROUND_Y - 16), Vector2(sx + 10, GROUND_Y)]), spike_color)
				draw_string(ThemeDB.fallback_font, Vector2(x + 8, GROUND_Y - 20), "L%d" % int(trap["level"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
				for c in int(trap["charges"]):
					draw_circle(Vector2(x + 9.0 + c * 9.0, GROUND_Y - 30), 3.0, Color(1.0, 0.8, 0.2))

	for s in shelters:
		var sl: float = s["left"]
		var lv: int = s["level"]
		draw_rect(Rect2(sl, GROUND_Y - 56, PLOT_W * 3.0, 56), WALL_COLORS[lv - 1])
		draw_colored_polygon(PackedVector2Array([Vector2(sl - 10, GROUND_Y - 56), Vector2(sl + 60, GROUND_Y - 100), Vector2(sl + 130, GROUND_Y - 56)]), ROOF_COLORS[lv - 1])
		draw_rect(Rect2(sl + 48, GROUND_Y - 38, 24, 38), Color(0.2, 0.12, 0.06))
		draw_string(ThemeDB.fallback_font, Vector2(sl + 42, GROUND_Y - 108), "Shelter Lv %d" % lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	# marker showing which plot E / 3 / 4 will act on
	if player != null and player.alive:
		var t := target_plot()
		draw_rect(Rect2(plot_x(t) + 2, GROUND_Y + 4, PLOT_W - 4, 6), Color(1.0, 0.9, 0.2))

func _draw_sun_or_moon() -> void:
	var h := Clock.hour
	if h >= 6.0 and h < 18.0:
		var f := (h - 6.0) / 12.0
		draw_circle(Vector2(lerpf(100.0, 1180.0, f), 170.0 - sin(f * PI) * 100.0), 34.0, Color(1.0, 0.9, 0.4))
	else:
		var t := h - 18.0 if h >= 18.0 else h + 6.0
		var f2 := t / 12.0
		draw_circle(Vector2(lerpf(100.0, 1180.0, f2), 170.0 - sin(f2 * PI) * 100.0), 26.0, Color(0.9, 0.92, 1.0))
