extends Node2D

# Authored layout in tile coordinates; no random or procedural room generation.
const CENTERS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(10, 0), Vector2i(0, 10), Vector2i(10, 10), Vector2i(20, 10), Vector2i(30, 10)]
const LINKS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 4), Vector2i(4, 5)]

func _ready() -> void:
	var floor: TileMapLayer = $Floor as TileMapLayer
	var cells: Dictionary = {}
	for center: Vector2i in CENTERS:
		for x: int in range(-3, 4):
			for y: int in range(-3, 4):
				cells[center + Vector2i(x, y)] = true
	for link: Vector2i in LINKS:
		var a: Vector2i = CENTERS[link.x]
		var b: Vector2i = CENTERS[link.y]
		for step: int in range(11):
			for width: int in range(-1, 2):
				var cell: Vector2i = a + Vector2i(step, width) if a.y == b.y else a + Vector2i(width, step)
				cells[cell] = true
	for cell: Vector2i in cells:
		floor.set_cell(cell, 0, Vector2i(posmod(cell.x + cell.y, 4), 0))
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	var vertices: Array[Vector2] = [Vector2(64, 0), Vector2(0, 32), Vector2(-64, 0), Vector2(0, -32)]
	for cell: Vector2i in cells:
		for edge: int in range(4):
			if cells.has(cell + offsets[edge]):
				continue
			var a: Vector2 = floor.map_to_local(cell) + vertices[edge]
			var b: Vector2 = floor.map_to_local(cell) + vertices[(edge + 1) % 4]
			var wall: StaticBody2D = StaticBody2D.new()
			var collision: CollisionShape2D = CollisionShape2D.new()
			var segment: SegmentShape2D = SegmentShape2D.new()
			segment.a = a
			segment.b = b
			collision.shape = segment
			wall.add_child(collision)
			$Walls.add_child(wall)
			var line: Line2D = Line2D.new()
			line.points = PackedVector2Array([a, b])
			line.width = 7.0
			line.default_color = Color(0.35, 0.45, 0.5)
			wall.add_child(line)
