extends Area2D
class_name CollectibleFlower

# Скрипт для цветка, который можно собрать
# Цветок не уничтожается и не скрывается, просто регистрируется сбор

@export var flower_id: String = ""

func _ready():
	# Настраиваем коллизию для взаимодействия с игроком
	# Устанавливаем маску на слой 2, где находится игрок
	collision_layer = 0 # Сам цветок не должен быть на каком-то слое
	collision_mask = 2 # Сканируем только слой 2 (игрок)
	
	var game_state = get_node_or_null("/root/GameStateManager")
	if not game_state:
		return
	
	# Если цветок уже собран, отключаем коллизию
	if game_state.is_flower_collected(flower_id):
		disable_collision()
		return
	
	# Подключаемся к сигналу входа в зону
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Проверяем, что это игрок
	if body.is_in_group("player"):
		var game_state = get_node_or_null("/root/GameStateManager")
		if game_state:
			# Отмечаем цветок как собранный
			game_state.collect_flower(flower_id)
		
		# Отключаем коллизию, чтобы нельзя было собрать повторно
		call_deferred("disable_collision")
		
		# Показываем временное сообщение
		show_collection_message()

func disable_collision():
	# Отключаем коллизию с использованием set_deferred для безопасности
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func show_collection_message():
	"""Показывает временное сообщение о сборе цветка"""
	var label = Label.new()
	label.text = "Собран цветок!"
	
	# Позиционируем над цветком
	label.global_position = global_position - Vector2(50, 30)
	
	# Настройки шрифта
	var font = load("res://assets/fonts/PixelFont/PixelFont.ttf")
	if font:
		var label_settings = LabelSettings.new()
		label_settings.font = font
		label_settings.font_size = 16
		label_settings.font_color = Color.WHITE
		label_settings.outline_size = 3
		label_settings.outline_color = Color.BLACK
		label.label_settings = label_settings

	get_tree().current_scene.add_child(label)
	
	# Таймер на удаление
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(label.queue_free)
