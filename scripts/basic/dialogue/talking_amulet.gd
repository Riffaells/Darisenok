extends Area2D
class_name TalkingAmulet

# Говорящий амулет - запускает диалог при приближении игрока

@export var dialogue_resource: String = "dialog-1"
@export var auto_start: bool = true  # Автоматически запускать диалог
@export var one_time_only: bool = true  # Только один раз
@export var activation_distance: float = 50.0  # Расстояние активации

var player: CharacterBody2D = null
var dialogue_started: bool = false
var is_player_near: bool = false

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var interaction_area: CollisionPolygon2D = $CollisionPolygon2D if has_node("CollisionPolygon2D") else null




# Визуальные эффекты
var glow_tween: Tween

func _ready():
	# Настраиваем коллизию (стандартные настройки)
	collision_layer = 1  # Стандартный слой
	collision_mask = 1   # Взаимодействует со слоем 1 (игрок)
	monitoring = true
	monitorable = true
	

	
	# Настраиваем сигналы
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Ищем игрока с задержкой
	call_deferred("find_player")
	
	# Добавляем в группу
	add_to_group("dialogue_objects")
	
	# Запускаем эффект свечения
	start_glow_effect()

func find_player():
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	# Экстренная разблокировка движения по Escape
	if Input.is_action_just_pressed("ui_cancel") and player:
		if player.has_method("set_can_move"):
			player.set_can_move(true)
		if "can_move" in player:
			player.can_move = true
	
	# Активация амулета по клавише T
	if Input.is_key_pressed(KEY_T) and player:
		var amulet = get_tree().get_first_node_in_group("amulet_character")
		if amulet and amulet.visible and amulet.is_clickable:
			amulet.use_amulet()
	
	if not dialogue_started and player:
		# Проверяем расстояние до игрока
		var distance = global_position.distance_to(player.global_position)
		
		if distance <= activation_distance:
			if auto_start and not dialogue_started:
				start_dialogue()
			elif not auto_start and Input.is_action_just_pressed("ui_accept"):
				start_dialogue()

func _on_body_entered(body):
	"""Игрок вошел в область"""
	if body.is_in_group("player"):
		is_player_near = true
		
		# Усиливаем свечение
		if sprite:
			sprite.modulate = Color(1.5, 1.5, 1.0)
		
		# Если автозапуск включен - сразу запускаем диалог
		if auto_start and not dialogue_started:
			start_dialogue()

func _on_body_exited(body):
	"""Игрок вышел из области"""
	if body.is_in_group("player"):
		is_player_near = false
		
		# Возвращаем обычное свечение
		if sprite:
			sprite.modulate = Color(1.2, 1.2, 0.8)

func start_dialogue():
	"""Запускает диалог"""
	# Проверяем не завершен ли уже этот диалог
	var game_state = get_node("/root/GameStateManager")
	if game_state and game_state.is_dialogue_completed(dialogue_resource) and one_time_only:
		print("Диалог уже завершен: ", dialogue_resource)
		return
	
	if dialogue_started and one_time_only:
		return
	
	dialogue_started = true
	

	
	# Останавливаем игрока
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
	
	# Показываем амулет-персонаж
	show_amulet_character()
	
	# Запускаем диалог
	if DialogueManager:
		var dialogue_path = "res://dialogs/" + dialogue_resource + ".dialogue"
		var dialogue_res = load(dialogue_path)
		if dialogue_res:
			# Подключаемся к сигналу окончания диалога
			if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
				DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

			# Проверяем что нет уже активных balloon'ов
			var existing_balloons = get_tree().get_nodes_in_group("dialogue_balloon")
			if existing_balloons.size() > 0:
				return
			
			# Используем стандартный balloon пока
			# Создаем кастомный balloon с озвучкой
			var balloon_scene = preload("res://addons/dialogue_manager/example_balloon/example_balloon.tscn")
			var voice_balloon = balloon_scene.instantiate()
			voice_balloon.set_script(preload("res://scripts/basic/dialogue/voice_balloon.gd"))
			get_tree().current_scene.add_child(voice_balloon)
			voice_balloon.start(dialogue_res, "start")
			
			# # Только аварийное разблокирование через 150 секунд на случай зависания
			# get_tree().create_timer(150.0).timeout.connect(func():
			# 	print("⚠️ АВАРИЙНОЕ РАЗБЛОКИРОВАНИЕ - диалог завис")
			# 	force_enable_movement()
			# )
		else:
			_on_dialogue_ended()
	else:
		show_simple_dialogue()
		_on_dialogue_ended()

func show_simple_dialogue():
	"""Показывает простой диалог"""
	var dialog = AcceptDialog.new()
	dialog.title = "Говорящий амулет"
	dialog.dialog_text = "Диалог: " + dialogue_resource + "\n\nАкжан: Помогите! Вытащите меня отсюда!\n\n(Для полного диалога нужен DialogueManager)"
	
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())


func _on_dialogue_ended(resource = null):
	"""Вызывается когда диалог закончился"""
	print("=== ДИАЛОГ ЗАВЕРШЕН ===")
	
	# Отмечаем диалог как завершенный в глобальном состоянии
	var game_state = get_node("/root/GameStateManager")
	if game_state:
		game_state.mark_dialogue_completed(dialogue_resource)
		print("✅ Диалог отмечен как завершенный: ", dialogue_resource)
	
	# ВАЖНО: Даем амулет игроку после диалога с Акжаном
	if dialogue_resource == "dialog-1":
		give_amulet_to_player()
	
	# Возвращаем управление игроку
	print("Возвращаем управление игроку...")
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)
	
	# Если диалог одноразовый - скрываем амулет на карте
	if one_time_only:
		hide_amulet()

func force_enable_movement():
	"""Принудительно включает движение игрока"""
	print("🔧 ПРИНУДИТЕЛЬНОЕ РАЗБЛОКИРОВАНИЕ ДВИЖЕНИЯ")
	if player:
		if player.has_method("set_can_move"):
			player.set_can_move(true)
		# Также проверим переменную напрямую
		if "can_move" in player:
			player.can_move = true
			print("✓ can_move установлен в true напрямую")
		print("✓ Движение принудительно разблокировано")



func give_amulet_to_player():
	"""Дает амулет игроку после диалога"""
	print("🔮 Даем амулет игроку после диалога!")
	
	# Используем глобальный менеджер состояния
	var game_state = get_node("/root/GameStateManager")
	if game_state:
		print("✅ GameStateManager найден, вызываем give_amulet()")
		game_state.give_amulet()
		print("✅ Амулет дан через GameStateManager")
	else:
		print("❌ GameStateManager не найден! Используем старый способ...")
		# Используем глобальный менеджер амулета
		var amulet_manager = get_node("/root/AmuletManager")
		if amulet_manager:
			amulet_manager.give_amulet()
		else:
			print("AmuletManager не найден! Ищем амулет напрямую...")
			# Прямой поиск амулета
			var amulet = get_tree().root.find_child("AmuletCharacter", true, false)
			if amulet and amulet.has_method("show_amulet"):
				amulet.show_amulet()



func hide_amulet():
	"""Скрывает амулет после диалога"""
	print("Амулет исчезает с карты...")
	
	# Просто скрываем спрайт (без анимации)
	if sprite:
		sprite.visible = false
	else:
		print("НЕТУУ.")

	
	# Отключаем коллизию, чтобы нельзя было снова активировать
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	
	print("✓ Амулет скрыт с карты")

func start_glow_effect():
	"""Запускает эффект свечения амулета"""
	if not sprite:
		return
	
	glow_tween = create_tween()
	glow_tween.set_loops()
	
	# Плавное свечение
	glow_tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 0.6), 1.5)
	glow_tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 0.8), 1.5)

func force_start_dialogue():
	"""Принудительно запускает диалог (для вызова из кода)"""
	dialogue_started = false  # Сбрасываем флаг
	start_dialogue()

# Функция для тестирования из консоли
func test_dialogue():
	"""Тестовая функция для запуска из консоли"""
	force_start_dialogue()

# Функция для добавления в игрока
func show_amulet_character():
	"""Показывает амулет-персонаж в UI"""
	# Ищем существующий амулет-персонаж
	var existing_amulet = get_tree().get_first_node_in_group("amulet_character")
	
	if not existing_amulet:
		# Создаем новый амулет-персонаж
		var amulet_scene = preload("res://scenes/dialogue/amulet_character.tscn")
		var amulet_character = amulet_scene.instantiate()
		
		# Добавляем в UI (CanvasLayer)
		var ui_layer = get_tree().get_first_node_in_group("ui_layer")
		if ui_layer:
			ui_layer.add_child(amulet_character)
		else:
			# Добавляем прямо на сцену
			get_tree().current_scene.add_child(amulet_character)
		
		amulet_character.add_to_group("amulet_character")
		existing_amulet = amulet_character
	
	# Запускаем анимацию диалога
	if existing_amulet and existing_amulet.has_method("on_dialogue_started"):
		existing_amulet.on_dialogue_started()

func hide_amulet_character():
	"""Скрывает амулет-персонаж"""
	var amulet_character = get_tree().get_first_node_in_group("amulet_character")
	if amulet_character and amulet_character.has_method("on_dialogue_ended"):
		amulet_character.on_dialogue_ended()
		
		# Если диалог одноразовый - скрываем персонаж
		if one_time_only:
			amulet_character.hide_amulet()
