# SceneTransition.gd (Автозагрузка)
extends CanvasLayer

# Ссылки на наши ноды
@onready var animation_player = $AnimationPlayer
@onready var color_rect = $ColorRect

# Переменная, чтобы предотвратить двойную смену сцены
var is_transitioning: bool = false

# Публичный метод для смены сцены. Его будем вызывать из любого места игры.
func change_scene(target_scene_path: String) -> void:
	if is_transitioning:
		return # Уже меняем сцену, выходим
	is_transitioning = true
	
	# 1. Проверяем, существует ли файл сцены
	if not ResourceLoader.exists(target_scene_path):
		push_error("Смена сцены не удалась: файл не найден - " + target_scene_path)
		is_transitioning = false
		return
	
	# 2. Запускаем анимацию исчезновения и ждем её окончания
	animation_player.play("fade_out")
	await animation_player.animation_finished
	
	# 3. Пытаемся загрузить и сменить сцену
	var result = get_tree().change_scene_to_file(target_scene_path)
	
	# 4. Проверяем на ошибки
	if result != OK:
		push_error("Смена сцены не удалась с ошибкой: ", result)
		is_transitioning = false
		return
	
	# 5. Даем новой сцене кадр для инициализации, потом запускаем появление
	await get_tree().process_frame
	animation_player.play("fade_in")
	await animation_player.animation_finished
	
	# 6. Завершаем состояние перехода
	is_transitioning = false

# Можно добавить методы для разных типов переходов
func change_scene_with_custom_fade(target_scene_path: String, fade_out_anim: String, fade_in_anim: String) -> void:
	# Аналогично, но с возможностью выбора анимации
	pass
