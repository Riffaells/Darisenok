extends Node
class_name SpawnManager

# Менеджер всех спавн-поинтов на карте

var spawn_points: Array[EnemySpawnPoint] = []

func _ready():
	# Находим все спавн-поинты на сцене
	find_all_spawn_points()
	
	# print("Найдено спавн-поинтов: ", spawn_points.size())

func find_all_spawn_points():
	"""Находит все спавн-поинты на сцене"""
	spawn_points.clear()
	
	# Ищем по группе
	var points = get_tree().get_nodes_in_group("spawn_points")
	for point in points:
		if point is EnemySpawnPoint:
			spawn_points.append(point)
	
	# Если не нашли по группе, ищем по типу
	if spawn_points.size() == 0:
		_find_spawn_points_recursive(get_tree().current_scene)

func _find_spawn_points_recursive(node: Node):
	"""Рекурсивно ищет спавн-поинты"""
	if node is EnemySpawnPoint:
		spawn_points.append(node)
	
	for child in node.get_children():
		_find_spawn_points_recursive(child)

func spawn_all():
	"""Заставляет все спавн-поинты заспавнить врагов"""
	for point in spawn_points:
		point.force_spawn()
	print("Принудительный спавн на всех точках")

func clear_all():
	"""Очищает всех врагов со всех спавн-поинтов"""
	for point in spawn_points:
		point.clear_spawned_enemies()
	# print("Очищены все спавн-поинты")

func get_spawn_point_by_index(index: int) -> EnemySpawnPoint:
	"""Возвращает спавн-поинт по индексу"""
	if index >= 0 and index < spawn_points.size():
		return spawn_points[index]
	return null

func spawn_at_point(index: int):
	"""Спавнит врага на конкретном спавн-поинте"""
	var point = get_spawn_point_by_index(index)
	if point:
		return point.force_spawn()
	return null

func get_total_enemies() -> int:
	"""Возвращает общее количество врагов от всех спавн-поинтов"""
	var total = 0
	for point in spawn_points:
		total += point.spawned_enemies.size()
	return total

func set_all_respawn_time(time: float):
	"""Устанавливает время респавна для всех точек"""
	for point in spawn_points:
		point.respawn_time = time

func disable_all_respawn():
	"""Отключает респавн на всех точках"""
	set_all_respawn_time(0)

func enable_all_respawn(time: float = 10.0):
	"""Включает респавн на всех точках"""
	set_all_respawn_time(time)