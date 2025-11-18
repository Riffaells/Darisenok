extends CanvasLayer

const SlotClass = preload("res://scripts/basic/items/slot.gd")

# UIManager - Главный управляющий интерфейсом инвентаря
#
# Новые возможности:
# 1. Хотбар:
#    - Переключение слотов клавишами 1-9
#    - Клик по слоту для переключения активного слота
#    - Колесико мыши для последовательного переключения
#
# 2. Перетаскивание предметов:
#    - Зажать ЛКМ на предмете для начала перетаскивания
#    - Отпустить ЛКМ на целевом слоте для размещения
#    - Автоматический обмен предметами при перетаскивании
#    - Работает между инвентарем, хотбаром и слотами экипировки
#
# 3. Использование предметов:
#    - ПКМ по предмету для использования
#    - Автоматическое удаление предмета при использовании (если он расходуется)

@onready var inventory = $Inventory
@onready var hotbar = $Hotbar
@onready var health_energy_ui = $HealthEnergyUI
@onready var crystal_counter = $CrystalCounter
# Узел, который будет отображать перетаскиваемый предмет
@onready var dragged_item_display: TextureRect = $DraggedItemDisplay

# Прямые ссылки на UI элементы здоровья для удобства
@onready var health_bar: ProgressBar = $HealthEnergyUI/HealthBar
@onready var energy_bar: ProgressBar = $HealthEnergyUI/EnergyBar

# Данные о перетаскиваемом слоте
var dragged_slot = null

func _ready():
	# Проверяем, что все узлы существуют
	if not inventory:
		push_error("UIManager: Узел Inventory не найден!")
		return
	if not hotbar:
		push_error("UIManager: Узел Hotbar не найден!")
		return
	if not dragged_item_display:
		push_error("UIManager: Узел DraggedItemDisplay не найден!")
		return
	
	inventory.visible = false
	dragged_item_display.visible = false # Скрываем его по умолчанию
	
	# Настраиваем видимость кристаллов в зависимости от уровня
	_setup_crystal_counter_visibility()
	
	# Принудительно включаем _process, чтобы гарантировать обновление позиции
	set_process(true)
	add_test_items()
	
	# Подключаемся к сигналам игрока для обновления UI здоровья
	_connect_to_player_stats()

func _process(_delta):
	# Если мы перетаскиваем предмет, его иконка следует за курсором
	if dragged_slot:
		dragged_item_display.global_position = get_viewport().get_mouse_position() - dragged_item_display.size / 2
	# Страховка: если перетаскивание было отменено, а иконка осталась - прячем
	elif dragged_item_display.visible:
		dragged_item_display.visible = false

func _input(event):
	# 1. Открытие/закрытие инвентаря
	if event.is_action_pressed("ui_inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return

	# 1.5. Переключение слотов хотбара клавишами 1-9 (только когда инвентарь закрыт)
	if not inventory.visible:
		# Попробуем прямые коды клавиш вместо действий
		if event is InputEventKey and event.is_pressed():
			match event.keycode:
				KEY_1:
					hotbar.select_slot(0)
					get_viewport().set_input_as_handled()
					return
				KEY_2:
					hotbar.select_slot(1)
					get_viewport().set_input_as_handled()
					return
				KEY_3:
					hotbar.select_slot(2)
					get_viewport().set_input_as_handled()
					return
				KEY_4:
					hotbar.select_slot(3)
					get_viewport().set_input_as_handled()
					return
				KEY_5:
					hotbar.select_slot(4)
					get_viewport().set_input_as_handled()
					return
				KEY_6:
					hotbar.select_slot(5)
					get_viewport().set_input_as_handled()
					return
				KEY_7:
					hotbar.select_slot(6)
					get_viewport().set_input_as_handled()
					return
				KEY_8:
					hotbar.select_slot(7)
					get_viewport().set_input_as_handled()
					return
				KEY_9:
					hotbar.select_slot(8)
					get_viewport().set_input_as_handled()
					return

	# 2. Логика колесика мыши для переключения слотов хотбара (только когда инвентарь закрыт)
	if not inventory.visible:
		if event.is_action_pressed("scroll_down") || event.is_action_pressed("scroll_hotbar_right"):
			print("UIManager: Колесико вправо")
			hotbar.scroll_right()
			get_viewport().set_input_as_handled()
			return
		elif event.is_action_pressed("scroll_up") || event.is_action_pressed("scroll_hotbar_left"):
			print("UIManager: Колесико влево")
			hotbar.scroll_left()
			get_viewport().set_input_as_handled()
			return

	# 3. Логика кнопок мыши
	if event is InputEventMouseButton and event.is_pressed():

		# === ЛОГИКА ДЛЯ ОТКРЫТОГО ИНВЕНТАРЯ ===
		if inventory.visible:
			# ЛКМ: перетаскивание предметов в инвентаре
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Если предмет уже "на курсоре"
				if dragged_slot:
					var target_slot = _get_slot_under_mouse()
					# Если кликнули на слот - кладем предмет
					if target_slot:
						_drop_item_on_slot(target_slot)
					# Если кликнули мимо - отменяем
					else:
						_cancel_drag()
					get_viewport().set_input_as_handled()
				# Если предмет не на курсоре, пытаемся его взять
				else:
					var slot_to_drag = _get_slot_under_mouse()
					if slot_to_drag and not slot_to_drag.is_empty():
						_start_drag(slot_to_drag)
						get_viewport().set_input_as_handled()

			# ПКМ: использование предметов в инвентаре
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# Если перетаскиваем - отменяем
				if dragged_slot:
					_cancel_drag()
					get_viewport().set_input_as_handled()
				# Иначе используем предмет
				else:
					var slot_to_use = _get_slot_under_mouse()
					if slot_to_use and not slot_to_use.is_empty():
						_use_item_from_slot(slot_to_use)
						get_viewport().set_input_as_handled()

		# === ЛОГИКА ДЛЯ ЗАКРЫТОГО ИНВЕНТАРЯ (ИГРОВОЙ МИР) ===
		else:
			# ЛКМ: проверяем клик по хотбару или атака активным предметом
			if event.button_index == MOUSE_BUTTON_LEFT:
				var clicked_hotbar_slot = _get_clicked_hotbar_slot()
				if clicked_hotbar_slot != -1:
					# Кликнули по слоту хотбара - переключаем активный слот
					hotbar.select_slot(clicked_hotbar_slot)
					get_viewport().set_input_as_handled()
				else:
					# Кликнули мимо хотбара - атакуем
					_attack_with_active_item()
					get_viewport().set_input_as_handled()

			# ПКМ: использование активного предмета из хотбара
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_use_active_hotbar_item()
				get_viewport().set_input_as_handled()

func toggle_inventory():
	inventory.visible = !inventory.visible
	if not inventory.visible and dragged_slot:
		_cancel_drag()

func _start_drag(slot):
	if not slot.item: return

	# Получаем текстуру предмета
	var texture = null
	if slot.item.has_method("get_texture"):
		texture = slot.item.get_texture()

	if not texture:
		print("UI Manager: Не удалось получить текстуру для '", slot.get_item_name(), "'")
		return

	dragged_slot = slot

	# Настраиваем иконку для перетаскивания
	dragged_item_display.texture = texture
	# Устанавливаем размер с ограничением (чтобы не было слишком больших иконок)
	var texture_size = texture.get_size()
	var max_size = 64.0  # Максимальный размер иконки
	if texture_size.x > max_size or texture_size.y > max_size:
		var scale_factor = max_size / max(texture_size.x, texture_size.y)
		dragged_item_display.size = texture_size * scale_factor
	else:
		dragged_item_display.size = texture_size
	
	dragged_item_display.modulate = Color(1, 1, 1, 0.7)
	dragged_item_display.visible = true

	# Прячем оригинальный предмет
	slot.item.visible = false

func _cancel_drag():
	if not dragged_slot: return
	dragged_slot.item.visible = true
	dragged_slot = null
	dragged_item_display.visible = false

func _drop_item_on_slot(target_slot):
	if not dragged_slot or dragged_slot == target_slot:
		_cancel_drag()
		return

	# Показываем перетаскиваемый предмет обратно
	dragged_slot.item.visible = true

	# Выполняем обмен предметов через PlayerInventory
	PlayerInventory.swap_items(dragged_slot, target_slot)

	# Обновляем хотбар если один из слотов был из хотбара
	if dragged_slot.slotType == SlotClass.SlotType.HOTBAR or target_slot.slotType == SlotClass.SlotType.HOTBAR:
		hotbar.initialize_hotbar()
	
	# Обновляем инвентарь если один из слотов был из инвентаря
	if dragged_slot.slotType == SlotClass.SlotType.INVENTORY or target_slot.slotType == SlotClass.SlotType.INVENTORY:
		inventory.initialize_inventory()

	# Заканчиваем перетаскивание
	dragged_slot = null
	dragged_item_display.visible = false

func _get_slot_under_mouse():
	var mouse_pos = get_viewport().get_mouse_position()

	# Сначала проверяем слоты инвентаря
	if inventory.visible:
		for slot in inventory.slots:
			if slot.get_global_rect().has_point(mouse_pos):
				return slot

		# Потом проверяем слоты экипировки
		for slot in inventory.equip_slots:
			if slot.get_global_rect().has_point(mouse_pos):
				return slot

	# Затем проверяем слоты хотбара (всегда видимы)
	for slot in hotbar.slots:
		if slot.get_global_rect().has_point(mouse_pos):
			return slot

	return null

func _get_clicked_hotbar_slot() -> int:
	"""Возвращает индекс слота хотбара под курсором или -1 если не найден"""
	var mouse_pos = get_viewport().get_mouse_position()
	for i in range(hotbar.slots.size()):
		if hotbar.slots[i].get_global_rect().has_point(mouse_pos):
			return i
	return -1

func add_test_items():
	# Добавляем только предметы, которые есть в item_data.json
	var test_items = [
		["Frying Pan", 1],
		["Energy Bar", 10]
	]

	for item_data in test_items:
		PlayerInventory.add_item(item_data[0], item_data[1])

func _use_item_from_slot(slot):
	"""Использует предмет из указанного слота"""
	if slot and not slot.is_empty():
		var player = get_tree().root.find_child("player", true, false)
		if player:
			# Используем метод use_item слота, который уже обрабатывает удаление предмета
			if slot.use_item(player):
				print("Использован предмет: ", slot.get_item_name())
			else:
				print("Не удалось использовать предмет: ", slot.get_item_name())

func _use_active_hotbar_item():
	"""Использует активный предмет из хотбара (ПКМ в игровом мире)"""
	var active_slot = hotbar.get_active_slot()
	if active_slot and not active_slot.is_empty():
		var player = get_tree().root.find_child("player", true, false)
		if player:
			# Используем метод use_item слота, который уже обрабатывает удаление предмета
			if active_slot.use_item(player):
				print("Использован предмет: ", active_slot.get_item_name())
			else:
				print("Не удалось использовать предмет: ", active_slot.get_item_name())

func _attack_with_active_item():
	"""Атакует активным предметом из хотбара (ЛКМ в игровом мире)"""
	var active_slot = hotbar.get_active_slot()
	var player = get_tree().root.find_child("player", true, false)

	if player:
		if active_slot and not active_slot.is_empty():
			var item = active_slot.item
			# Проверяем, является ли предмет оружием
			if item and item.item_data and item.item_data.has("weapon_type"):
				# Используем предмет как оружие
				if item.has_method("use_item"):
					item.use_item(player)
					print("Атака оружием: ", active_slot.get_item_name())
				else:
					print("Предмет не может быть использован как оружие")
					_perform_bare_hand_attack(player)
			else:
				print("Атака кулаками (нет оружия в руках)")
				_perform_bare_hand_attack(player)
		else:
			print("Атака кулаками (пустые руки)")
			_perform_bare_hand_attack(player)

func _perform_bare_hand_attack(player):
	"""Атака без оружия (кулаками)"""
	var base_damage = 5
	var attack_range = 40
	
	print("Атака кулаками, урон: ", base_damage)
	
	# Ищем врагов в радиусе атаки
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = attack_range
	query.shape = circle_shape
	query.transform = Transform2D(0, player.global_position)
	query.collision_mask = 2  # Слой врагов
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var enemy = result.collider
		if enemy.has_method("take_damage"):
			enemy.take_damage(base_damage)
			print("Кулак попал в ", enemy.name, "!")

# Тестовые команды (можно убрать позже)
func _unhandled_key_input(event):
	if event.is_pressed():
		var player = get_tree().root.find_child("player", true, false)
		if not player:
			return
		
		match event.keycode:
			KEY_F1:  # Восстановить здоровье
				player.heal(20)
				print("Тест: восстановлено 20 здоровья")
			KEY_F2:  # Нанести урон
				player.take_damage(15)
				print("Тест: получено 15 урона")
			KEY_F3:  # Восстановить энергию
				player.restore_energy(30)
				print("Тест: восстановлено 30 энергии")
			KEY_F4:  # Потратить энергию
				if player.consume_energy(20):
					print("Тест: потрачено 20 энергии")
				else:
					print("Тест: недостаточно энергии")
			KEY_F5:  # Применить бафф скорости
				player.apply_buff("speed", 10.0)
				print("Тест: применён бафф скорости на 10 сек")
# Методы для работы с UI здоровья и энергии
func _connect_to_player_stats():
	"""Подключается к сигналам игрока для обновления UI"""
	var player = get_tree().root.find_child("player", true, false)
	if player:
		var player_stats = player.get_node_or_null("PlayerStats")
		if player_stats:
			player_stats.health_changed.connect(_on_health_changed)
			player_stats.energy_changed.connect(_on_energy_changed)
			print("UIManager: Подключен к PlayerStats")
		else:
			print("UIManager: PlayerStats не найден у игрока")
	else:
		print("UIManager: Игрок не найден")

func _on_health_changed(current_health: float, max_health: float):
	"""Обновляет UI здоровья с плавной анимацией"""
	if health_bar:
		health_bar.max_value = max_health
		
		# Плавная анимация изменения здоровья
		var tween = create_tween()
		tween.tween_property(health_bar, "value", current_health, 0.3)
		
		# Меняем цвет в зависимости от уровня здоровья
		var health_percent = current_health / max_health
		var target_color: Color
		if health_percent > 0.6:
			target_color = Color.GREEN
		elif health_percent > 0.3:
			target_color = Color.YELLOW
		else:
			target_color = Color.RED
		
		# Плавная анимация цвета
		tween.parallel().tween_property(health_bar, "modulate", target_color, 0.2)

func _on_energy_changed(current_energy: float, max_energy: float):
	"""Обновляет UI энергии с плавной анимацией"""
	if energy_bar:
		energy_bar.max_value = max_energy
		
		# Плавная анимация изменения энергии
		var tween = create_tween()
		tween.tween_property(energy_bar, "value", current_energy, 0.2)

func _setup_crystal_counter_visibility():
	"""Настраивает видимость счетчика кристаллов в зависимости от уровня"""
	if not crystal_counter:
		return
	
	# Получаем имя текущей сцены
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_name = current_scene.name
		print("🔍 UIManager: Текущая сцена: ", scene_name)
		
		# Показываем кристаллы только на втором уровне и далее
		if scene_name == "GameLevel1":
			crystal_counter.visible = false
			print("💎 UIManager: Кристаллы скрыты на первом уровне")
		else:
			crystal_counter.visible = true
			print("💎 UIManager: Кристаллы показаны на уровне: ", scene_name)
