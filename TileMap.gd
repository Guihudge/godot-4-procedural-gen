extends TileMap

var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()

var chunck_size  = 32
var view_distance = 8
var chunck_genrated = 0

var thread
@onready var player = get_parent().get_child(1)

func _ready():
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()
	altitude.frequency = 0.005
	Performance.add_custom_monitor("Generation/Generated chunck", get_generated_chunk)
	thread = Thread.new()
	thread.start(generate_chunck_in_view)


func _process(delta):
	if not thread.is_alive():
		thread.wait_to_finish()
		thread.start(generate_chunck_in_view)

func generate_chunck_in_view():
	var position = player.position
	var tile_pos = local_to_map(position)
	var chunck_pos = tile_pos / chunck_size
	for xChunk in range(-view_distance,view_distance):
		for yChunk in range(-view_distance,view_distance):
			var local_chunk = Vector2i(chunck_pos.x + xChunk, chunck_pos.y+yChunk)
			generate_chunk(local_chunk)
	

func generate_chunk(chunck_pos):
	if get_cell_tile_data(0, Vector2i(chunck_pos.x*chunck_size, chunck_pos.y*chunck_size)) == null:
		chunck_genrated += 1
		for x in range(chunck_size):
			for y in range(chunck_size):
				var local_x = chunck_pos.x*chunck_size + x
				var local_y = chunck_pos.y*chunck_size + y
				
				var moist = moisture.get_noise_2d(local_x, local_y)*10
				var temp = temperature.get_noise_2d(local_x, local_y)*10
				var alt = altitude.get_noise_2d(local_x, local_y)*10
					
				if alt < 2:
					set_cell(0, Vector2i(local_x, local_y), 0, Vector2(3, round((temp+10)/5)))
				else:
					set_cell(0, Vector2i(local_x, local_y), 0, Vector2(round((moist+10)/5), round((temp+10)/5)))

func dummy():
	var x = 1+1

func get_generated_chunk():
	return chunck_genrated
