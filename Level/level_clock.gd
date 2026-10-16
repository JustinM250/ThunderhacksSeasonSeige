extends Node
class_name LevelClock

const solar_cycle_time: float = 90.0
var time_left: float = solar_cycle_time:
	set(v):
		time_left = v
		_set_sky_col()
		_set_ui_cycle_bar()

@export var time_multiplier: float = 1.5#1.0

var cycles_completed: int:
	set(v):
		cycles_completed = v
		match(v):
			0:
				r.current_season = SEASONS.LIST.SPRING
				r.day = true
				#r.play_song(load("res://Music/SPRING_DAY.mp3"))
			1:
				r.current_season = SEASONS.LIST.SPRING
				r.day = false
				#r.play_song(load("res://Music/SPRING_DAY.mp3"))
			2:
				r.current_season = SEASONS.LIST.SUMMER
				r.day = true
				#r.play_song(load("res://Music/SUMMER_DAY.mp3"))
			3:
				r.current_season = SEASONS.LIST.SUMMER
				r.day = false
				#r.play_song(load("res://Music/SUMMER_NIGHT.mp3"))
			4:
				r.current_season = SEASONS.LIST.AUTUMN
				r.day = true
				#r.play_song(load("res://Music/FALL_DAY.mp3"))
			5:
				r.current_season = SEASONS.LIST.AUTUMN
				r.day = false
				#r.play_song(load("res://Music/FALL_NIGHT.mp3"))
			6:
				r.current_season = SEASONS.LIST.WINTER
				r.day = true
				#r.play_song(load("res://Music/WINTER_DAY.mp3"))
			7:
				r.current_season = SEASONS.LIST.WINTER
				r.day = false
				#r.play_song(load("res://Music/WINTER_NIGHT.mp3"))
			8:
				r.current_season = SEASONS.LIST.SPRING
				r.day = true
				_win()
		
				
var r: Level
func _ready() -> void:
	r = get_tree().current_scene
	cycles_completed = 0
	#_set_ui_cycle_label()
	call_deferred("_set_ui_cycle_label")
	
func _physics_process(delta: float) -> void:
	time_left -= delta * time_multiplier
	if time_left <= 0.0:
		time_left = solar_cycle_time
		cycles_completed += 1
		_set_ui_cycle_label()
		
		
func _set_sky_col():
	var day_col: Color = SEASONS.get_season_day_color(r.current_season)
	var night_col: Color = SEASONS.get_season_night_color(r.current_season)

	var t: float = 1.0 - (time_left / solar_cycle_time)

	# Keep the transition near the end of each cycle.
	t = smoothstep(0.8, 1.0, t)

	if r.day:
		r.sky_col_rect.color = day_col.lerp(night_col, t)
	else:
		r.sky_col_rect.color = night_col.lerp(day_col, t)
		
func _set_ui_cycle_label():
	r.player.main_ui.cycle_label.text = SEASONS.get_season_name(r.current_season) + " - " + ("DAY" if r.day else "NIGHT")
		
	match(cycles_completed):
		0:
			r.play_song(load("res://Music/SPRING_DAY.mp3"))
		1:
			r.play_song(load("res://Music/SPRING_DAY.mp3"))
		2:
			r.play_song(load("res://Music/SUMMER_DAY.mp3"))
		3:
			r.play_song(load("res://Music/SUMMER_NIGHT.mp3"))
		4:
			r.play_song(load("res://Music/FALL_DAY.mp3"))
		5:
			r.play_song(load("res://Music/FALL_NIGHT.mp3"))
		6:
			r.play_song(load("res://Music/WINTER_DAY.mp3"))
		7:
			r.play_song(load("res://Music/WINTER_NIGHT.mp3"))
		
func _set_ui_cycle_bar():
	r.player.main_ui.cycle_bar.value = time_left / solar_cycle_time
		
#func _set_sky_col():
	#var day_col: Color = Color(0.0, 0.77, 0.878, 1.0)
	#var night_col: Color = Color(0.047, 0.156, 0.284, 1.0)
#
	#if r.day:
		#r.sky_col_rect.color = lerp(day_col,night_col, time_left / solar_cycle_time )
	#else:
		#r.sky_col_rect.color = lerp(night_col,day_col, time_left / solar_cycle_time )

func _win():
	get_tree().change_scene_to_file("res://Title/end_title.tscn")
