extends Control

# Простые прокручиваемые титры

@onready var scrolling_credits: Control = $ScrollingCredits
@onready var credits_container: Control = $ScrollingCredits/CreditsContainer
@onready var title: Label = $ScrollingCredits/CreditsContainer/Title
@onready var controls_hint: Label = $ControlsHint
@onready var background: ColorRect = $Background

# Параметры прокрутки
var scroll_speed: float = 50.0  # Обычная скорость (пикселей в секунду)
var fast_scroll_speed: float = 150.0  # Быстрая скорость при зажатом пробеле
var current_speed: float = 0.0
var is_scrolling: bool = false
var scroll_tween: Tween

func _ready():
	# Перемещаем контейнер за нижний край экрана для анимации
	var screen_height = get_viewport().get_visible_rect().size.y
	credits_container.position.y = screen_height
	
	# Запускаем анимацию появления
	animate_credits_appearance()
	
	# Запускаем прокрутку с задержкой
	await get_tree().create_timer(3.0).timeout
	start_scrolling()

func animate_credits_appearance():
	"""Анимирует появление элементов титров с красивыми эффектами"""
	# Скрываем все элементы
	background.modulate.a = 0.0
	title.modulate.a = 0.0
	controls_hint.modulate.a = 0.0
	
	# Скрываем все дочерние элементы контейнера
	for child in credits_container.get_children():
		if child is Label:
			child.modulate.a = 0.0
	
	# Анимируем появление
	var tween = create_tween()
	
	# Фон
	tween.tween_property(background, "modulate:a", 1.0, 1.0)
	tween.tween_interval(0.5)
	
	# Заголовок
	tween.parallel().tween_property(title, "modulate:a", 1.0, 1.0)
	tween.tween_interval(0.3)
	
	# Все остальные элементы
	for child in credits_container.get_children():
		if child is Label and child != title:
			tween.parallel().tween_property(child, "modulate:a", 1.0, 0.8)
			tween.tween_interval(0.1)
	
	# Подсказки управления
	tween.parallel().tween_property(controls_hint, "modulate:a", 1.0, 0.6)

func start_scrolling():
	"""Запускает прокрутку титров"""
	is_scrolling = true
	current_speed = scroll_speed
	
	# Вычисляем расстояние прокрутки
	var screen_height = get_viewport().get_visible_rect().size.y
	var container_height = credits_container.size.y
	var scroll_distance = container_height + screen_height
	
	# Создаем анимацию прокрутки
	scroll_tween = create_tween()
	
	# Анимируем движение вверх
	var duration = scroll_distance / current_speed
	scroll_tween.tween_property(credits_container, "position:y", -container_height, duration)
	
	# После завершения - показываем кнопки управления
	scroll_tween.tween_callback(show_end_options)

func update_scroll_speed():
	"""Обновляет скорость прокрутки"""
	if not scroll_tween:
		return
	
	# Получаем текущую позицию
	var current_pos = credits_container.position.y
	var target_pos = -credits_container.size.y
	var remaining_distance = abs(target_pos - current_pos)
	
	# Пересчитываем время с новой скоростью
	var new_duration = remaining_distance / current_speed
	
	# Перезапускаем анимацию с новой скоростью
	scroll_tween.kill()
	scroll_tween = create_tween()
	scroll_tween.tween_property(credits_container, "position:y", target_pos, new_duration)
	scroll_tween.tween_callback(show_end_options)

func show_end_options():
	"""Показывает опции в конце титров"""
	# Создаем кнопки управления
	var end_container = VBoxContainer.new()
	end_container.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, get_viewport().get_visible_rect().size.y / 2)
	
	var restart_btn = Button.new()
	restart_btn.text = "Начать заново"
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.pressed.connect(_on_restart_pressed)
	
	var exit_btn = Button.new()
	exit_btn.text = "Выход"
	exit_btn.add_theme_font_size_override("font_size", 24)
	exit_btn.pressed.connect(_on_exit_pressed)
	
	end_container.add_child(restart_btn)
	end_container.add_child(exit_btn)
	add_child(end_container)
	
	# Анимация появления кнопок
	end_container.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(end_container, "modulate:a", 1.0, 1.0)

func _process(_delta):
	"""Обрабатывает ввод каждый кадр"""
	if not is_scrolling:
		return
	
	# Проверяем зажат ли пробел для ускорения
	var space_pressed = Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)
	var new_speed = fast_scroll_speed if space_pressed else scroll_speed
	
	# Обновляем скорость если она изменилась
	if abs(new_speed - current_speed) > 1.0:
		current_speed = new_speed
		update_scroll_speed()

func _on_restart_pressed():
	"""Перезапускает игру"""
	# Сбрасываем состояние игры
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		game_state.reset_crystals()
		# Можно добавить сброс других состояний
	
	# Возвращаемся на первый уровень
	get_tree().change_scene_to_file("res://scenes/levels/game_level_1.tscn")

func _on_exit_pressed():
	"""Выходит из игры"""
	get_tree().quit()

func _input(event):
	"""Обрабатывает нажатие клавиш"""
	if event.is_action_pressed("ui_cancel"):
		_on_exit_pressed()
	elif event.is_action_pressed("ui_accept") and not is_scrolling:
		_on_restart_pressed()
