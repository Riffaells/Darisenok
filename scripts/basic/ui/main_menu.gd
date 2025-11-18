extends Control

# Главное меню игры "Кристаллы Воспоминаний"

@onready var game_title: Label = $GameTitle
@onready var subtitle: Label = $Subtitle
@onready var start_button: Button = $StartButton
@onready var exit_button: Button = $ExitButton
@onready var game_info: RichTextLabel = $GameInfo
@onready var controls_hint: Label = $ControlsHint

func _ready():
	# Настраиваем стили
	setup_menu_styles()
	
	# Подключаем кнопки
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Подключаем эффекты наведения
	start_button.mouse_entered.connect(_on_start_button_hover)
	start_button.mouse_exited.connect(_on_start_button_unhover)
	exit_button.mouse_entered.connect(_on_exit_button_hover)
	exit_button.mouse_exited.connect(_on_exit_button_unhover)
	
	# Запускаем анимацию появления
	animate_menu_appearance()
	
	# Фокусируемся на кнопке "Начать игру"
	start_button.grab_focus()

func setup_menu_styles():
	"""Настраивает стили для элементов меню"""
	# Заголовок игры
	game_title.add_theme_font_size_override("font_size", 48)
	game_title.add_theme_color_override("font_color", Color.GOLD)
	game_title.add_theme_color_override("font_shadow_color", Color.BLACK)
	game_title.add_theme_constant_override("shadow_offset_x", 4)
	game_title.add_theme_constant_override("shadow_offset_y", 4)
	
	# Подзаголовок
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	subtitle.add_theme_color_override("font_shadow_color", Color.BLACK)
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	
	# Кнопки
	start_button.add_theme_font_size_override("font_size", 28)
	exit_button.add_theme_font_size_override("font_size", 24)
	
	# Подсказки управления
	controls_hint.add_theme_font_size_override("font_size", 14)
	controls_hint.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	controls_hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	controls_hint.add_theme_constant_override("shadow_offset_x", 1)
	controls_hint.add_theme_constant_override("shadow_offset_y", 1)

func animate_menu_appearance():
	"""Анимирует появление элементов меню с красивыми эффектами"""
	# Устанавливаем pivot_offset для масштабирования от центра
	game_title.pivot_offset = game_title.size / 2
	start_button.pivot_offset = start_button.size / 2
	exit_button.pivot_offset = exit_button.size / 2
	
	# Скрываем все элементы и устанавливаем начальные состояния
	game_title.modulate.a = 0.0
	game_title.scale = Vector2(0.3, 0.3)  # Масштабируется от центра
	
	subtitle.modulate.a = 0.0
	subtitle.position.x -= 100
	
	start_button.modulate.a = 0.0
	start_button.scale = Vector2(0.8, 0.8)  # Масштабируется от центра
	start_button.position.y += 30  # Движение сверху
	
	exit_button.modulate.a = 0.0
	exit_button.scale = Vector2(0.8, 0.8)  # Масштабируется от центра
	exit_button.position.x -= 50  # Движение слева (как ты хотел)
	
	game_info.modulate.a = 0.0
	game_info.position.y += 30
	
	controls_hint.modulate.a = 0.0
	controls_hint.position.x += 50
	
	# Сохраняем оригинальные позиции
	var original_subtitle_pos = subtitle.position.x + 100
	var original_start_pos = start_button.position.y - 30
	var original_exit_pos = exit_button.position.x + 50
	var original_info_pos = game_info.position.y - 30
	var original_hint_pos = controls_hint.position.x - 50
	
	# Анимируем появление с эффектами
	var tween = create_tween()
	
	# Заголовок - масштабирование от центра + появление
	tween.parallel().tween_property(game_title, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(game_title, "scale", Vector2(1.0, 1.0), 1.0)
	tween.tween_interval(0.3)
	
	# Подзаголовок - скольжение слева
	tween.parallel().tween_property(subtitle, "modulate:a", 1.0, 0.6)
	tween.parallel().tween_property(subtitle, "position:x", original_subtitle_pos, 0.6)
	tween.tween_interval(0.4)
	
	# Кнопка "Начать игру" - движение сверху + масштабирование от центра
	tween.parallel().tween_property(start_button, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.5)
	tween.parallel().tween_property(start_button, "position:y", original_start_pos, 0.5)
	tween.tween_interval(0.2)
	
	# Кнопка "Выход" - скольжение слева + масштабирование от центра
	tween.parallel().tween_property(exit_button, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(exit_button, "scale", Vector2(1.0, 1.0), 0.5)
	tween.parallel().tween_property(exit_button, "position:x", original_exit_pos, 0.5)
	tween.tween_interval(0.2)
	
	# Информация об игре - движение снизу
	tween.parallel().tween_property(game_info, "modulate:a", 1.0, 0.6)
	tween.parallel().tween_property(game_info, "position:y", original_info_pos, 0.6)
	tween.tween_interval(0.1)
	
	# Подсказки управления - скольжение справа
	tween.parallel().tween_property(controls_hint, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(controls_hint, "position:x", original_hint_pos, 0.4)
	tween.tween_interval(0.3)
	
	# Subtitle2 (кодовое название) - последняя анимация, появление снизу
	var subtitle2 = $Subtitle2
	if subtitle2:
		subtitle2.modulate.a = 0.0
		subtitle2.position.y += 20
		var original_subtitle2_pos = subtitle2.position.y - 20
		
		tween.parallel().tween_property(subtitle2, "modulate:a", 1.0, 0.8)
		tween.parallel().tween_property(subtitle2, "position:y", original_subtitle2_pos, 0.8)

func _on_start_pressed():
	"""Начинает игру"""
	# Анимация исчезновения перед переходом
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/levels/game_level_1.tscn"))

func _on_exit_pressed():
	"""Выходит из игры"""
	# Анимация исчезновения перед выходом
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().quit())

func _input(event):
	"""Обрабатывает нажатие клавиш"""
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_ENTER and event.pressed):
		_on_start_pressed()
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		_on_exit_pressed()



func _on_start_button_hover():
	"""Эффект при наведении на кнопку старта"""
	var tween = create_tween()
	tween.parallel().tween_property(start_button, "scale", Vector2(1.1, 1.1), 0.2)
	tween.parallel().tween_property(start_button, "rotation", deg_to_rad(2), 0.2)

func _on_start_button_unhover():
	"""Эффект при уходе курсора с кнопки старта"""
	var tween = create_tween()
	tween.parallel().tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(start_button, "rotation", 0.0, 0.2)

func _on_exit_button_hover():
	"""Эффект при наведении на кнопку выхода"""
	var tween = create_tween()
	tween.parallel().tween_property(exit_button, "scale", Vector2(1.1, 1.1), 0.2)
	tween.parallel().tween_property(exit_button, "rotation", deg_to_rad(-2), 0.2)

func _on_exit_button_unhover():
	"""Эффект при уходе курсора с кнопки выхода"""
	var tween = create_tween()
	tween.parallel().tween_property(exit_button, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(exit_button, "rotation", 0.0, 0.2)
