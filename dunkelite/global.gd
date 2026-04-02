extends Node

const SAVE_PATH = "user://save.dat"

var stars: int = 0
var hearts: int = 50
var best_score: int = 0
var sound_on: bool = true
var music_on: bool = true
var dark_theme: bool = false
var owned_balls: Array = ["default"]
var owned_backgrounds: Array = ["default"]
var equipped_ball: String = "default"
var equipped_bg: String = "default"

func _ready() -> void:
	load_data()

func save_data() -> void:
	var data = {
		"stars": stars,
		"hearts": hearts,
		"best_score": best_score,
		"sound_on": sound_on,
		"music_on": music_on,
		"dark_theme": dark_theme,
		"owned_balls": owned_balls,
		"owned_backgrounds": owned_backgrounds,
		"equipped_ball": equipped_ball,
		"equipped_bg": equipped_bg,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(data)

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = file.get_var()
	if data is not Dictionary:
		return
	stars = data.get("stars", 0)
	hearts = data.get("hearts", 3)
	best_score = data.get("best_score", 0)
	sound_on = data.get("sound_on", true)
	music_on = data.get("music_on", true)
	dark_theme = data.get("dark_theme", false)
	owned_balls = data.get("owned_balls", ["default"])
	owned_backgrounds = data.get("owned_backgrounds", ["default"])
	equipped_ball = data.get("equipped_ball", "default")
	equipped_bg = data.get("equipped_bg", "default")

func add_stars(amount: int) -> void:
	stars += amount
	save_data()

func spend_stars(amount: int) -> bool:
	if stars >= amount:
		stars -= amount
		save_data()
		return true
	return false

func use_heart() -> bool:
	if hearts > 0:
		hearts -= 1
		save_data()
		return true
	return false

func update_best_score(score: int) -> void:
	if score > best_score:
		best_score = score
		save_data()
