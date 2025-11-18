extends Control
class_name AmuletCharacter

# Простой амулет-персонаж рядом с hotbar

@export var default_texture_number: int = 16  # По умолчанию 16.png

var current_texture_number: int = 16
var base_path: String = "res://assets/rpg cutie/"
var is_clickable: bool = false  # Можно ли кликать по амулету

@onready var sprite: TextureRect = $Sprite

func _ready():
	# Загружаем текстуру по умолчанию
	set_texture(default_texture_number)
	
	# Добавляем в группы для правильной работы
	add_to_group("amulet_character")
	add_to_group("ui_elements")
	
	# Подключаем клик
	gui_input.connect(_on_gui_input)
	
	# Проверяем состояние амулета с задержкой
	call_deferred("check_amulet_state")

func check_amulet_state():
	"""Проверяет состояние амулета после инициализации"""
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		# Подключаемся к сигналу получения амулета
		if not game_state.amulet_obtained.is_connected(_on_amulet_obtained):
			game_state.amulet_obtained.connect(_on_amulet_obtained)
		
		# Проверяем сохраненную текстуру амулета
		var saved_texture = game_state.get_amulet_texture()
		if saved_texture != default_texture_number:
			set_texture(saved_texture)
		
		# Проверяем текущее состояние
		if game_state.get_has_amulet():
			# Амулет уже получен - показываем
			visible = true
			is_clickable = true
		else:
			# Амулет еще не получен - скрываем
			visible = false
			is_clickable = false
	else:
		# По умолчанию скрываем
		visible = false
		is_clickable = false

func _on_amulet_obtained():
	"""Вызывается когда игрок получает амулет"""
	show_amulet()

func set_texture(texture_number: int):
	"""Устанавливает текстуру амулета"""
	current_texture_number = texture_number
	var texture_path = base_path + str(texture_number) + ".png"
	
	var texture = load(texture_path)
	if texture and sprite:
		sprite.texture = texture

func show_emotion(emotion: String):
	"""Показывает эмоцию через смену текстуры"""
	match emotion:
		"happy":
			set_texture(17)  # Счастливый
		"sad":
			set_texture(18)  # Грустный
		"angry":
			set_texture(19)  # Злой
		"surprised":
			set_texture(20)  # Удивленный
		"normal":
			set_texture(16)  # Обычный
		_:
			set_texture(16)  # По умолчанию обычный

func show_amulet():
	"""Показывает амулет после получения"""
	visible = true
	is_clickable = true

func hide_amulet():
	"""Скрывает амулет"""
	visible = false
	is_clickable = false

func _on_gui_input(event):
	"""Обрабатывает клик по амулету"""
	if not is_clickable or not visible:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			use_amulet()

func use_amulet():
	"""Использует амулет для активации магических объектов"""
	# Ищем ближайший магический камень
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var magic_stones = get_tree().get_nodes_in_group("magic_stones")
	
	var closest_stone = null
	var closest_distance = 999999.0
	
	for stone in magic_stones:
		var distance = player.global_position.distance_to(stone.global_position)
		
		if stone.has_method("is_player_nearby"):
			var nearby = stone.is_player_nearby()
			if nearby:
				if distance < closest_distance:
					closest_distance = distance
					closest_stone = stone
	
	if closest_stone:
		closest_stone.activate_stone()
		show_use_effect()

func show_use_effect():
	"""Показывает эффект использования амулета"""
	# Анимация мигания
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.CYAN, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite, "modulate", Color.CYAN, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
