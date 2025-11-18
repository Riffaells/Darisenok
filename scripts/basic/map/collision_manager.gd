extends Node2D

@onready var tile_map_layer = $TileMapLayer

func _ready():
	setup_tile_collisions()

func setup_tile_collisions():
	"""
	Настраивает коллизии для разных типов тайлов
	"""
	var tile_set = tile_map_layer.tile_set

	# Получаем источники тайлов
	for source_id in tile_set.get_source_count():
		var source = tile_set.get_source(source_id)
		if source is TileSetAtlasSource:
			setup_atlas_collisions(source, source_id)

func setup_atlas_collisions(atlas_source: TileSetAtlasSource, source_id: int):
	"""
	Настраивает коллизии для атласа тайлов
	"""
	# Проходим по всем тайлам в атласе
	for i in range(atlas_source.get_texture_region_size().x / atlas_source.texture_region_size.x):
		for j in range(atlas_source.get_texture_region_size().y / atlas_source.texture_region_size.y):
			var atlas_coords = Vector2i(i, j)

			# Проверяем, есть ли тайл в этих координатах
			if atlas_source.has_tile(atlas_coords):
				setup_tile_collision(atlas_source, atlas_coords, source_id)

func setup_tile_collision(atlas_source: TileSetAtlasSource, atlas_coords: Vector2i, source_id: int):
	"""
	Настраивает коллизию для конкретного тайла
	"""
	# Определяем тип тайла и добавляем коллизию
	match source_id:
		0: # Основные тайлы местности
			setup_terrain_collision(atlas_source, atlas_coords)
		1: # Структуры (дома)
			setup_structure_collision(atlas_source, atlas_coords)
		2: # Объекты (деревья, камни)
			setup_object_collision(atlas_source, atlas_coords)

func setup_terrain_collision(atlas_source: TileSetAtlasSource, atlas_coords: Vector2i):
	"""
	Настраивает коллизии для тайлов местности
	"""
	# Вода - непроходима
	if atlas_coords.x >= 7 and atlas_coords.x <= 10 and atlas_coords.y == 0:
		add_full_collision(atlas_source, atlas_coords)

	# Камни/булыжник - непроходимы
	if atlas_coords.y >= 4 and atlas_coords.y <= 6:
		add_full_collision(atlas_source, atlas_coords)

func setup_structure_collision(atlas_source: TileSetAtlasSource, atlas_coords: Vector2i):
	"""
	Настраивает коллизии для структур (домов)
	"""
	# Все структуры непроходимы
	add_full_collision(atlas_source, atlas_coords)

func setup_object_collision(atlas_source: TileSetAtlasSource, atlas_coords: Vector2i):
	"""
	Настраивает коллизии для объектов (деревья, камни)
	"""
	# Большинство объектов непроходимы
	add_full_collision(atlas_source, atlas_coords)

func add_full_collision(atlas_source: TileSetAtlasSource, atlas_coords: Vector2i):
	"""
	Добавляет полную коллизию к тайлу
	"""
	# Создаём физический слой если его нет
	var tile_data = atlas_source.get_tile_data(atlas_coords, 0)

	# Добавляем коллизионный полигон (полный квадрат)
	var collision_polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(16, 0),
		Vector2(16, 16),
		Vector2(0, 16)
	])

	tile_data.set_collision_polygons_count(0, 1)
	tile_data.set_collision_polygon_points(0, 0, collision_polygon)

# Функция для создания динамических препятствий
func create_obstacle(pos: Vector2, size: Vector2):
	"""
	Создаёт динамическое препятствие
	"""
	var obstacle = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	shape.size = size
	collision.shape = shape
	obstacle.add_child(collision)

	obstacle.global_position = pos
	add_child(obstacle)

	return obstacle

# Функция для создания разрушаемой стены
func create_destructible_wall(pos: Vector2, size: Vector2):
	"""
	Создаёт разрушаемую стену
	"""
	var wall = RigidBody2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var sprite = Sprite2D.new()

	# Настраиваем физику
	wall.gravity_scale = 0
	wall.lock_rotation = true

	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	wall.add_child(sprite)

	wall.global_position = pos
	add_child(wall)

	# Добавляем функцию разрушения
	# wall.set_script(preload("res://scripts/basic/objects/destructible_wall.gd"))

	return wall
