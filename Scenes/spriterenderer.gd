
extends Node3D


enum RENDERMODE {ANIMATION, MODEL}

@export_category("General Settings")
@export var mode: RENDERMODE

@export_category("Spritesheet Settings")
@export var export_as_spritesheet: bool = false
@export var width: int = 0
@export var height: int = 0

@export_category("Export settings")
@export var render_angle: float
@export_dir var save_folder
@export var save_name: String
enum ROTATIONDIRECTION {CLOCKWISE, ANTICLOCKWISE}
@export var rotation_direction : ROTATIONDIRECTION


@export_category("Model & Animation Settings")
@export var model: Node3D
@export var model_animation_player: AnimationPlayer
@export var animation_frames: int = 30
@export var animation_duration: float

#Spritesheet vars
@onready var subviewportcontainer = $SubViewportContainer
@onready var subviewport = $SubViewportContainer/SubViewport
@onready var spritesheet = $SubViewportContainer/SubViewport/Spritesheet
@onready var sprite_size = get_viewport().get_visible_rect().size
@onready var spritesheet_width = sprite_size.x * width
@onready var spritesheet_height = sprite_size.y * height

#Render vars
@onready var number_of_angles_to_render: int = 360.0 / render_angle
@onready var render_viewport = get_viewport()
var angles_rendered: int = 0
var frames_rendered: int = 0
var sprite_dict: Dictionary
signal spritesheet_rendered

func set_up_spritesheet() -> void:
	#set the size of the subviewport according to the defined spritesheet and sprite size (project settings)
	subviewport.size = Vector2(spritesheet_width, spritesheet_height)
	#The sprites are stored within a grid container. Set the amount of columns according to the defined width
	spritesheet.columns = width
	
	#add texture_rects to the grid container. These hold the individual sprites.
	var num_of_sprite = 0
	if mode == RENDERMODE.MODEL:
		for i in width * height:
			var texture_rect = TextureRect.new()
			texture_rect.name = str(num_of_sprite)
			spritesheet.add_child(texture_rect)
			num_of_sprite += 1
	
	if mode == RENDERMODE.ANIMATION:
		#if width*height == animation_frames:
			print("fits")
			for i in width * height:
				var texture_rect = TextureRect.new()
				texture_rect.name = str(num_of_sprite)
				spritesheet.add_child(texture_rect)
				num_of_sprite += 1
		#else:
			#for i in animation_frames * animation_duration:
				#var texture_rect = TextureRect.new()
				#texture_rect.name = str(num_of_sprite)
				#spritesheet.add_child(texture_rect)
				#num_of_sprite += 1
	
func render_spritesheet(_spritedict: Dictionary, _angle_rendered) -> void:
	
		for key in _spritedict:
			var frame = spritesheet.get_node(str(key))
			var sprite = _spritedict[key]
			frame.texture = sprite
			
		if save_name && save_folder:
			subviewportcontainer.visible = true
			
			if mode == RENDERMODE.MODEL:
				await RenderingServer.frame_post_draw
				var save_string = str(save_folder + "/" + save_name + ".png")
				var finished_spritesheet = subviewport.get_texture().get_image()
				print("finished sheet:", finished_spritesheet)
				finished_spritesheet.save_png(save_string)
				spritesheet_rendered.emit()
				
			elif mode == RENDERMODE.ANIMATION:
				await RenderingServer.frame_post_draw
				var save_string = str(save_folder + "/" + save_name + str(angles_rendered) + ".png")
				var finished_spritesheet = subviewport.get_texture().get_image()
				print("finished sheet animation:", finished_spritesheet)
				finished_spritesheet.save_png(save_string)
				spritesheet_rendered.emit()
				
	
		#if mode == RENDERMODE.MODEL:
			#var num_needed_sprite_containers = 360 / render_angle
			#var err_msg = "Spritesheet not configured correctly. Check if width and height match the required amount: {amn}.".format({"amn": num_needed_sprite_containers})
			#push_error(err_msg)
		#if mode == RENDERMODE.ANIMATION:
			#var num_needed_sprite_containers = roundi(animation_frames * animation_duration)
			#var err_msg = "Spritesheet not configured correctly. Check if width and height match the required amount: {amn}.".format({"amn": num_needed_sprite_containers})
			#push_error(err_msg)
		#get_tree().quit()
		
func rotate_model(_angle) -> void:
	if rotation_direction == ROTATIONDIRECTION.CLOCKWISE:
		var rotation_angle = deg_to_rad(_angle)
		model.rotate_y(-rotation_angle)
	if rotation_direction == ROTATIONDIRECTION.ANTICLOCKWISE:
		var rotation_angle = deg_to_rad(_angle)
		model.rotate_y(rotation_angle)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var names = model_animation_player.get_animation_list()
	print(names[0])
	model_animation_player.play(names[3])
	print(number_of_angles_to_render)
	if export_as_spritesheet:
		set_up_spritesheet()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if mode == RENDERMODE.MODEL:
		print(angles_rendered)
		if export_as_spritesheet:
			
			if angles_rendered < number_of_angles_to_render:
				print(angles_rendered)
				await RenderingServer.frame_post_draw
				var raw_sprite = render_viewport.get_texture().get_image()
				var sprite = ImageTexture.create_from_image(raw_sprite)
				sprite_dict[angles_rendered] = sprite
				angles_rendered += 1
				rotate_model(render_angle)
			
			if angles_rendered >= number_of_angles_to_render:
				print(sprite_dict)
				render_spritesheet(sprite_dict, null)
				await spritesheet_rendered
				get_tree().quit()
			
		else:
			if angles_rendered < number_of_angles_to_render:
				print(angles_rendered)
				await RenderingServer.frame_post_draw
				var sprite = render_viewport.get_texture().get_image()
				var save_string = str(save_folder + "/" + save_name + str(angles_rendered) + ".png")
				var finished_spritesheet = subviewport.get_texture().get_image()
				print("finished sheet model single:", finished_spritesheet)
				sprite.save_png(save_string)
				angles_rendered += 1
				rotate_model(render_angle)
			
			if angles_rendered >= number_of_angles_to_render:
				get_tree().quit()
			
			
	if mode == RENDERMODE.ANIMATION:
		Engine.max_fps = animation_frames
		var number_frames_to_render = roundi(animation_frames * animation_duration) 
		if export_as_spritesheet:
			if angles_rendered < number_of_angles_to_render:
				if frames_rendered < number_frames_to_render:
					await RenderingServer.frame_post_draw
					var raw_sprite = render_viewport.get_texture().get_image()
					var sprite = ImageTexture.create_from_image(raw_sprite)
					print(frames_rendered)
					sprite_dict[frames_rendered] = sprite
					frames_rendered += 1
				elif frames_rendered == number_frames_to_render:
					frames_rendered = 0
					render_spritesheet(sprite_dict, angles_rendered)
					await spritesheet_rendered
					subviewportcontainer.visible = false
					sprite_dict.clear()
					angles_rendered += 1
					rotate_model(render_angle)
			if angles_rendered >= number_of_angles_to_render:
				get_tree().quit()
		else: 
			#exporting single animation frames is not implemented
			pass
