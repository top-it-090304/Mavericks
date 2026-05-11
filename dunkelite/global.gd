extends Node

signal cosmetics_changed
signal challenge_updated
signal volumes_changed

const SAVE_PATH = "user://save.dat"
const SAVE_VERSION = 1

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
	}
]

var stars: int = 0
var hearts: int = 3
var best_score: int = 0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var dark_theme: bool = false
var owned_balls: Array = ["default"]
var owned_backgrounds: Array = ["default"]
var equipped_ball: String = "default"
var equipped_bg: String = "default"
var challenges: Dictionary = {}

var _save_timer: Timer
var _save_pending: bool = false

func _ready() -> void:
	# Global не должен ставиться на паузу: сохранения по таймеру и события
	# notification (APPLICATION_PAUSED, WM_CLOSE_REQUEST) обязаны срабатывать
	# даже когда `get_tree().paused == true` (меню паузы, экран game over).
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_data()
	_initChallenges()
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.5
	_save_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_save_timer.timeout.connect(_flush_save)
	add_child(_save_timer)

# Объединяет частые мутации (5 saves подряд при одном голе: notifyGoalScored +
# notifyCleanShot + notifyComboFiveGame + add_stars + ...) в одну запись на диск.
# Каждый запрос перезаводит 0.5с таймер; если изменений больше нет — пишем,
# иначе ждём окончания серии. Критические точки (game over, app pause/close)
# должны вызывать save_now() для немедленной записи.
func request_save() -> void:
	_save_pending = true
	_save_timer.start()

func _flush_save() -> void:
	if _save_pending:
		_save_pending = false
		save_data()

func save_now() -> void:
	_save_pending = false
	_save_timer.stop()
	save_data()

func _initChallenges() -> void:
	for id in challenges.keys():
		if _getDefById(id).is_empty():
			challenges.erase(id)
	for def in CHALLENGE_DEFS:
		var id = def["id"]
		if id not in challenges:
			challenges[id] = {"step": 0, "progress": 0, "claimable": false}
	var collector = challenges.get("collector")
	if collector:
		var count = owned_balls.size() - 1
		if count > collector["progress"]:
			collector["progress"] = count
	for def in CHALLENGE_DEFS:
		_refreshClaimable(challenges[def["id"]], def)

func save_data() -> void:
	var data = {
		"version": SAVE_VERSION,
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
	if file == null:
		push_warning("save_data: cannot open %s (err=%s)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_var(data)
	file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("load_data: cannot open %s (err=%s)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	var data = file.get_var()
	file.close()
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
	request_save()

func spend_stars(amount: int) -> bool:
	if stars >= amount:
		stars -= amount
		request_save()
		return true
	return false

func use_heart() -> bool:
	if hearts > 0:
		hearts -= 1
		request_save()
		return true
	return false

func update_best_score(score: int) -> void:
	if score > best_score:
		best_score = score
		_progressChallenge("record")
		# Рекорд — критическая точка: пишем сразу, чтобы при крэше игры
		# (а не при штатном выходе) новый best точно сохранился.
		save_now()

func equip_ball(id: String) -> void:
	equipped_ball = id
	request_save()
	cosmetics_changed.emit()

func equip_bg(id: String) -> void:
	equipped_bg = id
	request_save()
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
	if ch["step"] >= def["chain"].size():
		return
	ch["progress"] += 1
	_refreshClaimable(ch, def)
	request_save()
	challenge_updated.emit()

func _setProgressChallenge(id: String, value: int) -> void:
	if id not in challenges:
		return
	var ch = challenges[id]
	var def = _getDefById(id)
	if ch["step"] >= def["chain"].size():
		return
	if value <= ch["progress"]:
		return
	ch["progress"] = value
	_refreshClaimable(ch, def)
	request_save()
	challenge_updated.emit()

func _refreshClaimable(ch: Dictionary, def: Dictionary) -> void:
	if ch["step"] >= def["chain"].size():
		ch["claimable"] = false
		return
	ch["claimable"] = ch["progress"] >= def["chain"][ch["step"]]

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
	_refreshClaimable(ch, def)
	request_save()
	challenge_updated.emit()

func notifyCleanShot(comboValue: int) -> void:
	_setProgressChallenge("combo", comboValue)

func notifyGoalScored(totalGoals: int) -> void:
	_setProgressChallenge("sniper", totalGoals)

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
	volumes_changed.emit()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	volumes_changed.emit()
