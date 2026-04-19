extends Control

signal open_settings
signal open_shop
signal open_quests

@onready var settings_btn: Button = $SettingsBtn
@onready var stars_label: Label = $StarsLabel
@onready var hearts_label: Label = $HeartsLabel
@onready var shop_btn: Button = $ShopBtn
@onready var quests_btn: Button = $QuestsBtn

func _ready() -> void:
	settings_btn.pressed.connect(func(): open_settings.emit())
	shop_btn.pressed.connect(func(): open_shop.emit())
	quests_btn.pressed.connect(func(): open_quests.emit())
	update_data()

func update_data() -> void:
	stars_label.text = " " + str(Global.stars)
	hearts_label.text = " " + str(Global.hearts)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		update_data()
