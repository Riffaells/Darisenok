extends Node2D
class_name EnemySpawnPoint

# Точка спавна врагов на карте

@export_enum("orc_warrior", "zombie_dino", "random") var enemy_type: String = "orc_warrior"
@export var auto_spawn: bool = true  # Спавнить автоматически при старте
@export var respawn_time: float = 10.0  # Время респавна в секундах
@export var max_spawns: int = 1  # Максимум врагов от этой точки

# Кастомные параметры врага (если нужно)
@export var custom_health: float = 0  # 0 = использовать стандартное
@export var custom_damage: float = 0
@export var custom_speed: float = 0

# Параметры разброса
@export var spawn_radius: float = 30.0  # Радиус разброса спавна
@export var speed_variation: float = 15.0  # Вариация скорости (+-15)

var spawner: EnemySpawner
var spawned_enemies: Array = []
var respawn_timer: float = 0.0

func _ready():
	# Создаем спавнер
	spawner = EnemySpawner.new()
	add_child(spawner)
	
	# Автоспавн при старте (мгновенно)
	if auto_spawn:
		# Спавним сразу столько врагов, сколько указано в max_spawns
		for i in range(max_spawns):
			await get_tree().process_frame  # Небольшая задержка между спавнами
			spawn_enemy()

func _process(delta):
	# Обновляем таймер респавна
	if respawn_timer > 0:
		respawn_timer -= delta
		if respawn_timer <= 0:
			check_respawn()
	
	# Очищаем список от мертвых врагов
	clean_enemy_list()

func spawn_enemy():
	"""Спавнит врага в этой точке с разбросом позиции"""
	if spawned_enemies.size() >= max_spawns:
		return null
	
	# Генерируем случайную позицию в радиусе
	var spawn_pos = get_random_spawn_position()
	
	var enemy: BaseEnemy = null
	
	# Спавним по типу
	match enemy_type:
		"orc_warrior":
			enemy = spawner.spawn_orc_warrior(spawn_pos)
		"zombie_dino":
			enemy = spawner.spawn_zombie_dino(spawn_pos)
		"random":
			if randf() > 0.5:
				enemy = spawner.spawn_orc_warrior(spawn_pos)
			else:
				enemy = spawner.spawn_zombie_dino(spawn_pos)
	
	if enemy:
		# Применяем кастомные параметры + рандомную скорость
		apply_custom_stats(enemy)
		apply_random_speed(enemy)
		
		# Добавляем небольшое начальное отталкивание от других врагов
		apply_initial_separation(enemy)
		
		# Добавляем в список
		spawned_enemies.append(enemy)
		
		# Подключаемся к сигналу смерти
		enemy.connect("tree_exited", _on_enemy_died)
		
		# print("Спавн-поинт заспавнил ", enemy.enemy_name, " в позиции ", spawn_pos)
		return enemy
	
	return null

func apply_custom_stats(enemy: BaseEnemy):
	"""Применяет кастомные параметры к врагу"""
	if custom_health > 0:
		enemy.max_health = custom_health
		enemy.current_health = custom_health
	
	if custom_damage > 0:
		enemy.damage = custom_damage
	
	if custom_speed > 0:
		enemy.move_speed = custom_speed
	
	# Обновляем UI
	enemy.update_ui()

func _on_enemy_died():
	"""Вызывается когда враг умирает"""
	clean_enemy_list()
	
	# Запускаем таймер респавна
	if respawn_time > 0:
		respawn_timer = respawn_time
		# print("Спавн-поинт: респавн через ", respawn_time, " сек")

func check_respawn():
	"""Проверяет нужно ли респавнить"""
	if spawned_enemies.size() < max_spawns:
		spawn_enemy()

func clean_enemy_list():
	"""Очищает список от мертвых врагов"""
	var alive_enemies = []
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			alive_enemies.append(enemy)
	spawned_enemies = alive_enemies

func force_spawn():
	"""Принудительно спавнит врага (для вызова из кода)"""
	return spawn_enemy()

func clear_spawned_enemies():
	"""Удаляет всех заспавненных врагов"""
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()

# Визуализация ТОЛЬКО в редакторе
func _draw():
	if Engine.is_editor_hint():
		# Рисуем иконку спавн-поинта только в редакторе
		draw_circle(Vector2.ZERO, 10, Color.RED)
		draw_circle(Vector2.ZERO, 8, Color.YELLOW)
		
		# Подпись с типом врага
		var font = ThemeDB.fallback_font
		draw_string(font, Vector2(-20, -15), enemy_type, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		
		# Показываем радиус спавна
		draw_circle(Vector2.ZERO, spawn_radius, Color(0, 1, 0, 0.2))

func get_random_spawn_position() -> Vector2:
	"""Генерирует случайную позицию в радиусе спавна"""
	var angle = randf() * 2.0 * PI
	var distance = randf() * spawn_radius
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return global_position + offset

func apply_random_speed(enemy: BaseEnemy):
	"""Применяет случайную скорость к врагу"""
	var speed_modifier = randf_range(-speed_variation, speed_variation)
	enemy.move_speed += speed_modifier
	enemy.move_speed = max(enemy.move_speed, 10.0)  # Минимальная скорость

func apply_initial_separation(enemy: BaseEnemy):
	"""Применяет начальное отталкивание от других врагов"""
	# Находим других врагов поблизости
	var nearby_enemies = []
	for other_enemy in spawned_enemies:
		if other_enemy != enemy and is_instance_valid(other_enemy):
			var distance = enemy.global_position.distance_to(other_enemy.global_position)
			if distance < 40:  # Если слишком близко
				nearby_enemies.append(other_enemy)
	
	# Отталкиваем от каждого ближайшего врага
	for other_enemy in nearby_enemies:
		var push_force = 50.0
		
		# Применяем отталкивание к новому врагу
		if enemy.has_method("push_away"):
			enemy.push_away(other_enemy.global_position, push_force)
		
		# И небольшое отталкивание к старому
		if other_enemy.has_method("push_away"):
			other_enemy.push_away(enemy.global_position, push_force * 0.3)
