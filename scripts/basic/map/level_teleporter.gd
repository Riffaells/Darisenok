extends Area2D
class_name LevelTeleporter

# Этот скрипт телепортирует игрока на другой уровень при входе в зону.

@export_file("*.tscn") var target_level_path: String = ""

func _ready():
	# Подключаем сигнал входа тела в зону
	body_entered.connect(_on_body_entered)
	
	collision_layer = 0  # Сам телепорт не должен быть физическим объектом
	collision_mask = 2   # Сканируем только слой 2, на котором находится игрок

func _on_body_entered(body):
	# Проверяем, что вошедший объект - это игрок
	if body.is_in_group("player"):
		# Проверяем, что путь к уровню указан и файл существует
		if not target_level_path.is_empty() and FileAccess.file_exists(target_level_path):
			# Специальная проверка только для game_level_3 - нужно 4 кристалла
			if target_level_path.contains("game_level_3") or target_level_path.contains("c1g1xnod5s3gj"):
				var game_state = get_node_or_null("/root/GameStateManager")
				if game_state:
					var collected_crystals = game_state.get_collected_crystals()
					if collected_crystals < 4:
						call_deferred("show_crystal_requirement_message")
						return
				else:
					pass # Enough crystals
			
			call_deferred("change_scene", target_level_path)
		else:
			pass # No target level path

func change_scene(path: String):
	"""Безопасная смена сцены"""
	get_tree().change_scene_to_file(path)

func show_crystal_requirement_message():
	"""Показывает сообщение о требовании кристаллов"""
	create_notification_text("Не хватает кристаллов Воспоминаний")

func create_notification_text(message: String):
	"""Создает временное текстовое уведомление"""
	var label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.RED)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Позиционируем по центру экрана
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	label.position = Vector2(screen_size.x / 2 - 200, screen_size.y / 2 - 25)
	label.size = Vector2(400, 50)
	
	# Добавляем к сцене
	get_tree().current_scene.add_child(label)
	
	# Анимация появления и исчезновения
	var tween = create_tween()
	label.modulate.a = 0.0
	tween.tween_property(label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.5)  # Показываем 1.5 секунды
	tween.tween_property(label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(label.queue_free)
