extends Node

signal cosmetics_changed
signal challenge_updated
signal volumes_changed

const SAVE_PATH = "user://save.dat"

const CHALLENGE_DEFS: Array = [
	{
		"id": "combo",
		"title": "Серия",
		"desc": "Набей %d комбо подряд",
		"chain": [3, 5, 10, 20, 30],
		"stars": [10, 20, 30, 50, 100],
		"hearts": [0, 0, 0, 3, 5]
	},
	{
		"id": "sniper",
		"title": "Снайпер",
		"desc": "Попади в кольцо %d раз за одну игру",
		"chain": [10, 20, 30, 50, 70, 100],
		"stars": [10, 20, 30, 50, 70, 100],
		"hearts": [0, 0, 0, 1, 3, 5]
	},
	{
		"id": "record",
		"title": "Рекордсмен",
		"desc": "Побей свой рекорд %d раз",
		"chain": [3, 7, 10, 15],
		"stars": [10, 20, 30, 40],
		"hearts": [0, 0, 0, 0]
	},
	{
		"id": "collector",
		"title": "Коллекционер",
		"desc": "Купи %d скинов мяча",
		"chain": [3, 5, 10, 14],
		"stars": [10, 30, 50, 100],
		"hearts": [0, 0, 1, 2]
	},
	{
		"id": "phoenix",
		"title": "Феникс",
		"desc": "Перезапусти игру после поражения %d раз",
		"chain": [3, 7, 15],
		"stars": [10, 30, 50],
		"hearts": [0, 0, 1]
	},
	{
		"id": "longshot",
		"title": "Дальнобойщик",
		"desc": "Используй максимальную силу броска %d раз",
		"chain": [10, 25, 50],
		"stars": [15, 25, 50],
		"hearts": [0, 0, 0]
	},
	{
		"id": "machine",
		"title": "Машина",
		"desc": "Набей комбо ×5 в %d разных играх",
		"chain": [3, 5, 10],
		"stars": [20, 35, 70],
		"hearts": [0, 0, 1]
	},
	{
		"id": "no_walls",
		"title": "Без тормозов",
		"desc": "Набей %d комбо подряд не касаясь стен",
		"chain": [7, 12, 20],
		"stars": [25, 45, 65],
		"hearts": [0, 0, 2]
	},
	{
		"id": "progress_ch",
		"title": "Прогресс",
		"desc": "Улучши личный рекорд %d раз",
		"chain": [5, 10, 20],
		"stars": [25, 45, 75],
		"hearts": [0, 0, 0]
	}
]

var stars: int = 0
var hearts: int = 0
var best_score: int = 0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var dark_theme: bool = false
var owned_balls: Array = ["default"]
var owned_backgrounds: Array = ["default"]
var equipped_ball: String = "default"
var equipped_bg: String = "default"
var challenges: Dictionary = {}

func _ready() -> void:
	load_data()
	_initChallenges()

func _initChallenges() -> void:
	for def in CHALLENGE_DEFS:
		var id = def["id"]
		if id not in challenges:
			challenges[id] = {"step": 0, "progress": 0, "claimable": false}

func save_data() -> void:
	var data = {
		"stars": stars,
		"hearts": hearts,
		"best_score": best_score,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"dark_theme": dark_theme,
		"owned_balls": owned_balls,
		"owned_backgrounds": owned_backgrounds,
		"equipped_ball": equipped_ball,
		"equipped_bg": equipped_bg,
		"challenges": challenges,
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
	music_volume = data.get("music_volume", 1.0)
	sfx_volume = data.get("sfx_volume", 1.0)
	dark_theme = data.get("dark_theme", false)
	owned_balls = data.get("owned_balls", ["default"])
	owned_backgrounds = data.get("owned_backgrounds", ["default"])
	equipped_ball = data.get("equipped_ball", "default")
	equipped_bg = data.get("equipped_bg", "default")
	challenges = data.get("challenges", {})

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
		_progressChallenge("record")
		_progressChallenge("progress_ch")
		save_data()

func equip_ball(id: String) -> void:
	equipped_ball = id
	save_data()
	cosmetics_changed.emit()

func equip_bg(id: String) -> void:
	equipped_bg = id
	save_data()
	cosmetics_changed.emit()

# ── Challenges ────────────────────────────────────────────────────

func _getDefById(id: String) -> Dictionary:
	for def in CHALLENGE_DEFS:
		if def["id"] == id:
			return def
	return {}

func _progressChallenge(id: String) -> void:
	if id not in challenges:
		return
	var ch = challenges[id]
	var def = _getDefById(id)
	if ch["step"] >= def["chain"].size() or ch["claimable"]:
		return
	ch["progress"] += 1
	if ch["progress"] >= def["chain"][ch["step"]]:
		ch["claimable"] = true
	save_data()
	challenge_updated.emit()

func _setProgressChallenge(id: String, value: int) -> void:
	if id not in challenges:
		return
	var ch = challenges[id]
	var def = _getDefById(id)
	if ch["step"] >= def["chain"].size() or ch["claimable"]:
		return
	ch["progress"] = value
	if ch["progress"] >= def["chain"][ch["step"]]:
		ch["claimable"] = true
	save_data()
	challenge_updated.emit()

func _resetStreakChallenge(id: String) -> void:
	if id not in challenges:
		return
	var ch = challenges[id]
	if ch["claimable"] or ch["step"] >= _getDefById(id)["chain"].size():
		return
	if ch["progress"] == 0:
		return
	ch["progress"] = 0
	challenge_updated.emit()

func claimChallenge(id: String) -> void:
	if id not in challenges:
		return
	var ch = challenges[id]
	if not ch["claimable"]:
		return
	var def = _getDefById(id)
	var step = ch["step"]
	stars += def["stars"][step]
	hearts += def["hearts"][step]
	ch["step"] += 1
	ch["progress"] = 0
	ch["claimable"] = false
	save_data()
	challenge_updated.emit()

func notifyCleanShot(comboValue: int) -> void:
	_setProgressChallenge("combo", comboValue)
	_setProgressChallenge("no_walls", comboValue)

func notifyRimHit() -> void:
	_resetStreakChallenge("combo")
	_resetStreakChallenge("no_walls")

func notifyGoalScored(totalGoals: int) -> void:
	var id = "sniper"
	if id not in challenges:
		return
	var ch = challenges[id]
	var def = _getDefById(id)
	if ch["step"] >= def["chain"].size() or ch["claimable"]:
		return
	if totalGoals > ch["progress"]:
		_setProgressChallenge(id, totalGoals)

func notifyMaxForceShot() -> void:
	_progressChallenge("longshot")

func notifyComboFiveGame() -> void:
	_progressChallenge("machine")

func notifyRestartAfterLoss() -> void:
	_progressChallenge("phoenix")

func notifyBallPurchased() -> void:
	_setProgressChallenge("collector", owned_balls.size() - 1)

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	save_data()
	volumes_changed.emit()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	save_data()
	volumes_changed.emit()
