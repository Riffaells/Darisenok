extends CharacterBody2D

@export var movement_speed: float = 500
@export var run_speed_multiplier: float = 1.8
@export var acceleration: float = 2000
@export var friction: float = 1500
@export var energy_drain_rate: float = 15.0  # энергия в секунду при беге

var character_direction: Vector2
var speed_multiplier: float = 1.0
var is_running: bool = false
var can_move: bool = true  # Для диалогов
var is_walking: bool = false  # Для звука ходьбы
var was_running: bool = false  # Для отслеживания изменения состояния бега

@onready var ui_manager = get_tree().root.find_child("UIManager", true, false)
@onready var player_stats: PlayerStats = $PlayerStats
@onready var item_display: Sprite2D = $ItemDisplay
@onready var walk_sound: AudioStreamPlayer2D = $WalkSound
@onready var run_sound: AudioStreamPlayer2D = $RunSound

func _physics_process(delta):
	# Получаем направление движения
	character_direction = Vector2.ZERO

	# Проверяем, можем ли мы двигаться (инвентарь закрыт И нет диалога)
	var can_move_now = can_move and not (ui_manager and ui_manager.inventory.visible)

	if can_move_now:
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			character_direction.x -= 1
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
			character_direction.x += 1
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			character_direction.y -= 1
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			character_direction.y += 1

	character_direction = character_direction.normalized()
	
	# Проверяем бег (Ctrl + движение)
	var wants_to_run = Input.is_key_pressed(KEY_CTRL) and character_direction != Vector2.ZERO and can_move_now
	
	# Обновляем состояние бега
	if wants_to_run and player_stats and player_stats.current_energy > 0:
		if not is_running:
			is_running = true
			print("Начал бежать")
		# Тратим энергию на бег
		if player_stats.consume_energy_float(energy_drain_rate * delta):
			pass  # Энергия потрачена успешно
		else:
			# Энергия закончилась
			is_running = false
			print("Энергия закончилась, перехожу на ходьбу")
	else:
		if is_running:
			is_running = false
			print("Перестал бежать")

	# Плавное движение с ускорением и торможением
	var effective_speed = movement_speed * speed_multiplier
	if is_running:
		effective_speed *= run_speed_multiplier
	
	if character_direction != Vector2.ZERO:
		velocity = velocity.move_toward(character_direction * effective_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	# Flip спрайта
	if character_direction.x > 0:
		%sprite.flip_h = false
	elif character_direction.x < 0:
		%sprite.flip_h = true

	# Анимации с новыми спрайтами
	if velocity.length() > 10:  # Движение
		var target_anim = ""
		
		# Выбираем анимацию в зависимости от скорости
		if is_running:
			# Бег
			if %sprite.sprite_frames.has_animation("run"):
				target_anim = "run"
			elif %sprite.sprite_frames.has_animation("walk"):
				target_anim = "walk"
			elif %sprite.sprite_frames.has_animation("walking"):
				target_anim = "walking"
		else:
			# Обычная ходьба
			if %sprite.sprite_frames.has_animation("walk"):
				target_anim = "walk"
			elif %sprite.sprite_frames.has_animation("walking"):
				target_anim = "walking"
		
		# Применяем анимацию
		if target_anim != "" and %sprite.animation != target_anim:
			%sprite.animation = target_anim
			%sprite.play()
		
		# Звуки движения
		if not is_walking:
			is_walking = true
			update_movement_sounds()
		elif was_running != is_running:
			# Изменилось состояние бега - обновляем звуки
			update_movement_sounds()
		
		was_running = is_running
			
	else:  # Стоим
		var target_anim = ""
		
		# Проверяем какие анимации доступны для покоя
		if %sprite.sprite_frames.has_animation("idle"):
			target_anim = "idle"
		elif %sprite.sprite_frames.has_animation("wait"):
			target_anim = "wait"
		
		# Применяем анимацию
		if target_anim != "" and %sprite.animation != target_anim:
			%sprite.animation = target_anim
			%sprite.play()
		
		# Останавливаем звуки движения
		if is_walking:
			is_walking = false
			stop_all_movement_sounds()

	move_and_slide()
	
	# Визуальный эффект быстрого движения (высокий шанс уворота)
	update_dodge_effect()

# Методы для системы характеристик
func set_speed_multiplier(multiplier: float):
	speed_multiplier = multiplier

func heal(amount: int):
	if player_stats:
		player_stats.heal(amount)

func take_damage(amount: int):
	# print("🩸 ИГРОК ПОЛУЧАЕТ УРОН: ", amount)
	# print("🩸 Стек вызовов:")
	print(get_stack())
	
	# Временная защита от самоповреждения
	if amount <= 0:
		# print("⚠️ Игнорируем нулевой или отрицательный урон")
		return false
	
	if player_stats:
		return player_stats.take_damage(amount)
	return false

func restore_energy(amount: int):
	if player_stats:
		player_stats.restore_energy(amount)

func consume_energy(amount: int) -> bool:
	if player_stats:
		return player_stats.consume_energy(amount)
	return false

func get_mana() -> int:
	if player_stats:
		return player_stats.get_mana()
	return 0

func consume_mana(amount: int) -> bool:
	if player_stats:
		return player_stats.consume_mana(amount)
	return false

func apply_buff(buff_type: String, duration: float):
	if player_stats:
		player_stats.apply_buff(buff_type, duration)
func _ready():
	# Настройка коллизий
	collision_layer = 2  # Игрок
	collision_mask = 1 + 4  # Мир + Враги (стены и враги)
	
	# ОТЛАДКА: Проверяем группы игрока
	# print("🎮 ИГРОК СОЗДАН!")
	# print("   Группы игрока: ", get_groups())
	# print("   Позиция: ", global_position)
	
	# Убеждаемся что игрок НЕ в группе врагов
	if is_in_group("enemies"):
		# print("⚠️ КРИТИЧЕСКАЯ ОШИБКА: Игрок в группе врагов! Удаляем...")
		remove_from_group("enemies")
	
	# Подключаемся к сигналу изменения активного предмета
	if PlayerInventory:
		PlayerInventory.active_item_updated.connect(_on_active_item_changed)
	_update_item_display()

func _on_active_item_changed():
	"""Вызывается при изменении активного предмета"""
	_update_item_display()

func _update_item_display():
	"""Обновляет отображение активного предмета"""
	if not item_display:
		return
	
	# Получаем активный предмет из хотбара
	var active_slot_index = PlayerInventory.active_item_slot
	if PlayerInventory.hotbar.has(active_slot_index):
		var item_data = PlayerInventory.hotbar[active_slot_index]
		var item_name = item_data[0]
		
		# Загружаем иконку предмета
		if JsonData.item_data.has(item_name):
			var icon_path = JsonData.item_data[item_name].get("Icon", "")
			if icon_path != "":
				var texture = load(icon_path)
				if texture:
					item_display.texture = texture
					item_display.visible = true
					return
	
	# Если нет активного предмета - скрываем
	item_display.visible = false

func update_dodge_effect():
	"""Простой эффект быстрого движения"""
	# Убираем сложные эффекты - оставляем только обычный спрайт
	%sprite.modulate = Color.WHITE

func get_dodge_chance() -> float:
	"""Возвращает текущий шанс уворота игрока (для отладки)"""
	var base_dodge = 0.1
	var current_speed = velocity.length()
	
	if current_speed > 100:
		var speed_bonus = min((current_speed - 100) / 200.0, 0.4)
		base_dodge += speed_bonus
	
	return base_dodge

# Функции для диалогов
func set_can_move(value: bool):
	"""Устанавливает возможность движения (для диалогов)"""
	can_move = value
	if not can_move:
		velocity = Vector2.ZERO
		character_direction = Vector2.ZERO
		print("Движение игрока заблокировано")
	else:
		print("Движение игрока разблокировано")

func get_can_move() -> bool:
	"""Возвращает возможность движения"""
	return can_move

func _input(event):
	"""Обрабатывает ввод для телепортации"""
	# Телепортация на game_level_2 по клавише F
	if event.is_action_pressed("ui_cancel") and Input.is_key_pressed(KEY_F):
		teleport_to_level("res://scenes/levels/game_level_2.tscn")

func teleport_to_level(level_path: String):
	"""Телепортирует игрока на другой уровень"""
	print("🌀 Телепортация на: ", level_path)
	get_tree().change_scene_to_file(level_path)

func play_walk_sound():
	"""Запускает звук ходьбы"""
	if walk_sound and not walk_sound.playing:
		# Загружаем звук ходьбы
		var walk_audio = load("res://audio/walk.mp3")
		if walk_audio:
			walk_sound.stream = walk_audio
			walk_sound.pitch_scale = 1.0 + randf_range(-0.1, 0.1)  # Небольшая вариация высоты тона
			walk_sound.volume_db = -10.0  # Умеренная громкость
			
			# Подключаем сигнал для зацикливания
			if not walk_sound.finished.is_connected(_on_walk_sound_finished):
				walk_sound.finished.connect(_on_walk_sound_finished)
			
			walk_sound.play()
			print("🎵 Звук ходьбы запущен")
		else:
			print("❌ Не удалось загрузить walk.mp3")

func stop_walk_sound():
	"""Останавливает звук ходьбы (устаревшая функция, используйте stop_all_movement_sounds)"""
	if walk_sound and walk_sound.playing:
		walk_sound.stop()
		print("🎵 Звук ходьбы остановлен")

func update_movement_sounds():
	"""Обновляет звуки движения в зависимости от состояния"""
	# Останавливаем все звуки движения
	stop_all_movement_sounds()
	
	# Запускаем нужный звук
	if is_running:
		play_run_sound()
	else:
		play_walk_sound()

func play_run_sound():
	"""Запускает звук бега"""
	if run_sound and not run_sound.playing:
		# Загружаем звук бега
		var run_audio = load("res://audio/run.ogg")
		if run_audio:
			run_sound.stream = run_audio
			run_sound.pitch_scale = 1.0 + randf_range(-0.05, 0.05)  # Меньшая вариация для бега
			run_sound.volume_db = -8.0  # Немного громче чем ходьба
			
			# Подключаем сигнал для зацикливания
			if not run_sound.finished.is_connected(_on_run_sound_finished):
				run_sound.finished.connect(_on_run_sound_finished)
			
			run_sound.play()
			print("🏃 Звук бега запущен")
		else:
			print("❌ Не удалось загрузить run.mp3")

func stop_all_movement_sounds():
	"""Останавливает все звуки движения"""
	if walk_sound and walk_sound.playing:
		walk_sound.stop()
	if run_sound and run_sound.playing:
		run_sound.stop()
	print("🎵 Все звуки движения остановлены")

func _on_walk_sound_finished():
	"""Вызывается когда звук ходьбы закончился"""
	# Если игрок все еще идет (но не бежит) - повторяем звук ходьбы
	if is_walking and velocity.length() > 10 and not is_running:
		play_walk_sound()

func _on_run_sound_finished():
	"""Вызывается когда звук бега закончился"""
	# Если игрок все еще бежит - повторяем звук бега
	if is_walking and velocity.length() > 10 and is_running:
		play_run_sound()
