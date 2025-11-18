# Интерфейсы поведений предметов
class_name ItemBehaviors

# Базовый интерфейс для всех поведений
class IItemBehavior:
	func use(_item_data: Dictionary, _user: Node2D) -> bool:
		return false

	func can_use(_item_data: Dictionary, _user: Node2D) -> bool:
		return true

	func get_use_description() -> String:
		return "Использовать"

# Поведение ближнего боя (мечи, ножи, дубинки)
class MeleeWeaponBehavior extends IItemBehavior:
	func use(item_data: Dictionary, user: Node2D) -> bool:
		var damage = item_data.get("damage", 10)
		var range_val = item_data.get("range", 50)
		var attack_type = item_data.get("attack_type", "slash")

		print("Атака ближнего боя! Урон: ", damage, ", тип: ", attack_type)
		_perform_melee_attack(user, damage, range_val)
		return false  # Оружие не расходуется

	func _perform_melee_attack(user: Node2D, damage: int, range_val: float):
		var attack_area = _create_attack_area(user, range_val)
		_damage_enemies_in_area(attack_area, damage)

	func _create_attack_area(user: Node2D, range_val: float) -> Array:
		var space_state = user.get_world_2d().direct_space_state
		var query = PhysicsShapeQueryParameters2D.new()

		var attack_type = "slash" # Заглушка, т.к. больше не передается

		match attack_type:
			"slash":  # Широкая дуга
				var sector_shape = CircleShape2D.new()
				sector_shape.radius = range_val
				query.shape = sector_shape
			"stab":   # Узкий конус
				var rect_shape = RectangleShape2D.new()
				rect_shape.size = Vector2(range_val, 20)
				query.shape = rect_shape
			_:
				var circle_shape = CircleShape2D.new()
				circle_shape.radius = range_val
				query.shape = circle_shape

		query.transform = Transform2D(0, user.global_position)
		query.collision_mask = 4  # Слой врагов (враги на слое 4, игрок на слое 2)
		return space_state.intersect_shape(query)

	func _damage_enemies_in_area(results: Array, damage: int):
		for result in results:
			var enemy = result.collider
			# КРИТИЧЕСКИ ВАЖНО: НЕ АТАКУЕМ ИГРОКА!
			if enemy.is_in_group("player"):
				print("⚠️ Пропускаем игрока при атаке оружием!")
				continue
			
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

	func get_use_description() -> String:
		return "Атаковать"

# Поведение дальнего боя (луки, арбалеты)
class RangedWeaponBehavior extends IItemBehavior:
	func use(item_data: Dictionary, user: Node2D) -> bool:
		var damage = item_data.get("damage", 15)
		var range_val = item_data.get("range", 200)
		var projectile_type = item_data.get("projectile_type", "arrow")
		var ammo_required = item_data.get("ammo_required", "")

		# Проверяем наличие боеприпасов
		if ammo_required != "" and not _has_ammo(user, ammo_required):
			print("Нет боеприпасов: ", ammo_required)
			return false

		print("Дальняя атака! Урон: ", damage, ", снаряд: ", projectile_type)
		_shoot_projectile(user, damage, range_val, projectile_type)

		# Расходуем боеприпасы
		if ammo_required != "":
			_consume_ammo(user, ammo_required)

		return false

	func _has_ammo(user: Node2D, ammo_type: String) -> bool:
		# Проверяем инвентарь на наличие боеприпасов
		if user.has_method("has_item"):
			return user.has_item(ammo_type)
		return true  # Если нет системы проверки, считаем что есть

	func _consume_ammo(user: Node2D, ammo_type: String):
		if user.has_method("consume_item"):
			user.consume_item(ammo_type, 1)

	func _shoot_projectile(user: Node2D, damage: int, range_val: float, projectile_type: String):
		# Здесь будет логика создания снаряда
		print("Выстрел снарядом ", projectile_type, " на дальность ", range_val)

	func get_use_description() -> String:
		return "Выстрелить"

# Поведение магического оружия (посохи, жезлы)
class MagicWeaponBehavior extends IItemBehavior:
	func use(item_data: Dictionary, user: Node2D) -> bool:
		var damage = item_data.get("damage", 20)
		var mana_cost = item_data.get("mana_cost", 10)
		var spell_type = item_data.get("spell_type", "fireball")
		var range_val = item_data.get("range", 150)

		# Проверяем ману
		if not _has_mana(user, mana_cost):
			print("Недостаточно маны! Нужно: ", mana_cost)
			return false

		print("Магическая атака! Заклинание: ", spell_type, ", урон: ", damage)
		_cast_spell(user, damage, range_val, spell_type)
		_consume_mana(user, mana_cost)

		return false

	func _has_mana(user: Node2D, mana_cost: int) -> bool:
		if user.has_method("get_mana"):
			return user.get_mana() >= mana_cost
		return true

	func _consume_mana(user: Node2D, mana_cost: int):
		if user.has_method("consume_mana"):
			user.consume_mana(mana_cost)

	func _cast_spell(user: Node2D, damage: int, range_val: float, spell_type: String):
		match spell_type:
			"fireball":
				_cast_fireball(user, damage, range_val)
			"lightning":
				_cast_lightning(user, damage, range_val)
			"heal":
				_cast_heal(user, damage)
			_:
				print("Неизвестное заклинание: ", spell_type)

	func _cast_fireball(user: Node2D, damage: int, range_val: float):
		print("Огненный шар! Взрывной урон в радиусе")
		# Логика взрывного урона

	func _cast_lightning(user: Node2D, damage: int, range_val: float):
		print("Молния! Цепной урон по нескольким целям")
		# Логика цепного урона

	func _cast_heal(user: Node2D, heal_amount: int):
		print("Лечение на ", heal_amount, " здоровья")
		if user.has_method("heal"):
			user.heal(heal_amount)

	func get_use_description() -> String:
		return "Колдовать"

# Поведение еды
class FoodBehavior extends IItemBehavior:
	func use(item_data: Dictionary, user: Node2D) -> bool:
		var heal_amount = item_data.get("heal_amount", 0)
		var energy_amount = item_data.get("energy_amount", 0)
		var buff_type = item_data.get("buff_type", "")
		var buff_duration = item_data.get("buff_duration", 0)

		var used = false
		
		# Восстанавливаем здоровье
		if user.has_method("heal") and heal_amount > 0:
			if user.heal(heal_amount):
				used = true

		# Восстанавливаем энергию
		if user.has_method("restore_energy") and energy_amount > 0:
			if user.restore_energy(energy_amount):
				used = true

		# Применяем бафф если есть
		if buff_type != "" and user.has_method("apply_buff"):
			user.apply_buff(buff_type, buff_duration)
			used = true

		# Если ничего не восстановилось, но предмет съедобный - всё равно "съедаем"
		if not used and (heal_amount > 0 or energy_amount > 0):
			print("Характеристики уже максимальны, но предмет съеден")
			used = true

		return used  # Еда расходуется если была использована

	func can_use(item_data: Dictionary, user: Node2D) -> bool:
		# Еду можно использовать если здоровье или энергия не максимальны
		var heal_amount = item_data.get("heal_amount", 0)
		var energy_amount = item_data.get("energy_amount", 0)
		
		if heal_amount > 0 and user.has_method("get_health"):
			var player_stats = user.get_node_or_null("PlayerStats")
			if player_stats and player_stats.current_health < player_stats.max_health:
				return true
		
		if energy_amount > 0 and user.has_method("get_energy"):
			var player_stats = user.get_node_or_null("PlayerStats")
			if player_stats and player_stats.current_energy < player_stats.max_energy:
				return true
		
		# Если есть бафф - всегда можно использовать
		if item_data.get("buff_type", "") != "":
			return true
		
		return false

	func get_use_description() -> String:
		return "Съесть"

# Поведение ключа
class KeyBehavior extends IItemBehavior:
	func use(item_data: Dictionary, user: Node2D) -> bool:
		var key_id = item_data.get("key_id", "")
		var use_range = item_data.get("use_range", 100)
		var is_master_key = item_data.get("is_master_key", false)

		var door = _find_door_in_range(user, use_range, key_id, is_master_key)
		if door:
			if door.has_method("unlock"):
				var success = door.unlock(key_id)
				if success:
					print("Дверь открыта ключом: ", key_id)
					return item_data.get("single_use", false)  # Одноразовые ключи расходуются
				else:
					print("Ключ не подходит к этой двери")
			else:
				print("Этот объект нельзя открыть")
		else:
			print("Нет подходящей двери поблизости")

		return false

	func _find_door_in_range(user: Node2D, range_val: float, key_id: String, is_master_key: bool) -> Node2D:
		var space_state = user.get_world_2d().direct_space_state
		var query = PhysicsShapeQueryParameters2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = range_val
		query.shape = circle_shape
		query.transform = Transform2D(0, user.global_position)
		query.collision_mask = 4  # Слой интерактивных объектов

		var results = space_state.intersect_shape(query)
		for result in results:
			var obj = result.collider
			if obj.has_method("can_unlock_with"):
				if is_master_key or obj.can_unlock_with(key_id):
					return obj

		return null

	func can_use(item_data: Dictionary, user: Node2D) -> bool:
		var key_id = item_data.get("key_id", "")
		var use_range = item_data.get("use_range", 100)
		var is_master_key = item_data.get("is_master_key", false)
		return _find_door_in_range(user, use_range, key_id, is_master_key) != null

	func get_use_description() -> String:
		return "Открыть замок"

# Поведение инструмента
class ToolBehavior extends IItemBehavior:
	func use(_item_data: Dictionary, user: Node2D) -> bool:
		var tool_type = _item_data.get("tool_type", "")
		var efficiency = _item_data.get("efficiency", 1.0)

		match tool_type:
			"shovel":
				return _use_shovel(user, efficiency)
			"axe":
				return _use_axe(user, efficiency)
			"pickaxe":
				return _use_pickaxe(user, efficiency)
			_:
				print("Неизвестный тип инструмента: ", tool_type)
				return false

	func _use_shovel(user: Node2D, efficiency: float) -> bool:
		# Логика копания
		print("Копаю с эффективностью: ", efficiency)
		return true

	func _use_axe(user: Node2D, efficiency: float) -> bool:
		# Логика рубки деревьев
		print("Рублю деревья с эффективностью: ", efficiency)
		return true

	func _use_pickaxe(user: Node2D, efficiency: float) -> bool:
		# Логика добычи руды
		print("Добываю руду с эффективностью: ", efficiency)
		return true

	func get_use_description() -> String:
		return "Использовать инструмент"
