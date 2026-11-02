extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var data: MapDefinition = load("res://data/maps/map_01.tres") as MapDefinition
	if data == null:
		push_error("Primeiro mapa deve existir")
		quit(1)
		return
	assert(data.validate_first_map().is_empty())
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	var session: AdventureSession = game.adventure_session
	var player: PlayerController = game.player
	player.health.apply_damage(10)
	player.apply_upgrade(load("res://data/upgrades/damage.tres") as UpgradeDefinition)
	var identity: int = player.get_instance_id()
	assert(session.mount_definition(data) == OK)
	var map: Node2D = session.current_map
	assert(map.get_node("Rooms").get_child_count() == 6)
	assert(map.get_node("Doors").get_child_count() == 6)
	var floor: TileMapLayer = map.get_node("Floor") as TileMapLayer
	assert(floor.tile_set.tile_size == Vector2i(128, 64) and floor.get_used_cells().size() > 300)
	var director: RoomDirector = game.room_director
	var door: Node = map.get_node("Doors/Door01")
	assert(not door.is_open)
	await process_frame
	for enemy: EnemyController in director.controllers[&"R01"].active_enemies.duplicate():
		enemy.health.apply_damage(enemy.health.current)
	var upgrades: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	for frame: int in range(10):
		if upgrades.has_pending_choices():
			upgrades.select_upgrade(upgrades.current_offer[0].upgrade_id)
		await process_frame
	await physics_frame
	assert(door.is_open)
	var health_before: int = player.health.current
	var damage_before: int = player.runtime_stats.effective_damage()
	player.global_position = director.controllers[&"R02A"].global_position
	await physics_frame
	await physics_frame
	assert(director.current_room_id == &"R02A")
	assert(player.get_instance_id() == identity and player.health.current == health_before and player.runtime_stats.effective_damage() == damage_before)
	assert(not map.get_node("Doors/Door02").is_open)
	print("Adventure map smoke: OK")
	quit()
