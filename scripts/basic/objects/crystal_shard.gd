extends Area2D
class_name CrystalShard

# Осколок кристалла для сбора

@export var shard_value: int = 1  # Сколько осколков дает

var collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	# Генерируем уникальный ID для осколка
	var shard_id = "shard_" + str(global_position.x) + "_" + str(global_position.y)
	
	# Проверяем не собран ли уже этот осколок
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state and game_state.is_crystal_collected(shard_id):
		print("💎 Осколок уже собран: ", shard_id)
		queue_free()
		return
	
	# Настраиваем сигналы
	body_entered.connect(_on_body_entered)
	
	# Добавляем в группу
	add_to_group("crystal_shards")
	
	# Эффект свечения
	start_glow_effect()
	
	print("💎 Осколок кристалла создан (ID: ", shard_id, ")")

func _on_body_entered(body):
	"""Игрок собрал осколок"""
	if body.is_in_group("player") and not collected:
		collect_shard()

func collect_shard():
	"""Собирает осколок"""
	if collected:
		return
	
	collected = true
	var shard_id = "shard_" + str(global_position.x) + "_" + str(global_position.y)
	print("💎 Осколок собран! ID: ", shard_id)
	
	# Сохраняем в GameStateManager
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		game_state.collect_crystal(shard_id)
	
	# Находим счетчик кристаллов и добавляем осколок
	var crystal_counter = get_tree().get_first_node_in_group("crystal_counter")
	if crystal_counter and crystal_counter.has_method("add_shard"):
		crystal_counter.add_shard(shard_value)
	
	# Эффект сбора
	show_collect_effect()
	
	# Удаляем осколок
	queue_free()

func show_collect_effect():
	"""Показывает эффект сбора"""
	if sprite:
		# Анимация исчезновения
		var tween = create_tween()
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.5)

func start_glow_effect():
	"""Запускает эффект свечения"""
	if sprite:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 1.5), 1.0)
		tween.tween_property(sprite, "modulate", Color.WHITE, 1.0)