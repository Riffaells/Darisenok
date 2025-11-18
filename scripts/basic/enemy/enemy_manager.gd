extends Node
class_name EnemyManager

# Менеджер для управления всеми врагами в игре

var enemy_data: Dictionary = {}
var enemy_groups: Dictionary = {}

func _ready():
	load_enemy_data()

func load_enemy_data():
	"""Загружает данные врагов из JSON файла"""
	var file = FileAccess.open("res://data/enemy_data.json", FileAccess.READ)
	if not file:
		print("Не удалось загрузить enemy_data.json")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("Ошибка парсинга enemy_data.json")
		return
	
	var data = json.data
	enemy_data = data.get("enemy_types", {})
	enemy_groups = data.get("enemy_groups", {})
	
	print("Загружено типов врагов: ", enemy_data.size())
	print("Загружено групп врагов: ", enemy_groups.size())

func get_enemy_info(enemy_type: String) -> Dictionary:
	"""Возвращает информацию о типе врага"""
	return enemy_data.get(enemy_type, {})

func get_group_info(group_name: String) -> Dictionary:
	"""Возвращает информацию о группе врагов"""
	return enemy_groups.get(group_name, {})

func get_all_enemy_types() -> Array:
	"""Возвращает список всех типов врагов"""
	return enemy_data.keys()

func get_all_groups() -> Array:
	"""Возвращает список всех групп врагов"""
	return enemy_groups.keys()

func spawn_enemy(enemy_type: String, position: Vector2, parent: Node) -> Node:
	"""Спавнит врага указанного типа"""
	var info = get_enemy_info(enemy_type)
	if info.is_empty():
		print("Неизвестный тип врага: ", enemy_type)
		return null
	
	var scene_path = info.get("scene_path", "")
	if scene_path == "":
		print("Не указан путь к сцене для врага: ", enemy_type)
		return null
	
	var enemy_scene = load(scene_path)
	if not enemy_scene:
		print("Не удалось загрузить сцену: ", scene_path)
		return null
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	
	# Применяем параметры из JSON
	enemy.enemy_name = info.get("name", "Враг")
	enemy.max_health = info.get("health", 50)
	enemy.current_health = enemy.max_health
	enemy.damage = info.get("damage", 10)
	enemy.walk_speed = info.get("walk_speed", 50)
	enemy.attack_speed = info.get("attack_speed", 1.5)
	enemy.attack_radius = info.get("attack_radius", 30)
	enemy.detection_range = info.get("detection_range", 100)
	
	# Обновляем UI
	if enemy.has_method("update_health_display"):
		enemy.update_health_display()
	
	if enemy.has_method("set_enemy_name"):
		enemy.set_enemy_name(enemy.enemy_name)
	
	# Применяем цвет если указан
	var color = info.get("sprite_color", [1.0, 1.0, 1.0, 1.0])
	if enemy.sprite:
		enemy.sprite.modulate = Color(color[0], color[1], color[2], color[3])
	
	parent.add_child(enemy)
	# print("Заспавнен ", enemy.enemy_name, " в позиции: ", position)
	return enemy

func spawn_group(group_name: String, center_position: Vector2, parent: Node, spread: float = 60.0) -> Array:
	"""Спавнит группу врагов"""
	var group_info = get_group_info(group_name)
	if group_info.is_empty():
		print("Неизвестная группа: ", group_name)
		return []
	
	var enemies_list = group_info.get("enemies", [])
	var formation = group_info.get("formation", "circle")
	
	var spawned_enemies = []
	var positions = generate_formation_positions(center_position, enemies_list.size(), spread, formation)
	
	for i in range(enemies_list.size()):
		var enemy_type = enemies_list[i]
		var pos = positions[i] if i < positions.size() else center_position
		var enemy = spawn_enemy(enemy_type, pos, parent)
		if enemy:
			spawned_enemies.append(enemy)
	
	# print("Заспавнена группа '", group_name, "': ", spawned_enemies.size(), " врагов")
	return spawned_enemies

func generate_formation_positions(center: Vector2, count: int, spread: float, formation: String) -> Array:
	"""Генерирует позиции для формации"""
	var positions = []
	
	match formation:
		"line":
			for i in range(count):
				var offset = Vector2((i - count/2.0) * spread, 0)
				positions.append(center + offset)
		
		"circle":
			for i in range(count):
				var angle = (2.0 * PI * i) / count
				var offset = Vector2(cos(angle), sin(angle)) * spread
				positions.append(center + offset)
		
		"square":
			var side = ceil(sqrt(count))
			for i in range(count):
				var x = i % side
				var y = i / side
				var offset = Vector2((x - side/2.0) * spread, (y - side/2.0) * spread)
				positions.append(center + offset)
		
		_:
			# По умолчанию - круг
			for i in range(count):
				var angle = (2.0 * PI * i) / count
				var offset = Vector2(cos(angle), sin(angle)) * spread
				positions.append(center + offset)
	
	return positions

func create_custom_enemy(enemy_type: String, custom_stats: Dictionary) -> Dictionary:
	"""Создает кастомного врага на основе существующего типа"""
	var base_info = get_enemy_info(enemy_type)
	if base_info.is_empty():
		return {}
	
	var custom_info = base_info.duplicate()
	
	# Применяем кастомные параметры
	for key in custom_stats:
		custom_info[key] = custom_stats[key]
	
	return custom_info

func spawn_custom_enemy(base_type: String, custom_stats: Dictionary, position: Vector2, parent: Node) -> Node:
	"""Спавнит кастомного врага"""
	var custom_info = create_custom_enemy(base_type, custom_stats)
	if custom_info.is_empty():
		return null
	
	# Временно сохраняем кастомную информацию
	var original_info = enemy_data.get(base_type, {})
	enemy_data[base_type + "_custom"] = custom_info
	
	var enemy = spawn_enemy(base_type + "_custom", position, parent)
	
	# Удаляем временную информацию
	enemy_data.erase(base_type + "_custom")
	
	return enemy
