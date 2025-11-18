extends Node
class_name EnemySpawner

# ПРОСТОЙ спавнер врагов

# Сцены врагов
const OrcWarriorScene = preload("res://scenes/enemy/orc_warrior.tscn")
const ZombieDinoScene = preload("res://scenes/enemy/zombie_dino.tscn")

func spawn_orc_warrior(position: Vector2, parent: Node = null) -> BaseEnemy:
	"""Спавнит орка-воина"""
	return spawn_enemy(OrcWarriorScene, position, parent)

func spawn_zombie_dino(position: Vector2, parent: Node = null) -> BaseEnemy:
	"""Спавнит зомби-дино"""
	return spawn_enemy(ZombieDinoScene, position, parent)

func spawn_orc(position: Vector2, parent: Node = null) -> BaseEnemy:
	"""Спавнит орка (алиас)"""
	return spawn_orc_warrior(position, parent)

func spawn_zombie(position: Vector2, parent: Node = null) -> BaseEnemy:
	"""Спавнит зомби (алиас)"""
	return spawn_zombie_dino(position, parent)

func spawn_enemy(scene: PackedScene, position: Vector2, parent: Node = null) -> BaseEnemy:
	"""Спавнит врага из сцены"""
	var enemy = scene.instantiate() as BaseEnemy
	if not enemy:
		print("ОШИБКА: Сцена не содержит BaseEnemy!")
		return null
	
	enemy.global_position = position
	
	# ИСПРАВЛЕНИЕ: используем call_deferred для избежания ошибки
	if parent:
		parent.call_deferred("add_child", enemy)
	else:
		get_tree().current_scene.call_deferred("add_child", enemy)
	
	# print("Заспавнен ", enemy.enemy_name, " в позиции ", position)
	return enemy

func spawn_custom_orc(position: Vector2, health: float, damage: float, speed: float, parent: Node = null) -> BaseEnemy:
	"""Спавнит кастомного орка"""
	var orc = spawn_orc(position, parent)
	if orc:
		orc.max_health = health
		orc.current_health = health
		orc.damage = damage
		orc.move_speed = speed
		orc.update_ui()
	return orc

func spawn_custom_zombie(position: Vector2, health: float, damage: float, speed: float, parent: Node = null) -> BaseEnemy:
	"""Спавнит кастомного зомби"""
	var zombie = spawn_zombie(position, parent)
	if zombie:
		zombie.max_health = health
		zombie.current_health = health
		zombie.damage = damage
		zombie.move_speed = speed
		zombie.update_ui()
	return zombie

func clear_all_enemies():
	"""Удаляет всех врагов"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	print("Удалены все враги: ", enemies.size())

func spawn_random(position: Vector2, parent: Node = null) -> BaseEnemy:
	"""Спавнит случайного врага"""
	if randf() > 0.5:
		return spawn_orc_warrior(position, parent)
	else:
		return spawn_zombie_dino(position, parent)

func spawn_group(group_name: String, center_pos: Vector2, parent: Node = null, spread: float = 60.0) -> Array:
	"""Спавнит группу врагов"""
	var groups = {
		"patrol": ["orc_warrior", "zombie_dino"],
		"orc_squad": ["orc_warrior", "orc_warrior"],
		"zombie_horde": ["zombie_dino", "zombie_dino", "zombie_dino"],
		"mixed_force": ["orc_warrior", "zombie_dino", "zombie_dino"]
	}
	
	if not groups.has(group_name):
		print("Неизвестная группа: ", group_name)
		return []
	
	var enemies_list = groups[group_name]
	var spawned_enemies = []
	
	for i in range(enemies_list.size()):
		var angle = (2.0 * PI * i) / enemies_list.size()
		var offset = Vector2(cos(angle), sin(angle)) * spread
		var pos = center_pos + offset
		
		var enemy = null
		match enemies_list[i]:
			"orc_warrior":
				enemy = spawn_orc_warrior(pos, parent)
			"zombie_dino":
				enemy = spawn_zombie_dino(pos, parent)
		
		if enemy:
			spawned_enemies.append(enemy)
	
	# print("Заспавнена группа '", group_name, "': ", spawned_enemies.size(), " врагов")
	return spawned_enemies

func spawn_random_enemies(count: int, center_pos: Vector2, spread: float, parent: Node = null) -> Array:
	"""Спавнит случайных врагов в радиусе"""
	var spawned = []
	for i in range(count):
		var angle = randf() * 2.0 * PI
		var distance = randf() * spread
		var pos = center_pos + Vector2(cos(angle), sin(angle)) * distance
		var enemy = spawn_random(pos, parent)
		if enemy:
			spawned.append(enemy)
	return spawned

func get_available_groups() -> Array:
	"""Возвращает доступные группы врагов"""
	return ["patrol", "orc_squad", "zombie_horde", "mixed_force"]

func get_enemy_count() -> int:
	"""Возвращает количество врагов"""
	return get_tree().get_nodes_in_group("enemies").size()
