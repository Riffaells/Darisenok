extends Area2D
class_name Portal

# Портал для телепортации между уровнями

@export var target_scene: String = "res://scenes/levels/game_level_2.tscn"
@export var portal_name: String = "Портал"

var player_nearby: bool = false

func _ready():
	# Настраиваем сигналы
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("Портал создан: ", portal_name, " -> ", target_scene)

func _on_body_entered(body):
	"""Игрок вошел в портал"""
	if body.is_in_group("player"):
		player_nearby = true
		print("Игрок подошел к порталу. Нажмите E для телепортации")

func _on_body_exited(body):
	"""Игрок вышел из портала"""
	if body.is_in_group("player"):
		player_nearby = false

func _input(event):
	"""Обрабатывает активацию портала"""
	if player_nearby and event.is_action_pressed("use_item"):
		teleport()

func teleport():
	"""Телепортирует игрока на другой уровень"""
	print("🌀 Телепортация через портал на: ", target_scene)
	get_tree().change_scene_to_file(target_scene)