extends TileMap

var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()

var chunck_size  = 8
var view_distance = 8
var chunck_genrated = 0
var chunck_genrated_bis = 0
var nbThread = 4

var generation_run = true
var chunk_to_generate = []
var chunk_to_generate_id = 0

var thread
var workerThread = []
var semaphore
var mutex
var mutex2
var chunck_gen_end = true
@onready var player = get_parent().get_child(1)

func _ready():
	#Init radom seed
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()
	altitude.frequency = 0.005
	
	#add monitor
	Performance.add_custom_monitor("Generation/Generated chunck", get_generated_chunk)
	Performance.add_custom_monitor("Generation/cgunck bis", get_generated_chunk_bis)
	Performance.add_custom_monitor("Generation/to generate", get_chunck_to_generate)
	
	#init multi thread
	semaphore = Semaphore.new()
	mutex = Mutex.new()
	mutex2 = Mutex.new()
	chunck_gen_end
	
	
	#generate first view
	generate_chunck_list()
	for c in range(chunk_to_generate.size()):
		generate_chunk(c)
	chunk_to_generate = []
	#Start main generation thread
	thread = Thread.new()
	#thread.start(gen_map_main_thread)
	
	#Start worker generation thread
	print("Start map generation with %d thread(s)"%nbThread)
	for i in range(0, nbThread):
		workerThread.append(Thread.new())
		workerThread[i].start(gen_map_worker_thread)


func _process(_delta):
	if chunck_gen_end:
		mutex2.lock()
		generate_chunck_list()
		mutex2.unlock()
	if Input.is_action_just_pressed("reload_tile_map"):
		print_debug("Force Reload!")
		force_update()

func generate_chunck_list():
	chunk_to_generate = []
	var player_position = player.position
	var tile_pos = local_to_map(player_position)
	var chunck_pos = tile_pos / chunck_size
	for xChunk in range(-view_distance,view_distance):
		for yChunk in range(-view_distance,view_distance):
			var local_chunk = Vector2i(chunck_pos.x + xChunk, chunck_pos.y+yChunk)
			if get_cell_tile_data(0, Vector2i(local_chunk.x*chunck_size, local_chunk.y*chunck_size)) == null:
				chunk_to_generate.append(local_chunk)
	
	if chunk_to_generate.size() > 0:
		chunck_gen_end = false
	

func generate_chunk(chunck_pos_id):
	if chunck_pos_id < 0:
		return
	var chunck_pos = chunk_to_generate[chunck_pos_id]
	if get_cell_tile_data(0, Vector2i(chunck_pos.x*chunck_size+1, chunck_pos.y*chunck_size+1)) == null:
		var generated_tiles = 0
		chunck_genrated += 1
		for x in range(chunck_size):
			for y in range(chunck_size):
				mutex.lock()
				var local_x = chunck_pos.x*chunck_size + x
				var local_y = chunck_pos.y*chunck_size + y
				
				var moist = moisture.get_noise_2d(local_x, local_y)*10
				var temp = temperature.get_noise_2d(local_x, local_y)*10
				var alt = altitude.get_noise_2d(local_x, local_y)*10
				
				
				if alt < 2:
					set_cell(0, Vector2i(local_x, local_y), 0, Vector2(3, round((temp+10)/5)))
				else:
					set_cell(0, Vector2i(local_x, local_y), 0, Vector2(round((moist+10)/5), round((temp+10)/5)))
				
				if get_cell_tile_data(0, Vector2i(local_x, local_y)) != null:
					generated_tiles += 1
				mutex.unlock()
		
		chunck_genrated_bis += 1
		if generated_tiles != chunck_size* chunck_size:
			print("Error in chunk: ", chunck_pos, " generated ", generated_tiles, " tiles of ", chunck_size* chunck_size)
		

func get_chunk_to_generate():
	if chunk_to_generate.size() == 0:
		chunck_gen_end = true
		return -1;
	else:
		var x = chunk_to_generate_id
		chunk_to_generate_id += 1
		if chunk_to_generate_id > chunk_to_generate.size():
			chunck_gen_end = true
			chunk_to_generate = []
			chunk_to_generate_id = 0
		return x

#foction used by thread
func gen_map_worker_thread():
	while generation_run:
		mutex2.lock()
		var id = get_chunk_to_generate()
		mutex2.unlock()
		generate_chunk(id)

#Stop thread when quit action
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		generation_run = false

#Fonction for custom monitor
func get_generated_chunk():
	return chunck_genrated

func get_chunck_to_generate():
	return chunk_to_generate.size()

func get_generated_chunk_bis():
	return chunck_genrated_bis
