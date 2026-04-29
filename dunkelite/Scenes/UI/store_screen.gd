extends Control

signal back

const HEART_PRICE   := 25
const HEARTS_AMOUNT := 1

@onready var panel:          TextureRect     = $Panel
@onready var back_btn:       Button          = $MainLayout/Header/Content/Button
@onready var scroll:         ScrollContainer = $MainLayout/ScrollContainer
@onready var stars_label:    Label           = $MainLayout/Header/Content/StarsLabel
@onready var hearts_top_label: Label         = $MainLayout/Header/Content/HeartsLabel
@onready var balls_grid:     GridContainer   = $MainLayout/ScrollContainer/VBoxContainer/BallsSection/BallsGrid
@onready var bgs_grid:       GridContainer   = $MainLayout/ScrollContainer/VBoxContainer/BackgroundsSection/BgsGrid
@onready var buy_hearts_btn: Button          = $MainLayout/ScrollContainer/VBoxContainer/HeartsSection/HeartsVBox/HeartsIcon/BuyHeartsButton

@onready var balls_tab_btn:  Button  = $MainLayout/TabsPanel/TabsRow/BallsTabBtn
@onready var bgs_tab_btn:    Button  = $MainLayout/TabsPanel/TabsRow/BgsTabBtn
@onready var hearts_tab_btn: Button  = $MainLayout/TabsPanel/TabsRow/HeartsTabBtn

@onready var balls_section:  Control = $MainLayout/ScrollContainer/VBoxContainer/BallsSection
@onready var bgs_section:    Control = $MainLayout/ScrollContainer/VBoxContainer/BackgroundsSection
@onready var hearts_section: Control = $MainLayout/ScrollContainer/VBoxContainer/HeartsSection

var _tab_buttons: Array[Button] = []
var _sections: Array[Control] = []
var _active_style: StyleBoxFlat
var _inactive_style: StyleBoxFlat


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.add_to_group("header_ui")
	back_btn.modulate = Color(6.0, 6.0, 6.0, 1.0)
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

	# Настраиваем вкладки
	_tab_buttons = [balls_tab_btn, bgs_tab_btn, hearts_tab_btn]
	_sections = [balls_section, bgs_section, hearts_section]

	_active_style = StyleBoxFlat.new()
	_active_style.bg_color = Color(1, 1, 1, 0.15)
	_active_style.border_width_bottom = 3
	_active_style.border_color = Color(1, 1, 1, 0.9)
	_active_style.corner_radius_top_left = 6
	_active_style.corner_radius_top_right = 6

	_inactive_style = StyleBoxFlat.new()
	_inactive_style.bg_color = Color(0, 0, 0, 0)

	balls_tab_btn.pressed.connect(func(): _scroll_to_section(0))
	bgs_tab_btn.pressed.connect(func(): _scroll_to_section(1))
	hearts_tab_btn.pressed.connect(func(): _scroll_to_section(2))

	scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)

	_set_active_tab(0)
	_refresh_all()
	_update_store_bg()


func _scroll_to_section(index: int) -> void:
	var section := _sections[index]
	scroll.scroll_vertical = int(section.position.y)


func _on_scroll_changed(_value: float) -> void:
	var scroll_y := scroll.scroll_vertical
	var active_index := 0
	for i in range(_sections.size()):
		if scroll_y >= _sections[i].position.y - 100:
			active_index = i
	_set_active_tab(active_index)


func _set_active_tab(index: int) -> void:
	for i in range(_tab_buttons.size()):
		var style: StyleBoxFlat
		var color: Color
		if i == index:
			style = _active_style
			color = Color(1, 1, 1, 1)
		else:
			style = _inactive_style
			color = Color(0.7, 0.7, 0.7, 1)
		_tab_buttons[i].add_theme_stylebox_override("normal", style)
		_tab_buttons[i].add_theme_stylebox_override("hover", style)
		_tab_buttons[i].add_theme_stylebox_override("pressed", style)
		_tab_buttons[i].add_theme_color_override("font_color", color)
		_tab_buttons[i].add_theme_color_override("font_hover_color", color)
		_tab_buttons[i].add_theme_color_override("font_pressed_color", color)


func _make_scrollable(node: Node) -> void:
	for child in node.get_children():
		if child is Control and not (child is BaseButton):
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		_make_scrollable(child)


# ══════════════════════════════════════════════════════════════════
#  ОБРАБОТКА НАЖАТИЙ
# ══════════════════════════════════════════════════════════════════
func _on_item_pressed(id: String, is_ball: bool, price: int) -> void:
	if is_ball:
		if id not in Global.owned_balls:
			if not Global.spend_stars(price):
				return
			Global.owned_balls.append(id)
			Global.notifyBallPurchased()
		Global.equip_ball(id)   # сохраняет + эмитит cosmetics_changed
	else:
		if id not in Global.owned_backgrounds:
			if not Global.spend_stars(price):
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
