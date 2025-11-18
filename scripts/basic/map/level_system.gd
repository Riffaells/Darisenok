extends Node
class_name LevelSystem

# Система управления уровнями/картами

signal level_changed(level_name: String)

# Данные об уровнях
var levels_data = {
	"forest": {
		"name": "Лес",
		"scene_path": "res://scenes/levels/forest_level.tscn",
		"spawn_point": Vector2(0, 0),
		"enemies": ["orc_patrol", "orc_warband"],
		"description": "Тёмный лес, кишащий орками"
	},
	"village": {
		"name": "Деревня",
		"scene_path": "res://scenes/levels/village_level.tscn", 
		"spawn_point": Vector2(100, 100),
		"enemies": ["orc_raiders"],
		"description": "Разрушенная деревня"
	},
	"cave": {
		"name": "Пещера",
		"scene_path": "res://scenes/levels/cave_level.tscn",
		"spawn_point": Vector2(50, 50),
		"enemies": ["orc_defenders", "orc_boss_fight"],
		"description": "Глубокая пещера с сокровищами"
	}
}

var current_level: String = ""
var current_level_node: Node = null

func load_level(level_id: String):
	"""Загружает указанный уровень"""
	if not levels_data.has(level_id):
		print("Уровень не найден: ", level_id)
		return false
	
	var level_data = levels_data[level_id]
	
	# Выгружаем текущий уровень
	if current_level_node:
		current_level_node.queue_free()
		current_level_node = null
	
	# Загружаем новый уровень
	var level_scene = load(level_data.scene_path)
	if not level_scene:
		print("Не удалось загрузить сцену уровня: ", level_data.scene_path)
		return false
	
	current_level_node = level_scene.instantiate()
	get_tree().current_scene.add_child(current_level_node)
	
	# Перемещаем игрока на точку спавна
	var player = get_tree().root.find_child("player", true, false)
	if player:
		player.global_position = level_data.spawn_point
	
	current_level = level_id
	level_changed.emit(level_id)
	
	print("Загружен уровень: ", level_data.name)
	return true

func get_current_level_info() -> Dictionary:
	"""Возвращает информацию о текущем уровне"""
	if current_level != "" and levels_data.has(current_level):
		return levels_data[current_level]
	return {}

func get_available_levels() -> Array:
	"""Возвращает список доступных уровней"""
	return levels_data.keys()

func create_simple_level(level_id: String, level_name: String, spawn_point: Vector2 = Vector2.ZERO):
	"""Создаёт простой уровень программно (без сцены)"""
	# Создаём базовый узел уровня
	var level_node = Node2D.new()
	level_node.name = level_name
	
	# Добавляем менеджер уровня
	var level_manager = preload("res://scripts/basic/map/level_manager.gd").new()
	level_node.add_child(level_manager)
	
	# Выгружаем текущий уровень
	if current_level_node:
		current_level_node.queue_free()
		current_level_node = null
	
	# Устанавливаем новый уровень
	current_level_node = level_node
	get_tree().current_scene.add_child(current_level_node)
	
	# Перемещаем игрока
	var player = get_tree().root.find_child("player", true, false)
	if player:
		player.global_position = spawn_point
	
	current_level = level_id
	level_changed.emit(level_id)
	
	print("Создан простой уровень: ", level_name)

# Быстрые методы для создания уровней
func create_forest_level():
	create_simple_level("forest", "Лес", Vector2(0, 0))

func create_village_level():
	create_simple_level("village", "Деревня", Vector2(100, 100))

func create_cave_level():
	create_simple_level("cave", "Пещера", Vector2(50, 50))