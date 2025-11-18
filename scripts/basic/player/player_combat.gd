extends Node
class_name PlayerCombat

# Система боя для игрока

@export var attack_damage: float = 25.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 0.5

var attack_timer: float = 0.0
var player: CharacterBody2D
var mouse_was_pressed = false

# Сигналы
signal player_attacked(attack_position: Vector2, attack_range: float, attack_damage: float)

func _ready():
	player = get_parent() as CharacterBody2D

func get_global_mouse_position() -> Vector2:
	"""Получает позицию мыши в мировых координатах"""
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d()
	
	if camera:
		return camera.get_global_mouse_position()
	else:
		# Если нет камеры, используем простое преобразование
		return viewport.get_mouse_position()

func _process(delta):
	attack_timer -= delta
	
	# Убрали атаку по пробелу - теперь только мышь
	
	# Проверяем ЛКМ
	var mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if mouse_pressed and not mouse_was_pressed:
		# ВАЖНО: Не перехватываем клики по UI элементам!
		var mouse_pos = get_global_mouse_position()
		var ui_elements = get_tree().get_nodes_in_group("ui_elements")
		var clicked_ui = false
		
		# Проверяем амулет (используем viewport координаты для UI)
		var viewport = get_viewport()
		var viewport_mouse_pos = viewport.get_mouse_position()
		
		var amulet = get_tree().get_first_node_in_group("amulet_character")
		if amulet and amulet.visible and amulet.is_clickable:
			var amulet_rect = amulet.get_global_rect()
			
			if amulet_rect.has_point(viewport_mouse_pos):
				clicked_ui = true
				amulet.use_amulet()
		
		if not clicked_ui:
			# Проверяем клик по врагу
			var clicked_enemy = get_enemy_at_mouse_position()
			if clicked_enemy:
				attack_specific_enemy(clicked_enemy)
			else:
				attack()  # Обычная атака по радиусу
	
	mouse_was_pressed = mouse_pressed

func get_enemy_at_mouse_position() -> BaseEnemy:
	"""Находит врага под курсором мыши"""
	var mouse_pos = get_global_mouse_position()
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	var closest_enemy: BaseEnemy = null
	var closest_distance = 80.0  # Увеличиваем радиус клика
	
	for enemy in enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		# ВАЖНО: Проверяем что это не сам игрок!
		if enemy == player or enemy.is_in_group("player"):
			continue
		
		if enemy.has_method("get") and enemy.get("is_dead"):
			continue
		
		# Проверяем попадание в область врага
		var distance = mouse_pos.distance_to(enemy.global_position)
		# print("Враг ", enemy.enemy_name, " на расстоянии: ", distance)
		
		if distance <= closest_distance:
			closest_enemy = enemy as BaseEnemy
			closest_distance = distance
	
	return closest_enemy

func attack_specific_enemy(target_enemy: BaseEnemy):
	"""Атакует конкретного врага"""
	if attack_timer > 0:
		return
	
	var distance = player.global_position.distance_to(target_enemy.global_position)
	if distance > attack_range:
		return
	
	attack_timer = attack_cooldown
	
	
	# Атакуем выбранного врага
	target_enemy.take_damage(attack_damage)
	target_enemy.push_away(player.global_position, 100)
	
	# Визуальный эффект
	show_attack_effect()
	
	# Сигнал
	player_attacked.emit(player.global_position, attack_range, attack_damage)

func attack():
	"""Выполняет мощную атаку по области"""
	if attack_timer > 0:
		return  # Еще не готов к атаке
	
	attack_timer = attack_cooldown
	
	
	# Находим всех врагов в радиусе
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_enemies = []
	
	for enemy in enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		# ВАЖНО: Проверяем что это не сам игрок!
		if enemy == player or enemy.is_in_group("player"):
			continue
		
		# Проверяем что враг жив
		if enemy.has_method("get") and enemy.get("is_dead"):
			continue
		
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance <= attack_range:
			hit_enemies.append(enemy)
	
	# Атакуем всех найденных врагов
	for enemy in hit_enemies:
		# Наносим урон
		if enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage)
		
		# МОЩНОЕ отбрасывание - игрок сильный!
		if enemy.has_method("push_away"):
			var distance = player.global_position.distance_to(enemy.global_position)
			var push_force = 200 - (distance * 2)  # Чем ближе, тем сильнее отбрасывание
			push_force = max(push_force, 100)  # Минимум 100
			enemy.push_away(player.global_position, push_force)
		
		# Дополнительный эффект оглушения
		if enemy.has_method("stun"):
			enemy.stun(0.5)  # Оглушение на полсекунды
	
		# Убираем тряску экрана - она надоедли
	
	# Визуальный эффект атаки
	show_attack_effect()
	
	# Испускаем сигнал атаки
	player_attacked.emit(player.global_position, attack_range, attack_damage)

func show_attack_effect():
	"""Показывает анимацию атаки игрока"""
	# Теперь используем спрайт attack вместо желтого круга
	var sprite = player.get_node_or_null("%sprite")
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("attack"):
			sprite.animation = "attack"
			sprite.play()
			
			# Возвращаемся к idle через время
			await sprite.animation_finished
			if sprite.sprite_frames.has_animation("idle"):
				sprite.animation = "idle"
			else:
				sprite.animation = "wait"
			sprite.play()

# Убрали функцию тряски экрана
