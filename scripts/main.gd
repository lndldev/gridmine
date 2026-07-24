extends Node2D

@onready var terrain 	= $world/layer1
@onready var fog 		= $world/FogTileMap
@onready var target 	= $world/TargetTileMap

@onready var tick_sound 	= $world/tick_sound
@onready var break_sound 	= $world/break_sound

@onready var clear_target 	= $world/clear_target

@onready var camera 	= $Camera2D

var resources = {
	"stone" 	: 0,
	"copper" 	: 0,
	"gold"		: 0
}

const oob_coord = Vector2i(-1,-1)

const generic_stone_atlas 	= Vector2i(10,17) # to remove ? ?
const ground_atlas 	= Vector2i(19,1)
const target_atlas 	= Vector2i(30,14)
const fog_atlas 	= Vector2i(0,0)

var last_clicked_tile : Vector2i = oob_coord
var damage_to_tile = 0 
var tile_hp
const dmg = 1
var gathering_drop_rate = 1
var vision_range = 2



var dragging = false
var last_mouse_pos = Vector2i.ZERO

func _ready() -> void:
	set_camera_limits()
	update_all_vision()

func _process(delta: float) -> void:
	pass

func set_camera_limits() -> void :
	var used_rect = terrain.get_used_rect()
	var tile_size = terrain.tile_set.tile_size
	camera.limit_left = used_rect.position.x * tile_size.x
	camera.limit_top = used_rect.position.y * tile_size.y
	camera.limit_right = used_rect.end.x * tile_size.x
	camera.limit_bottom = used_rect.end.y * tile_size.y

func get_terrain_type(coords: Vector2i) -> String:
	return terrain.get_cell_tile_data(coords).get_custom_data("terrain_type")
	
func get_terrain_hp(coords: Vector2i) -> int:
	return terrain.get_cell_tile_data(coords).get_custom_data("hp")

func minable(coords : Vector2i) -> bool :
	#debatable if second condition might be redundant
	return is_block_minable(coords) and fog.get_cell_atlas_coords(coords) != fog_atlas and terrain.get_surrounding_cells(coords).any( func(cell) : return is_ground(cell) )


func zoom_in() -> void:
	var current_zoom = camera.zoom
	current_zoom *= 0.9 
	if current_zoom.x > 1 :
		camera.zoom = current_zoom
		
func zoom_out() -> void:
	var current_zoom = camera.zoom
	current_zoom *= 1.1 
	if current_zoom.x < 10 :
		camera.zoom = current_zoom

func init_camera_drag(event : InputEventMouseButton) -> void :
	dragging = event.pressed
	last_mouse_pos = event.position

func camera_drag(event : InputEventMouseMotion) -> void :
	var delta = event.position - last_mouse_pos
	camera.position -= delta / camera.zoom.x
	last_mouse_pos = event.position

func _input(event):
	if event.is_action_pressed("wheel_down"):
		zoom_in()
	if event.is_action_pressed("wheel_up"):
		zoom_out()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		init_camera_drag(event)
	elif event is InputEventMouseMotion	and dragging:
		camera_drag(event)
			
	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT :
		var clicked_tile_coords = terrain.local_to_map(get_global_mouse_position())
		if minable(clicked_tile_coords) : 
			minable_block_clicked(clicked_tile_coords)
		else : 
			print("nothing")


## no ui yet
func gain_block_resources(coords: Vector2i) -> void :
	var key = terrain.get_cell_tile_data(coords).get_custom_data("terrain_type")
	resources[key] += gathering_drop_rate
	print(resources)

func destroy_stone(coords : Vector2i) -> void :
	gain_block_resources(coords)
	terrain.set_cell(coords, 0, ground_atlas)
	target.clear()
	update_local_vision(coords)
	
func update_local_vision(coords : Vector2i) -> void :
	var tiles_to_show : Array[Vector2i]
	for neighbor in get_neighbour_coords(coords) : 
			if is_ground(neighbor)== false :
				tiles_to_show.append(neighbor)
	lift_fog(tiles_to_show)

func reset_target() -> void:
	damage_to_tile = 0
	target.clear()
	last_clicked_tile = oob_coord

## the idea is that only one block is damages at one given time
# we know it is not compatible with potential AOE damage but we don't think we want it for now ?
# i have an idea of how i would need to manage AOE, even tho it is not that easy
## basic chain of events : 
# when new block is clicked : reset damage, get max hp for specific terrain, and add a visual cue (target) to mark mined terrain
# in any case damage stacked until terrain broken
func minable_block_clicked(clicked_tile_coords : Vector2i):
	if clicked_tile_coords != last_clicked_tile  : 
		reset_target()
		tile_hp = get_terrain_hp(clicked_tile_coords)
		target.set_cell(clicked_tile_coords, 0, target_atlas,1)
		last_clicked_tile = clicked_tile_coords

	damage_to_tile += dmg
	if(damage_to_tile >= tile_hp):
		destroy_stone(clicked_tile_coords)
		break_sound.play()
	else:
		tile_hp = get_terrain_hp(clicked_tile_coords)
		tick_sound.play()
		clear_target.start()

func is_ground(coords : Vector2i) -> bool :
	return get_terrain_type(coords) == "ground"

func is_block_minable(coords : Vector2i) -> bool :
	return terrain.get_cell_tile_data(coords).get_custom_data("minable")

## custom function to get 8 neighbors instead of 4
## also allows for extended vision
func get_neighbour_coords(origin: Vector2i) -> Array[Vector2i] : 
	var neighbours : Array[Vector2i]
	for i in range(-vision_range, vision_range+1):
		for j in range(-vision_range, vision_range+1):
			var coord = Vector2i(origin.x + i, origin.y + j)
			neighbours.append(coord)
	return neighbours


func get_all_tiles_to_show() -> Array[Vector2i] :
	var groundCellsCoords :Array[Vector2i] = terrain.get_used_cells_by_id(0, ground_atlas)
	var tilesToShow :Array[Vector2i]
	for groundCell in groundCellsCoords:
		tilesToShow.append(groundCell)
		for neighbor in get_neighbour_coords(groundCell) : 
			if is_ground(neighbor)== false :
				tilesToShow.append(neighbor)
	return tilesToShow

## for is the third layer, opaque, above all, disapearing tile by tile to reveal terrain
func lift_fog(tilesToShow : Array[Vector2i]):
	for tile in tilesToShow:
		fog.erase_cell(tile)

##only runs at setup (with get_all_tiles_to_show)
## idea is : we look for all ground tiles, all their neighbors then show them
## later in game, we only show tiles neighboring the ones juste destroyed
## might need adjustment if player is eventually able to build walls and such
func update_all_vision():
	var tiles_to_show = get_all_tiles_to_show()
	lift_fog(tiles_to_show)

func _on_clear_target_timeout() -> void:
	reset_target()
