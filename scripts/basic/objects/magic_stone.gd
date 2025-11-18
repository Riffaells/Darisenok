extends StaticBody2D
class_name MagicStone

# Магический камень - препятствие, которое убирается амулетом

@export var interaction_distance: float = 100.0  # Расстояние для взаимодействия (увеличено)
@export var stone_name: String = "Магический камень"

var player: CharacterBody2D = null
var is_destroyed: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_collision: CollisionShape2D = $InteractionArea/CollisionShape2D

func _ready():
	# Ищем игрока
	player = get_tree().get_first_node_in_group("player")
	
	# Настраиваем область взаимодействия
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
		
		# Настраиваем слои коллизий для взаимодействия с игроком
		interaction_area.collision_mask = 2  # Слой игрока (как в телепорте)
		interaction_area.monitoring = true
		
		# Увеличиваем область взаимодействия программно
		if interaction_collision and interaction_collision.shape is RectangleShape2D:
			var shape = interaction_collision.shape as RectangleShape2D
			shape.size = Vector2(120, 120)  # Увеличиваем область
			print("🔧 Область взаимодействия камня увеличена до: ", shape.size)
		
		print("🔧 Настройки области взаимодействия:")
		print("	collision_mask: ", interaction_area.collision_mask)
		print("	monitoring: ", interaction_area.monitoring)
	
	# Добавляем в группу
	add_to_group("magic_stones")
	
	print("🗿 Магический камень создан: ", stone_name, " в позиции: ", global_position)
	

var player_nearby: bool = false

func _on_player_entered(body):
	"""Игрок вошел в зону взаимодействия"""
	if body.is_in_group("player"):
		player_nearby = true
		print("✅ Игрок подошел к ", stone_name, " в позиции: ", global_position)

func _on_player_exited(body):
	"""Игрок вышел из зоны взаимодействия"""
	if body.is_in_group("player"):
		player_nearby = false
		print("❌ Игрок отошел от ", stone_name)

func is_player_nearby() -> bool:
	"""Проверяет находится ли игрок рядом"""
	if is_destroyed:
		return false
	
	# Используем только область взаимодействия - она надежнее
	print("	Камень ", stone_name, " - игрок рядом: ", player_nearby)
	return player_nearby

func activate_stone():
	"""Активирует камень амулетом"""
	if is_destroyed:
		return
	
	print(stone_name, " активирован амулетом!")
	destroy_stone()

func destroy_stone():
	"""Уничтожает камень"""
	if is_destroyed:
		return
	
	is_destroyed = true
	print("💎 ", stone_name, " исчезает!")
	
	# Отключаем коллизию
	if collision:
		collision.disabled = true
	
	# Анимация исчезновения
	if sprite:
		var tween = create_tween()
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 1.0)
		tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 1.0)
		tween.tween_callback(queue_free)

# Убрали функцию show_magic_effect()

func force_destroy():
	"""Принудительно уничтожает камень (для тестирования)"""
	destroy_stone()
