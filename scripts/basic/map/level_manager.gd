extends Node2D

@onready var tile_map_layer = $TileMapLayer

# Импорт классов (убираем конфликт имен)

# Функция для изменения области карты
func change_map_area(start_pos: Vector2i, end_pos: Vector2i, source_id: int, atlas_coords: Vector2i):
	"""
	Изменяет прямоугольную область карты
	start_pos: начальная позиция (левый верхний угол)
	end_pos: конечная позиция (правый нижний угол)
	source_id: ID источника тайлов (0, 1, 2...)
	atlas_coords: координаты тайла в атласе
	"""
	for x in range(start_pos.x, end_pos.x + 1):
		for y in range(start_pos.y, end_pos.y + 1):
			tile_map_layer.set_cell(Vector2i(x, y), source_id, atlas_coords)

# Функция для создания моста
func create_bridge(pos: Vector2i, length: int, direction: Vector2i):
	"""
	Создаёт мост в указанном направлении
	pos: начальная позиция
	length: длина моста
	direction: направление (Vector2i(1,0) для горизонтального)
	"""
	for i in range(length):
		var bridge_pos = pos + direction * i
		# Используем каменные тайлы для моста (source_id = 0, terrain = 3)
		tile_map_layer.set_cell(bridge_pos, 0, Vector2i(1, 4)) # Каменный тайл

# Функция для разрушения стены
func destroy_wall(center_pos: Vector2i, radius: int):
	"""
	Разрушает стену в радиусе от центра
	"""
	for x in range(center_pos.x - radius, center_pos.x + radius + 1):
		for y in range(center_pos.y - radius, center_pos.y + radius + 1):
			var distance = center_pos.distance_to(Vector2i(x, y))
			if distance <= radius:
				# Заменяем на траву
				tile_map_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))

# Функция для создания дыры/ямы
func create_hole(center_pos: Vector2i, radius: int):
	"""
	Создаёт дыру (убирает тайлы)
	"""
	for x in range(center_pos.x - radius, center_pos.x + radius + 1):
		for y in range(center_pos.y - radius, center_pos.y + radius + 1):
			var distance = center_pos.distance_to(Vector2i(x, y))
			if distance <= radius:
				# Убираем тайл (делаем пустым)
				tile_map_layer.erase_cell(Vector2i(x, y))

# Пример использования - вызывается по событию
func _on_event_triggered():
	# Создаём мост через реку
	create_bridge(Vector2i(10, 5), 5, Vector2i(1, 0))

	# Разрушаем стену
	destroy_wall(Vector2i(20, 10), 2)

	# Создаём дыру от взрыва
	create_hole(Vector2i(15, 15), 3)
# Система спавна врагов
const EnemySpawnerScript = preload("res://scripts/basic/enemy/enemy_spawner.gd")
var spawner: EnemySpawnerScript

func _ready():
	# Сбрасываем состояние кристаллов при начале уровня
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		game_state.start_new_level()
	
	# Создаём спавнер
	spawner = EnemySpawnerScript.new()
	add_child(spawner)
	
	# Демонстрация разных способов спавна (с задержкой)
	call_deferred("demo_enemy_spawning")
	
	# Магические камни теперь добавляются вручную перетаскиванием сцены

func demo_enemy_spawning():
	"""Демонстрирует разные способы спавна орков"""
	
	# Убрали программный спавн врагов - теперь только через spawn points на карте
	print("=== Доступные группы орков ===")
	for group_name in spawner.get_available_groups():
		print("- ", group_name)

## Простые методы для использования в других местах

func spawn_enemy_simple(type_name: String, pos: Vector2):
	"""Простой метод для спавна орка по имени типа"""
	match type_name.to_lower():
		"warrior", "воин", "орк-воин", "орк":
			spawner.spawn_orc_warrior(pos, self)
		"zombie", "зомби", "дино", "зомби-дино":
			spawner.spawn_zombie_dino(pos, self)
		"random", "случайный":
			spawner.spawn_random(pos, self)
		_:
			print("Неизвестный тип орка: ", type_name)

func spawn_enemy_group_simple(group_name: String, center_pos: Vector2):
	"""Простой метод для спавна группы врагов"""
	# Проверяем что группа существует
	var available_groups = spawner.get_available_groups()
	if group_name in available_groups:
		spawner.spawn_group(group_name, center_pos, self)
	else:
		print("Группа не найдена: ", group_name, ". Доступные: ", available_groups)
		spawner.spawn_group("patrol", center_pos, self)  # По умолчанию

func spawn_wave(wave_number: int, center_pos: Vector2):
	"""Спавнит волну орков в зависимости от номера волны"""
	match wave_number:
		1:
			spawner.spawn_group("patrol", center_pos, self)
		2:
			spawner.spawn_group("orc_squad", center_pos, self)
		3:
			spawner.spawn_group("zombie_horde", center_pos, self)
		4:
			spawner.spawn_group("mixed_force", center_pos, self)
		5:
			spawner.spawn_group("mixed_force", center_pos, self)
		_:
			# Для больших волн - случайные орки
			var enemy_count = min(wave_number, 8)
			spawner.spawn_random_enemies(enemy_count, center_pos, 150, self)

# Магические камни добавляются перетаскиванием сцены scenes/objects/magic_stone.tscn на карту
