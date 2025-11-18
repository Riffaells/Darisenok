extends Area2D
class_name ClearableArea

# Зона, которая считается 'зачищенной', когда в ней не остается врагов.

@export var area_id: String = ""

var is_cleared: bool = false

func _ready():
	# Настраиваем коллизию для обнаружения врагов и игрока
	# Слой 2 (игрок) + Слой 3 (враги) = маска 2 + 4 = 6
	collision_layer = 0
	collision_mask = 6 
	
	# Проверяем, была ли зона уже зачищена
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state and game_state.is_area_cleared(area_id):
		is_cleared = true
		set_process(false)
		return
	
	# Выключаем проверку по умолчанию
	set_process(false)
	
	# Подключаем сигналы
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Если в зону вошел игрок и она еще не зачищена
	if body.is_in_group("player") and not is_cleared:
		set_process(true) # Начинаем проверку врагов
		print("Игрок вошел в зону зачистки. Начинаем проверку врагов.")

func _on_body_exited(body):
	# Если игрок покинул зону
	if body.is_in_group("player"):
		set_process(false) # Прекращаем проверку
		print("Игрок покинул зону зачистки. Проверка врагов остановлена.")

func _process(_delta):
	# Получаем все тела внутри зоны
	var overlapping_bodies = get_overlapping_bodies()
	var enemy_found = false
	for body in overlapping_bodies:
		# Проверяем, что это враг (по группе 'enemies')
		if body.is_in_group("enemies"):
			enemy_found = true
			break
	
	# Если врагов не найдено, ПОКА ИГРОК В ЗОНЕ
	if not enemy_found:
		print("✅ Зона '" + area_id + "' зачищена!")
		is_cleared = true
		
		var game_state = get_node_or_null("/root/GameStateManager")
		if game_state:
			# Выдаем кристалл
			var crystal_id = "crystal_from_" + area_id
			game_state.collect_crystal(crystal_id)
			print("💎 Выдан кристалл: ", crystal_id)
			
			# Отмечаем зону как зачищенную
			game_state.set_area_as_cleared(area_id)
			
		# Отключаем дальнейшие проверки
		set_process(false)