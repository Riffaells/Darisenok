extends Control
class_name CrystalCounter

# Кристалл-счетчик осколков в правом верхнем углу

@export var crystal_texture_number: int = 17  # Текстура кристалла 17.png
@export var max_shards: int = 5  # Максимальное количество осколков для сбора

var current_shards: int = 0
var base_path: String = "res://assets/rpg cutie/"

@onready var crystal_sprite: TextureRect = $CrystalSprite
@onready var shard_label: Label = $ShardLabel

func _ready():
	# Добавляем в группу для поиска
	add_to_group("crystal_counter")
	
	# Загружаем текстуру кристалла
	set_crystal_texture(crystal_texture_number)
	
	# Настраиваем текст
	setup_label()
	
	# Синхронизируем с GameStateManager
	sync_with_game_state()
	
	# Подключаемся к обновлениям GameStateManager
	setup_game_state_connection()
	
	# Обновляем отображение
	update_display()
	
	print("Кристалл-счетчик создан. Нужно собрать осколков: ", max_shards)

func sync_with_game_state():
	"""Синхронизирует счетчик с GameStateManager"""
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		current_shards = game_state.get_collected_crystals()
		max_shards = game_state.get_max_crystals()
		print("🔄 Синхронизация с GameStateManager: ", current_shards, "/", max_shards)

func set_crystal_texture(texture_number: int):
	"""Устанавливает текстуру кристалла"""
	var texture_path = base_path + str(texture_number) + ".png"
	
	var texture = load(texture_path)
	if texture and crystal_sprite:
		crystal_sprite.texture = texture
		print("Установлена текстура кристалла: ", texture_number)
	else:
		print("Не удалось загрузить текстуру кристалла: ", texture_path)

func setup_label():
	"""Настраивает текст счетчика"""
	if shard_label:
		# Настраиваем шрифт и размер
		shard_label.add_theme_font_size_override("font_size", 16)
		shard_label.add_theme_color_override("font_color", Color.WHITE)
		shard_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		shard_label.add_theme_constant_override("shadow_offset_x", 1)
		shard_label.add_theme_constant_override("shadow_offset_y", 1)
		
		# Выравнивание по центру
		shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shard_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func update_display():
	"""Обновляет отображение счетчика"""
	if shard_label:
		shard_label.text = str(current_shards) + "/" + str(max_shards)

func add_shard(amount: int = 1):
	"""Добавляет осколки"""
	current_shards = min(current_shards + amount, max_shards)
	update_display()
	
	print("Собрано осколков: ", current_shards, "/", max_shards)
	
	# Синхронизируем с GameStateManager
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		# Обновляем состояние в GameStateManager
		game_state.collected_crystals = current_shards
	
	# Проверяем, собраны ли все осколки
	if current_shards >= max_shards:
		on_all_shards_collected()

func remove_shard(amount: int = 1):
	"""Убирает осколки"""
	current_shards = max(current_shards - amount, 0)
	update_display()
	
	print("Потеряно осколков: ", amount, ". Осталось: ", current_shards, "/", max_shards)

func set_shards(amount: int):
	"""Устанавливает точное количество осколков"""
	current_shards = clamp(amount, 0, max_shards)
	update_display()

func get_shards() -> int:
	"""Возвращает текущее количество осколков"""
	return current_shards

func is_complete() -> bool:
	"""Проверяет, собраны ли все осколки"""
	return current_shards >= max_shards

func on_all_shards_collected():
	"""Вызывается когда все осколки собраны"""
	print("🔮 ВСЕ ОСКОЛКИ СОБРАНЫ! Квест выполнен!")
	
	# Эффект завершения
	show_completion_effect()

func show_completion_effect():
	"""Показывает эффект завершения сбора"""
	if crystal_sprite:
		# Анимация мигания
		var tween = create_tween()
		tween.set_loops(3)
		tween.tween_property(crystal_sprite, "modulate", Color.GOLD, 0.3)
		tween.tween_property(crystal_sprite, "modulate", Color.WHITE, 0.3)

func setup_game_state_connection():
	"""Подключается к GameStateManager для автоматического обновления"""
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		# Используем таймер для периодической проверки
		var timer = Timer.new()
		timer.wait_time = 0.5  # Проверяем каждые 0.5 секунды
		timer.timeout.connect(_check_game_state_update)
		timer.autostart = true
		add_child(timer)
		print("🔄 Подключен к обновлениям GameStateManager")

func _check_game_state_update():
	"""Проверяет обновления в GameStateManager"""
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		var new_shards = game_state.get_collected_crystals()
		if new_shards != current_shards:
			print("🔄 Обновление кристаллов: ", current_shards, " -> ", new_shards)
			current_shards = new_shards
			update_display()

func reset_counter():
	"""Сбрасывает счетчик"""
	current_shards = 0
	update_display()
	print("Счетчик осколков сброшен")