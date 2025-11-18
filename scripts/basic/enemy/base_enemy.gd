extends CharacterBody2D
class_name BaseEnemy

# ПРОСТОЙ базовый класс врага - только основное

# Основные параметры (настраиваются в сцене)
@export var max_health: float = 50.0
@export var damage: float = 15.0
@export var move_speed: float = 30.0 # Медленные враги
@export var attack_range: float = 25.0 # Меньший радиус атаки
@export var detection_range: float = 80.0 # Меньший радиус обнаружения
@export var attack_cooldown: float = 3.0 # Долгий кулдаун атаки
@export var enemy_name: String = "Враг"

# Внутренние переменные
var current_health: float
var player: CharacterBody2D = null
var attack_timer: float = 0.0
var is_dead: bool = false
var stun_timer: float = 0.0 # Таймер оглушения
var attack_windup_timer: float = 0.0 # Время замаха перед атакой
var is_winding_up: bool = false # Замахивается ли враг

# Система предотвращения застревания
var last_position: Vector2
var stuck_timer: float = 0.0
var stuck_threshold: float = 2.0  # Секунды без движения = застрял
var unstuck_force: float = 100.0

# Компоненты (автоматически находятся)
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var collision: CollisionShape2D = $Collision
@onready var health_bar: ProgressBar = $HealthBar if has_node("HealthBar") else null
@onready var health_text: Label = $HealthText if has_node("HealthText") else null
@onready var name_label: Label = $NameLabel if has_node("NameLabel") else null

func _ready():
	# Простая инициализация
	current_health = max_health
	attack_timer = attack_cooldown
	
	# Настройка коллизий
	collision_layer = 4 # Враги
	collision_mask = 1 + 2 + 4 # Мир + Игрок + Враги (стены, игрок, другие враги)
	
	# Поиск игрока
	find_player()
	
	# Добавляем в группу
	add_to_group("enemies")
	
	# Обновляем UI
	update_ui()
	
	# Подключаем сигналы мыши если есть MouseArea
	var mouse_area = get_node_or_null("MouseArea")
	if mouse_area:
		mouse_area.mouse_entered.connect(_on_mouse_entered)
		mouse_area.mouse_exited.connect(_on_mouse_exited)

func find_player():
	"""Находит игрока"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		player = get_tree().root.find_child("player", true, false)

func _physics_process(delta):
	if is_dead or not player:
		return
	
	# Обновляем таймеры
	attack_timer -= delta
	stun_timer -= delta
	attack_windup_timer -= delta
	
	# Если оглушен - не можем действовать
	if stun_timer > 0:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 3)
		update_animation("idle")
		move_and_slide()
		handle_enemy_collisions()
		return
	
	# Простая логика поведения
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= attack_range:
		# МЕДЛЕННАЯ АТАКА С ЗАМАХОМ - игрок может убежать
		velocity = Vector2.ZERO
		
		if not is_winding_up and attack_timer <= 0:
			# Начинаем замах
			is_winding_up = true
			attack_windup_timer = 1 # 1 секунды замаха - игрок может убежать!
			update_animation("attack")
			print(enemy_name, " замахивается для атаки!")
		
		elif is_winding_up:
			# Замахиваемся
			if attack_windup_timer <= 0:
				# Выполняем атаку
				simple_attack()
				attack_timer = attack_cooldown
				is_winding_up = false
			else:
				# Продолжаем замах - игрок может убежать
				update_animation("attack")
			
	elif distance <= detection_range:
		# УМНОЕ ПРЕСЛЕДОВАНИЕ
		var direction = (player.global_position - global_position).normalized()
		
		# Простое преследование без проверки пути
		velocity = direction * move_speed
		update_animation("walk")
		
		is_winding_up = false # Сбрасываем замах если игрок убежал
	else:
		# Стоим
		velocity = Vector2.ZERO
		update_animation("idle")
		is_winding_up = false # Сбрасываем замах если игрок далеко
	
	# Двигаемся
	move_and_slide()
	
	# Убрали проверку застревания
	
	# Обрабатываем столкновения с другими врагами
	handle_enemy_collisions()
	
	# Поворачиваем спрайт
	if velocity.x != 0 and sprite:
		sprite.flip_h = velocity.x < 0

# Убрали сложные функции - теперь простая механика боя

func simple_attack():
	"""Простая атака - почти всегда попадает"""
	if not player or not player.has_method("take_damage"):
		return
	
	# Проверяем расстояние
	var distance = global_position.distance_to(player.global_position)
	if distance > attack_range:
		print(enemy_name, " промахнулся - игрок убежал!")
		show_miss_effect()
		return
	
	# УЛУЧШЕННЫЕ ВРАГИ: более точные и опасные
	var player_speed = 0.0
	if "velocity" in player:
		player_speed = player.velocity.length()
	
	# Базовый шанс попадания 90%
	var hit_chance = 0.9
	
	# Если игрок движется быстро - немного снижаем точность
	if player_speed > 100:
		hit_chance -= 0.2  # До 50% при быстром движении
	elif player_speed > 50:
		hit_chance -= 0.1  # До 60% при среднем движении
	
	if randf() < hit_chance:
		# Попадание!
		print(enemy_name, " попал по игроку! Урон: ", damage)
		player.take_damage(damage)
		show_hit_effect()
	else:
		print(enemy_name, " промахнулся! (шанс попадания был: ", int(hit_chance * 100), "%)")
		show_miss_effect()

func show_miss_effect():
	"""Показывает эффект промаха"""
	if sprite:
		# Эффект промаха - быстрое мигание
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 0.5), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func show_hit_effect():
	"""Показывает эффект попадания"""
	if sprite:
		# Убираем scale эффект - только цвет
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func attack_player():
	"""Старая функция атаки - теперь вызывает простую атаку"""
	simple_attack()

func take_damage(amount: float):
	"""Получает урон"""
	if is_dead:
		return
	
	current_health -= amount
	
	# Не даем здоровью опускаться ниже нуля
	if current_health < 0:
		current_health = 0
	
	print(enemy_name, " получил ", amount, " урона. Здоровье: ", current_health)
	
	# ДЛИТЕЛЬНОЕ ОГЛУШЕНИЕ при получении урона - игроку легче сражаться
	attack_timer = attack_cooldown * 2.0 # Двойная задержка перед следующей атакой
	stun_timer = 1.0 # Дополнительное оглушение на 1 секунду
	
	# Обновляем UI
	update_ui()
	
	# Эффект урона
	if sprite:
		sprite.modulate = Color.YELLOW
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	# Проверяем смерть
	if current_health <= 0:
		die()

func die():
	"""Смерть врага"""
	if is_dead:
		return
	
	is_dead = true
	print(enemy_name, " погиб!")
	
	# Отключаем коллизию
	if collision:
		collision.disabled = true
	
	# Быстрая анимация смерти без scale
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)  # Быстрее: 0.3 вместо 1.0
		tween.tween_callback(queue_free)

func update_ui():
	"""Обновляет UI"""
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	if health_text:
		health_text.text = str(int(current_health)) + "/" + str(int(max_health))

func push_away(from_position: Vector2, force: float):
	"""Отталкивает врага"""
	var direction = (global_position - from_position).normalized()
	velocity += direction * force
	
	# Убираем scale эффект - только легкое мигание
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.8, 0.8, 0.8), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

# Функции для подсветки при наведении мыши
func _on_mouse_entered():
	"""Мышь наведена на врага"""
	if sprite and not is_dead:
		sprite.modulate = Color(1.2, 1.2, 1.2) # Легкая подсветка

func _on_mouse_exited():
	"""Мышь убрана с врага"""
	if sprite:
		sprite.modulate = Color.WHITE

func update_animation(anim_name: String):
	"""Обновляет анимацию врага"""
	if not sprite or not sprite.sprite_frames:
		return
	
	# Проверяем какие анимации доступны и выбираем подходящую
	var target_anim = ""
	
	match anim_name:
		"idle":
			if sprite.sprite_frames.has_animation("idle"):
				target_anim = "idle"
			elif sprite.sprite_frames.has_animation("default"):
				target_anim = "default"
		"walk":
			if sprite.sprite_frames.has_animation("walk"):
				target_anim = "walk"
			elif sprite.sprite_frames.has_animation("idle"):
				target_anim = "idle"
			elif sprite.sprite_frames.has_animation("default"):
				target_anim = "default"
		"attack":
			if sprite.sprite_frames.has_animation("attack"):
				target_anim = "attack"
			elif sprite.sprite_frames.has_animation("idle"):
				target_anim = "idle"
			elif sprite.sprite_frames.has_animation("default"):
				target_anim = "default"
	
	# Меняем анимацию только если нужно
	if target_anim != "" and sprite.animation != target_anim:
		sprite.animation = target_anim
		sprite.play()
func handle_enemy_collisions():
	"""Обрабатывает столкновения с другими врагами"""
	for i in get_slide_collision_count():
		var collision_info = get_slide_collision(i)
		var collider = collision_info.get_collider()
		
		# Если столкнулись с другим врагом
		if collider and collider.is_in_group("enemies") and collider != self:
			# Расталкиваемся
			var push_direction = (global_position - collider.global_position).normalized()
			var push_force = 30.0 # Сила расталкивания
			
			# Применяем силу к себе
			velocity += push_direction * push_force
			
			# Применяем силу к другому врагу (если у него есть такая функция)
			if collider.has_method("push_away"):
				collider.push_away(global_position, push_force * 0.5)

func stun(duration: float):
	"""Оглушает врага на указанное время"""
	stun_timer = duration
	print(enemy_name, " оглушен на ", duration, " сек!")
	
	# Визуальный эффект оглушения
	if sprite:
		sprite.modulate = Color(0.8, 0.8, 1.0) # Синеватый оттенок
		
		# Используем таймер вместо tween_delay
		get_tree().create_timer(duration).timeout.connect(func():
			if sprite and is_instance_valid(sprite):
				var tween = create_tween()
				tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
		)
# Убрали функцию check_if_stuck
