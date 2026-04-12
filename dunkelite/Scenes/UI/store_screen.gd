extends Control

signal back

const ITEM_PRICE    := 100
const HEART_PRICE   := 50
const HEARTS_AMOUNT := 1

@onready var panel:          TextureRect     = $Panel
@onready var back_btn:       Button          = $Panel/Button
@onready var scroll:         ScrollContainer = $Panel/ScrollContainer
@onready var stars_label:    Label           = $Panel/StarsLabel
@onready var hearts_top_label: Label         = $Panel/HeartsLabel
@onready var balls_grid:     GridContainer   = $Panel/ScrollContainer/VBoxContainer/BallsSection/BallsGrid
@onready var bgs_grid:       GridContainer   = $Panel/ScrollContainer/VBoxContainer/BackgroundsSection/BgsGrid
@onready var buy_hearts_btn: Button          = $Panel/ScrollContainer/VBoxContainer/HeartsSection/HeartsVBox/HeartsIcon/BuyHeartsButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.pressed.connect(func(): back.emit())
	buy_hearts_btn.pressed.connect(_on_buy_hearts)

	# Разрешаем тач-прокрутку: все не-кнопки внутри ScrollContainer пропускают события
	_make_scrollable(scroll)

	for item in balls_grid.get_children():
		item.item_pressed.connect(_on_item_pressed)
	for item in bgs_grid.get_children():
		item.item_pressed.connect(_on_item_pressed)

	# Мгновенно реагируем на смену косметики (в т.ч. из других мест)
	Global.cosmetics_changed.connect(_on_cosmetics_changed)

	_refresh_all()
	_update_store_bg()


func _make_scrollable(node: Node) -> void:
	for child in node.get_children():
		if child is Control and not (child is BaseButton):
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		_make_scrollable(child)


# ══════════════════════════════════════════════════════════════════
#  ОБРАБОТКА НАЖАТИЙ
# ══════════════════════════════════════════════════════════════════
func _on_item_pressed(id: String, is_ball: bool) -> void:
	if is_ball:
		if id not in Global.owned_balls:
			if not Global.spend_stars(ITEM_PRICE):
				return
			Global.owned_balls.append(id)
			Global.notifyBallPurchased()
		Global.equip_ball(id)   # сохраняет + эмитит cosmetics_changed
	else:
		if id not in Global.owned_backgrounds:
			if not Global.spend_stars(ITEM_PRICE):
				return
			Global.owned_backgrounds.append(id)
		Global.equip_bg(id)     # сохраняет + эмитит cosmetics_changed


func _on_buy_hearts() -> void:
	if Global.spend_stars(HEART_PRICE):
		Global.hearts += HEARTS_AMOUNT
		Global.save_data()
		_refresh_all()


# ══════════════════════════════════════════════════════════════════
#  ОБНОВЛЕНИЕ ВИЗУАЛА
# ══════════════════════════════════════════════════════════════════
func _on_cosmetics_changed() -> void:
	_refresh_all()
	_update_store_bg()


func _update_store_bg() -> void:
	# Меняем фон самого магазина на выбранный фон
	for item in bgs_grid.get_children():
		if item.item_id == Global.equipped_bg:
			panel.texture = item.item_texture
			return


func _refresh_all() -> void:
	stars_label.text      = " " + str(Global.stars)
	hearts_top_label.text = " " + str(Global.hearts)

	for item in balls_grid.get_children():
		item.set_state(
			item.item_id in Global.owned_balls,
			item.item_id == Global.equipped_ball
		)
	for item in bgs_grid.get_children():
		item.set_state(
			item.item_id in Global.owned_backgrounds,
			item.item_id == Global.equipped_bg
		)
