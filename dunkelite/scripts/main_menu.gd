extends Control

# Ссылки на узлы
@onready var ball_display = $BallCarousel/BallDisplay
@onready var left_arrow = $BallCarousel/LeftArrow
@onready var right_arrow = $BallCarousel/RightArrow
@onready var stars_label = $TopBar/StarsLabel
@onready var score_label = $TopBar/ScoreLabel
@onready var play_button = $BottomBar/PlayButton

# Текущий индекс мяча
var current_ball_index: int = 0

func _ready():
	# Подключаем сигналы
	setup_signals()
	
	# Загружаем данные из Global
	update_stars_display(Global.stars)
	update_ball_display(Global.selected_ball)
	
	# Подключаемся к сигналам Global для автоматического обновления
	Global.stars_changed.connect(update_stars_display)
	Global.selected_ball_changed.connect(update_ball_display)
	
	# Анимация появления меню
	animate_menu_appear()

func setup_signals():
	# Кнопки карусели
	left_arrow.pressed.connect(_on_left_arrow_pressed)
	right_arrow.pressed.connect(_on_right_arrow_pressed)
	
	# Кнопка Play
	play_button.pressed.connect(_on_play_pressed)
	
	# Делаем мяч кликабельным (как в Dunk Shot - нажатие на мяч запускает игру)
	ball_display.gui_input.connect(_on_ball_gui_input)

func _on_left_arrow_pressed():
	# Переключение на предыдущий мяч
	current_ball_index = (current_ball_index - 1 + Global.balls.size()) % Global.balls.size()
	Global.selected_ball = current_ball_index  # Обновит глобальную переменную и вызовет сигнал
	
	# Анимация листания
	animate_ball_switch(-50)  # Сдвиг влево

func _on_right_arrow_pressed():
	# Переключение на следующий мяч
	current_ball_index = (current_ball_index + 1) % Global.balls.size()
	Global.selected_ball = current_ball_index
	
	# Анимация листания
	animate_ball_switch(50)  # Сдвиг вправо

func update_ball_display(index: int):
	# Обновляем отображение мяча
	var texture_path = Global.balls[index]
	var texture = load(texture_path)
	ball_display.texture = texture
	
	# Можно добавить эффект "выбора" (подсветку)
	current_ball_index = index

func update_stars_display(value: int):
	stars_label.text = "★ " + str(value)

func animate_ball_switch(direction: int):
	# Плавная анимация переключения мяча
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Сдвигаем в сторону и возвращаем обратно
	tween.tween_property(ball_display, "position:x", direction, 0.1)
	tween.tween_property(ball_display, "position:x", 0, 0.2)

func _on_ball_gui_input(event):
	# Клик по мячу запускает игру (как в оригинале)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_play_pressed()

func _on_play_pressed():
	# Анимация нажатия на мяч
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ball_display, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(ball_display, "modulate:a", 0.0, 0.15)
	
	# Ждем анимацию и запускаем переход
	await tween.finished
	
func animate_menu_appear():
	# Плавное появление меню при загрузке
	modulate.a = 0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	
	# Анимация вылета мяча
	tween.parallel().tween_property(ball_display, "scale", Vector2(1, 1), 0.4).from(Vector2(0, 0))
