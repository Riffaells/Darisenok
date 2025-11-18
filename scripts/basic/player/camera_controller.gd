extends Camera2D

@export var follow_speed: float = 5.0
@export var camera_offset: Vector2 = Vector2.ZERO
@export var look_ahead_distance: float = 80.0
@export var look_ahead_speed: float = 2.0
@export var deadzone_size: Vector2 = Vector2(30, 20)
@export var max_distance: float = 150.0
@export var velocity_smoothing: float = 0.1

var target: Node2D
var last_target_position: Vector2
var look_ahead_offset: Vector2 = Vector2.ZERO
var smoothed_velocity: Vector2 = Vector2.ZERO

func _ready():
	# Находим игрока
	target = get_tree().root.find_child("player", true, false)
	if target:
		# Устанавливаем начальную позицию
		global_position = target.global_position + camera_offset
		last_target_position = target.global_position

func _physics_process(delta):
	if not target:
		return
	
	var target_pos = target.global_position
	var current_velocity = (target_pos - last_target_position) / delta
	last_target_position = target_pos
	
	# Сглаживаем скорость для более плавного поведения камеры
	smoothed_velocity = smoothed_velocity.lerp(current_velocity, velocity_smoothing)
	
	# Вычисляем look-ahead offset на основе сглаженной скорости игрока
	var desired_look_ahead = Vector2.ZERO
	if smoothed_velocity.length() > 20.0:  # Только если игрок движется достаточно быстро
		desired_look_ahead = smoothed_velocity.normalized() * look_ahead_distance
	
	# Плавно изменяем look-ahead offset
	look_ahead_offset = look_ahead_offset.lerp(desired_look_ahead, look_ahead_speed * delta)
	
	# Целевая позиция камеры
	var target_camera_pos = target_pos + camera_offset + look_ahead_offset
	
	# Простое плавное следование без deadzone для более предсказуемого поведения
	global_position = global_position.lerp(target_camera_pos, follow_speed * delta)

# Функция для встряхивания камеры (для атак, взрывов и т.д.)
func shake_camera(intensity: float, duration: float):
	var tween = create_tween()
	var original_offset = offset
	
	for i in range(int(duration * 60)):  # 60 FPS
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(self, "offset", original_offset + shake_offset, 1.0/60.0)
	
	tween.tween_property(self, "offset", original_offset, 0.1)

# Функция для плавного зума
func smooth_zoom(target_zoom: Vector2, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(self, "zoom", target_zoom, duration)

# Функция для временного фокуса на точке
func focus_on_point(point: Vector2, duration: float = 2.0):
	var tween = create_tween()
	var original_follow_speed = follow_speed
	
	# Временно отключаем следование за игроком
	follow_speed = 0.0
	
	# Двигаем камеру к точке
	tween.tween_property(self, "global_position", point, duration * 0.3)
	tween.tween_delay(duration * 0.4)
	
	# Возвращаем камеру к игроку
	if target:
		tween.tween_property(self, "global_position", target.global_position + camera_offset, duration * 0.3)
	
	# Восстанавливаем следование
	tween.tween_callback(func(): follow_speed = original_follow_speed)
