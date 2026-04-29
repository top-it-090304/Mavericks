@tool
extends Panel

## Уникальный id товара (напр. "default", "ball1", "fon2")
@export var item_id: String = ""

## Текстура-превью товара
@export var item_texture: Texture2D:
	set(v):
		item_texture = v
		_apply_texture()

## Фоновая текстура карточки (необязательно)
@export var card_bg: Texture2D:
	set(v):
		card_bg = v
		if is_inside_tree() and has_node("CardBg"):
			$CardBg.texture = v

## true = мяч (STRETCH_KEEP_ASPECT_CENTERED)
## false = фон (STRETCH_KEEP_ASPECT_COVERED)
@export var is_ball: bool = true:
	set(v):
		is_ball = v
		_apply_texture()

## Цена в звёздах
@export var price: int = 50:
	set(v):
		price = v
		if is_inside_tree() and has_node("LockOverlay/PriceLabel"):
			$LockOverlay/PriceLabel.text = str(v) + " ★"

signal item_pressed(item_id: String, is_ball: bool, price: int)

var _style: StyleBoxFlat
var _press_pos := Vector2.ZERO
var _is_pressed := false


func _ready() -> void:
	_apply_texture()
	if has_node("CardBg"):
		$CardBg.texture = card_bg
	if has_node("LockOverlay/PriceLabel"):
		$LockOverlay/PriceLabel.text = str(price) + " ★"

	# Дублируем стиль рамки у Border-ноды
	if has_node("Border"):
		var base: StyleBox = $Border.get_theme_stylebox("panel")
		if base is StyleBoxFlat:
			_style = base.duplicate()
			$Border.add_theme_stylebox_override("panel", _style)

	if not Engine.is_editor_hint():
		# Отключаем ClickButton — он блокирует прокрутку ScrollContainer на тач-устройствах.
		# Вместо этого детектим тапы через gui_input на самой Panel.
		if has_node("ClickButton"):
			$ClickButton.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mouse_filter = Control.MOUSE_FILTER_PASS
		gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
			_is_pressed = true
		elif _is_pressed:
			_is_pressed = false
			if _press_pos.distance_to(event.position) < 20.0:
				item_pressed.emit(item_id, is_ball, price)


func _apply_texture() -> void:
	if not is_inside_tree() or not has_node("Preview"):
		return
	$Preview.texture = item_texture
	$Preview.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED if is_ball
		else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	)


## Обновляет визуал ячейки: рамка + замок
func set_state(owned: bool, equipped: bool) -> void:
	if has_node("LockOverlay"):
		$LockOverlay.visible = not owned
	if not _style:
		return
	if equipped:
		_style.border_color = Color(1, 0.84, 0, 1)
		_style.set_border_width_all(4)
	elif owned:
		_style.border_color = Color(0.6, 0.6, 0.7, 0.7)
		_style.set_border_width_all(3)
	else:
		_style.border_color = Color(0.3, 0.3, 0.4, 0.6)
		_style.set_border_width_all(3)
