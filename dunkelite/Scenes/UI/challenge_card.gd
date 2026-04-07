extends PanelContainer

@onready var titleLabel: Label        = $MarginContainer/VBoxContainer/TitleRow/TitleLabel
@onready var stepLabel: Label         = $MarginContainer/VBoxContainer/TitleRow/StepLabel
@onready var descLabel: Label         = $MarginContainer/VBoxContainer/DescLabel
@onready var progressBar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var bottomRow: HBoxContainer = $MarginContainer/VBoxContainer/BottomRow
@onready var progressLabel: Label     = $MarginContainer/VBoxContainer/BottomRow/ProgressLabel
@onready var rewardLabel: Label       = $MarginContainer/VBoxContainer/BottomRow/RewardLabel
@onready var claimBtn: Button         = $MarginContainer/VBoxContainer/ClaimButton

var _def: Dictionary = {}

func _ready() -> void:
	for lbl in [titleLabel, stepLabel, descLabel, progressLabel, rewardLabel]:
		lbl.add_to_group("dark_text")

func setup(def: Dictionary) -> void:
	_def = def
	claimBtn.pressed.connect(func(): Global.claimChallenge(_def["id"]))
	refresh()

func refresh() -> void:
	if _def.is_empty():
		return
	var ch = Global.challenges[_def["id"]]
	var step = ch["step"]
	var isCompleted = step >= _def["chain"].size()
	var isClaimable = ch["claimable"]

	titleLabel.text = _def["title"]

	if isCompleted:
		stepLabel.text = "✓"
		descLabel.visible = false
		progressBar.visible = false
		bottomRow.visible = false
		claimBtn.visible = false
		_applyStyle(Color(0.75, 0.75, 0.75, 1.0))
	else:
		stepLabel.text = "%d / %d" % [step, _def["chain"].size()]
		descLabel.visible = true
		descLabel.text = _def["desc"] % _def["chain"][step]
		progressBar.visible = true
		progressBar.max_value = _def["chain"][step]
		progressBar.value = ch["progress"]
		bottomRow.visible = true
		progressLabel.text = "%d / %d" % [ch["progress"], _def["chain"][step]]
		rewardLabel.text = str(_def["stars"][step])
		claimBtn.visible = isClaimable
		_applyStyle(Color(1.0, 1.0, 1.0, 1.0))

func _applyStyle(bgColor: Color, borderColor: Color = Color.TRANSPARENT, borderWidth: int = 0) -> void:
	var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
		style.set_corner_radius_all(12)
	style.bg_color = bgColor
	style.border_color = borderColor
	style.set_border_width_all(borderWidth)
	add_theme_stylebox_override("panel", style)
