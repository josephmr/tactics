extends Node2D


@export var highlight_tile: PackedScene

@onready var unit: Node2D = $Unit
@onready var tiles: TileMap = $Tiles
@onready var select_tile: Node2D = $SelectTile

var grid: AStarGrid2D
var unit_path = []

func _ready() -> void:
	grid = AStarGrid2D.new()
	var rect = tiles.get_used_rect()
	grid.region = rect
	grid.cell_size = Vector2(32, 32)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()

func _unit_tile() -> Vector2i:
	return tiles.local_to_map(unit.position)

func _mouse_tile() -> Vector2i:
	return tiles.local_to_map(get_local_mouse_position())

func _get_id_path_to_mouse() -> Array[Vector2i]:
	var mouse_tile = _mouse_tile()
	if not tiles.get_used_rect().has_point(mouse_tile):
		return []
	return grid.get_id_path(_unit_tile(), mouse_tile)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("move") and unit_path.is_empty():
		unit_path = _get_id_path_to_mouse()

func _get_highlight_tiles(num: int) -> Array[Node]:
	var highlight_tiles = get_tree().get_nodes_in_group("highlight_tile")
	if highlight_tiles.size() > num:
		highlight_tiles.slice(num).map(func(t): t.queue_free())
		return highlight_tiles.slice(0, num)
	elif highlight_tiles.size() < num:
		var needed = num - highlight_tiles.size()
		var highlight_layer = get_tree().get_first_node_in_group("highlight_layer")
		for i in needed:
			var tile = highlight_tile.instantiate()
			highlight_layer.add_child(tile)
		return get_tree().get_nodes_in_group("highlight_tile")
	else:
		return highlight_tiles

func _paint_path() -> void:
	var path = unit_path
	if unit_path.is_empty():
		path = _get_id_path_to_mouse().map(func(tile): return tiles.map_to_local(tile))
	if path.size() <= 2:
		_get_highlight_tiles(0)
		return
	# don't paint current tile or mouse tile (which is the select)
	path.pop_back()
	path.pop_front()
	var highlight_tiles = _get_highlight_tiles(path.size())
	for i in path.size():
		highlight_tiles[i].position = path[i]

func _paint_select() -> void:
	var mouse_tile = _mouse_tile()
	var local_position = tiles.map_to_local(mouse_tile)
	select_tile.position = local_position

func _process(delta: float) -> void:
	if unit_path.is_empty():
		_paint_path()
		_paint_select()
		return
	var next_point = tiles.map_to_local(unit_path[0])
	if unit.global_position.distance_squared_to(next_point) < 1:
		unit.global_position = next_point
		unit_path.remove_at(0)
		return
	unit.global_position = unit.global_position.lerp(next_point, 1 - exp(-5 * delta))
	
