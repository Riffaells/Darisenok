extends Node

# Менеджер состояния уровня
# Восстанавливает состояние амулета и других объектов при загрузке уровня

func _ready():
	print("🗺️ LevelStateManager инициализирован")
	# Небольшая задержка чтобы все объекты успели загрузиться
	call_deferred("restore_level_state")

func restore_level_state():
	"""Восстанавливает состояние уровня"""
	print("🔄 Восстанавливаем состояние уровня...")
	
	var game_state = get_node("/root/GameStateManager")
	if not game_state:
		print("❌ GameStateManager не найден!")
		return
	
	# Восстанавливаем состояние амулета
	restore_amulet_state(game_state)
	
	# Скрываем завершенные диалоги
	hide_completed_dialogues(game_state)
	
	# Скрываем собранные кристаллы
	hide_collected_crystals(game_state)

func restore_amulet_state(game_state):
	"""Восстанавливает состояние амулета"""
	if game_state.get_has_amulet():
		print("✨ У игрока есть амулет - показываем в UI")
		
		# Ищем амулет в UI и показываем его
		call_deferred("show_amulet_ui")
	else:
		print("❌ У игрока нет амулета")

func show_amulet_ui():
	"""Показывает амулет в UI"""
	print("🔍 LevelStateManager ищет амулет в UI...")
	
	# Ищем существующий амулет
	var amulet = get_tree().get_first_node_in_group("amulet_character")
	
	if not amulet:
		print("❌ Амулет не найден, создаем новый")
		# Создаем амулет если его нет
		create_amulet_ui()
	else:
		print("✅ Амулет найден, показываем его")
		# Показываем существующий амулет
		if amulet.has_method("show_amulet"):
			amulet.show_amulet()
			print("✅ Вызван show_amulet()")
		else:
			amulet.visible = true
			print("✅ Установлен visible = true")
		
		# Принудительно обновляем состояние
		if amulet.has_method("check_amulet_state"):
			amulet.check_amulet_state()
			print("✅ Вызван check_amulet_state()")

func create_amulet_ui():
	"""Создает амулет в UI"""
	var amulet_scene = load("res://scenes/dialogue/amulet_character.tscn")
	if not amulet_scene:
		print("❌ Не найдена сцена амулета!")
		return
	
	var amulet_character = amulet_scene.instantiate()
	
	# Ищем UI слой
	var ui_layer = get_tree().get_first_node_in_group("ui_layer")
	if not ui_layer:
		ui_layer = get_tree().current_scene
	
	ui_layer.add_child(amulet_character)
	amulet_character.add_to_group("amulet_character")
	
	# Показываем амулет
	if amulet_character.has_method("show_amulet"):
		amulet_character.show_amulet()
	
	print("✅ Амулет создан и показан в UI")

func hide_completed_dialogues(game_state):
	"""Скрывает объекты завершенных диалогов"""
	var dialogue_objects = get_tree().get_nodes_in_group("dialogue_objects")
	
	for obj in dialogue_objects:
		if obj.has_method("get") and obj.get("dialogue_resource"):
			var dialogue_id = obj.dialogue_resource
			if game_state.is_dialogue_completed(dialogue_id):
				print("🙈 Скрываем завершенный диалог: ", dialogue_id)
				if obj.has_method("hide_amulet"):
					obj.hide_amulet()
				else:
					obj.visible = false

func hide_collected_crystals(game_state):
	"""Скрывает уже собранные кристаллы"""
	var crystals = get_tree().get_nodes_in_group("magic_stones")
	print("🔍 Найдено кристаллов на уровне: ", crystals.size())
	
	for crystal in crystals:
		if crystal.has_method("get") and crystal.get("crystal_id"):
			var crystal_id = crystal.crystal_id
			if game_state.is_crystal_collected(crystal_id):
				print("💎 Скрываем собранный кристалл: ", crystal_id)
				crystal.queue_free()