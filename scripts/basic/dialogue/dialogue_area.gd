extends Area2D
class_name DialogueArea

# Область для запуска диалога при входе (только если есть амулет)

@export var dialogue_resource: String = ""  # Имя файла диалога без .dialogue
@export var area_name: String = "Диалоговая область"
@export var require_amulet: bool = true  # Требуется ли амулет для активации
@export var one_time_only: bool = true  # Только один раз

var dialogue_triggered: bool = false
var player_in_area: bool = false
var player: CharacterBody2D = null

func _ready():
	# ВРЕМЕННОЕ ИСПРАВЛЕНИЕ: Устанавливаем dialogue_resource по имени узла
	if dialogue_resource == "":
		if name == "Dialog-2":
			dialogue_resource = "dialog-2"
		elif name == "Dialog-3":
			dialogue_resource = "dialog-3"
	
	# Настраиваем коллизию для взаимодействия с игроком
	collision_layer = 0 # Не ставим на какой-то определенный слой
	collision_mask = 4294967295 # Сканируем все слои
	monitoring = true
	monitorable = true
	
	# Настраиваем сигналы
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Ищем игрока с задержкой
	call_deferred("find_player")

func _on_body_entered(body):
	"""Игрок вошел в область"""
	
	if body.is_in_group("player"):
		player_in_area = true
		# Проверяем условия для запуска диалога
		check_dialogue_conditions()
	else:
		pass

func _on_body_exited(body):
	"""Игрок вышел из области"""
	if body.is_in_group("player"):
		player_in_area = false

func check_dialogue_conditions():
	"""Проверяет условия для запуска диалога"""
	# Если диалог уже был запущен и он одноразовый
	if dialogue_triggered and one_time_only:
		return
	
	# Если требуется амулет - проверяем его наличие
	if require_amulet:
		var has_amulet_result = has_amulet()
		if not has_amulet_result:
			return

	# Проверка на собранные цветки для диалога 8
	if dialogue_resource.get_file().get_basename() == "dialog-8":
		var game_state = get_node_or_null("/root/GameStateManager")
		if game_state:
			if game_state.get_collected_flower_count() < 2:
				return
		else:
			return

	# Проверка на зачистку зоны для диалога 12
	if dialogue_resource.get_file().get_basename() == "dialog-12":
		var game_state = get_node_or_null("/root/GameStateManager")
		if game_state:
			if not game_state.is_area_cleared("monster_clearing_1"):
				return
		else:
			return

	# Проверка на 4 кристалла для диалога 13
	if dialogue_resource.get_file().get_basename() == "dialog-13":
		var game_state = get_node_or_null("/root/GameStateManager")
		if game_state:
			var collected_crystals = game_state.get_collected_crystals()
			if collected_crystals < 4:
				return
		else:
			return
	
	# Все условия выполнены - запускаем диалог
	start_dialogue()

func has_amulet() -> bool:
	"""Проверяет, есть ли у игрока амулет"""
	# Проверяем через AmuletManager
	var amulet_manager = get_node("/root/AmuletManager")
	if amulet_manager:
		if amulet_manager.has_method("has_amulet_item"):
			var result = amulet_manager.has_amulet_item()
			if result:
				return true
	
	# Альтернативная проверка - ищем видимый амулет в UI
	var amulet = get_tree().get_first_node_in_group("amulet_character")
	if amulet:
		if amulet.visible:
			return true
	
	return false

func start_dialogue():
	"""Запускает диалог"""
	if dialogue_resource == "":
		return
	
	dialogue_triggered = true
	
	# Останавливаем игрока
	if player and player.has_method("set_can_move"):
		player.set_can_move(false)
	
	# Запускаем диалог через DialogueManager с озвучкой
	if DialogueManager:
		var dialogue_name = dialogue_resource.get_file().get_basename()
		var dialogue_path = "res://dialogs/" + dialogue_name + ".dialogue"
		var dialogue_res = load(dialogue_path)
		if dialogue_res:
			# Подключаемся к сигналу окончания диалога
			if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
				DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

			# Проверяем что нет уже активных balloon'ов
			var existing_balloons = get_tree().get_nodes_in_group("dialogue_balloon")
			if existing_balloons.size() > 0:
				return
			
			# Создаем кастомный balloon с озвучкой
			var balloon_scene = preload("res://addons/dialogue_manager/example_balloon/example_balloon.tscn")
			var voice_balloon = balloon_scene.instantiate()
			voice_balloon.set_script(preload("res://scripts/basic/dialogue/voice_balloon.gd"))
			get_tree().current_scene.add_child(voice_balloon)
			voice_balloon.start(dialogue_res, "start")
		else:
			_on_dialogue_ended()
	else:
		_on_dialogue_ended()
func _on_dialogue_ended(_resource = null):
	"""Вызывается когда диалог закончился"""
	# Проверяем нужно ли добавить кристалл за этот диалог
	check_and_add_crystal_reward()
	
	# Возвращаем управление игроку
	if player and player.has_method("set_can_move"):
		player.set_can_move(true)



func check_and_add_crystal_reward():
	"""Проверяет и добавляет кристалл за завершение диалога"""
	# Извлекаем номер диалога из dialogue_resource
	var dialogue_name = dialogue_resource.get_file().get_basename()
	var dialogue_number = dialogue_name.replace("dialog-", "").to_int()
	
	# Список диалогов, за которые НЕ дают кристаллы
	var excluded_dialogues = [1, 2, 3, 4, 5, 7, 10, 11, 12, 13]
	
	# Специальная логика для диалога 7 - меняем текстуру амулета (ДО проверки кристаллов)
	if dialogue_number == 7:
		change_amulet_texture_to_25()
	
	if dialogue_number in excluded_dialogues:
		return
	
	# Получаем GameStateManager и добавляем кристалл
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		var crystal_id = "dialogue_" + str(dialogue_number)
		game_state.collect_crystal(crystal_id)

func find_player():
	"""Находит игрока"""
	player = get_tree().get_first_node_in_group("player")

func change_amulet_texture_to_25():
	"""Меняет текстуру амулета на 25.png после диалога 7"""
	# Используем GameStateManager для сохранения состояния
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		game_state.set_amulet_texture(25)
	else:
		# Резервный способ - прямое изменение
		var amulet = get_tree().get_first_node_in_group("amulet_character")
		if amulet and amulet.has_method("set_texture"):
			amulet.set_texture(25)

func reset_area():
	"""Сбрасывает область (позволяет запустить диалог снова)"""
	dialogue_triggered = false
