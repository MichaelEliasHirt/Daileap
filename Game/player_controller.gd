extends CharacterBody2D
class_name PlayerController

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var particles_on_player_sprite: AnimatedSprite2D = $ParticlesOnPlayerSprite

@onready var run_particle_gen: CPUParticles2D = $ParticleGenerators/RunParticleGen
@onready var wallslide_particle_gen: CPUParticles2D = $ParticleGenerators/WallslideParticleGen
@onready var jump_particle_gen: CPUParticles2D = $ParticleGenerators/JumpParticleGen
@onready var world_position_particle_generators: Node2D = %WorldPositionParticleGenerators

# --- EXPORTED MOVEMENT & PHYSICS PARAMETERS ---

@export_category("Necesary Child Nodes")
@export var player_sprite: AnimatedSprite2D
@export var player_collider: CollisionShape2D

@export_category("L/R Movement")
##The max speed your player will move
@export_range(50, 500) var max_speed: float = 100.0
##How fast your player will reach max speed from rest (in seconds)
@export_range(0, 4) var time_to_reach_max_speed: float = 0.05
##How fast your player will reach zero speed from max speed (in seconds)
@export_range(0, 4) var time_to_reach_zero_speed: float = 0.2
##If true, player will instantly move and switch directions. Overrides the "timeToReach" variables, setting them to 0.
@export var directional_snap: bool = true

#INFO JUMPING
@export_category("Jumping and Gravity")
##The peak height of your player's jump
@export_range(0, 20) var jump_height: float = 2.
##How many jumps your character can do before needing to touch the ground again. Giving more than 1 jump disables jump buffering and coyote time.
@export_range(0, 100) var gravity_scale: float = 20.0
##The fastest your player can fall
@export_range(0, 1000) var terminal_velocity: float = 500.0
##Your player will move this amount faster when falling providing a less floaty jump curve.
@export_range(0.5, 3) var descending_gravity_factor: float = 1.05
##Enabling this toggle makes it so that when the player releases the jump key while still ascending, their vertical velocity will cut in half, providing variable jump height.

@export_range(0, 0.5) var coyote_time: float = 0.1

#INFO EXTRAS
@export_category("Wall Jumping")
##The player's gravity will be divided by this number when touch a wall and descending. Set to 1 by default meaning no change will be made to the gravity and there is effectively no wall sliding. THIS IS OVERRIDDED BY WALL LATCH.
@export_range(1, 20) var wall_sliding: float = 4.0

@export_category("Dashing")
##How far the player will dash. One of the dashing toggles must be on for this to be used.
@export_range(0.5, 10) var dash_length: float = 2.0
@export_range(1,5) var dash_speed: float = 2.0

@export_category("Drop Through")
@export_range(0.05,0.5) var drop_through_time: float = 0.1


@export_category("Animations (Check Box if has animation)")
##Animations must be named "idle" all lowercase as the check box says
@export var idle: bool = true
##Animations must be named "walk" all lowercase as the check box says
@export var walk: bool = true
##Animations must be named "slide" all lowercase as the check box says
@export var slide: bool = true


signal dash_indicator_on
signal dash_indicator_off

#Variables determined by the developer set ones.

var move_right := true
var move_left := false
var drop_straight := false
var wall_jump := false

var applied_gravity: float
var max_speed_lock: float
var applied_terminal_velocity: float

var friction: float
var acceleration: float
var deceleration: float
var instant_accel: bool = false
var instant_stop: bool = false

var jump_magnitude: float = 500.0
var jump_was_pressed: bool = false
var coyote_active: bool = false
var dash_magnitude: float
var gravity_active: bool = true
var dashing: bool = false
var dashing_up: bool = false
var dashing_down: bool = false
var dashing_left: bool = false
var dashing_right: bool = false


var jumped: bool = false

var dropping_through: bool = false

var was_moving_r: bool
var was_pressing_r: bool
var movement_input_monitoring: Vector2 = Vector2(true, true) #movementInputMonitoring.x addresses right direction while .y addresses left direction

var gdelta: float = 1

var dset = false

var collider_scale_lock_y
var collider_pos_lock_y

var was_on_wall = false
var was_on_floor = false


var anim: AnimatedSprite2D
var col
var anim_scale_lock : Vector2

var is_in_tight_spot: bool
@export var is_in_tight_spot_min_frames := 5
var is_in_tight_spot_frames := 0

#Input Variables for the whole script
var swipe_up
var swipe_down
var swipe_left
var swipe_right
var press
var hold
var still_hold

var is_walking: bool = true
var is_falling: bool = false
var is_wall_sliding: bool = false
var is_jumping: bool = false
var is_dashing: bool = false



var double_jump: bool = true
var dash: bool = true:
	set(value):
		if dash != value:
			if not value:
				dash_indicator_off.emit()
			else: dash_indicator_on.emit()
		dash = value


func _ready():

	was_moving_r = true
	anim = player_sprite
	col = player_collider
	
	_update_data()
	
	for generator in get_tree().get_nodes_in_group("GlobalParticleGenerator"):
		generator.get_parent().remove_child(generator)


func _update_data():
	acceleration = max_speed / time_to_reach_max_speed
	deceleration = -max_speed / time_to_reach_zero_speed
	
	jump_magnitude = (10.0 * jump_height) * gravity_scale
	
	dash_magnitude = max_speed * dash_length * dash_speed
	
	max_speed_lock = max_speed
	
	anim_scale_lock = abs(anim.scale)
	collider_scale_lock_y = col.scale.y
	collider_pos_lock_y = col.position.y
	
	if time_to_reach_max_speed == 0:
		instant_accel = true
		time_to_reach_max_speed = 1
	elif time_to_reach_max_speed < 0:
		time_to_reach_max_speed = abs(time_to_reach_max_speed)
		instant_accel = false
	else:
		instant_accel = false
		
	if time_to_reach_zero_speed == 0:
		instant_stop = true
		time_to_reach_zero_speed = 1
	elif time_to_reach_max_speed < 0:
		time_to_reach_max_speed = abs(time_to_reach_max_speed)
		instant_stop = false
	else:
		instant_stop = false
		
	
	coyote_time = abs(coyote_time)
	
	if directional_snap:
		instant_accel = true
		instant_stop = true
		
	


func _process(_delta):

	if ray_cast_right.is_colliding() and ray_cast_left.is_colliding():
		is_in_tight_spot_frames += 1
		if is_in_tight_spot_frames >= is_in_tight_spot_min_frames:
			is_in_tight_spot = true
	else:
		is_in_tight_spot_frames = 0
		is_in_tight_spot = false
	
	instant_stop = false
	instant_accel = false
	#INFO animations
	if move_right:
		anim.scale.x = anim_scale_lock.x
		$ParticleGenerators.scale.x = 1
		particles_on_player_sprite.scale.x = anim_scale_lock.x
		
	elif move_left:
		anim.scale.x = anim_scale_lock.x * -1
		$ParticleGenerators.scale.x = -1
		particles_on_player_sprite.scale.x = anim_scale_lock.x * -1
		
	if is_wall_sliding:
		if velocity.y > 0 and slide and wall_sliding != 1:
			anim.speed_scale = 1
			anim.play("wallslide")
			_stop_all_particles()
			wallslide_particle_gen.emitting = true
			was_on_wall = true
	
	else:
		if is_walking:
			if idle and walk and !dashing:
				if abs(velocity.x) > 0.1 and is_on_floor() and !is_on_wall():
					#anim.speed_scale = abs(velocity.x / 150)
					anim.play("run")
					_stop_all_particles()
					run_particle_gen.emitting = true
					
			was_on_wall = false
		else:
			if is_jumping:
				
				if was_on_wall:
					if anim.animation != "jump_up_wall":
						anim.speed_scale = 1
						anim.play("jump_up_wall")
						_stop_all_particles()
					
				elif anim.animation != "jump_up":
					
					anim.speed_scale = 1
					anim.play("jump_up")
					_stop_all_particles()
				
			elif is_falling and anim.animation != "jump_down":
				anim.speed_scale = 1
				anim.play("jump_down")
				_stop_all_particles()
		
	if is_dashing:
		anim.speed_scale = 1
		anim.play("dash")
		_stop_all_particles()


func _emit_jump_particle():
	var new_particle_gen = jump_particle_gen.duplicate()
	world_position_particle_generators.add_child(new_particle_gen)
	new_particle_gen.global_position = global_position + jump_particle_gen.position
	new_particle_gen.emitting = true
	
	new_particle_gen.connect("finished",new_particle_gen.queue_free)


func _stop_all_particles():
	for generator in get_tree().get_nodes_in_group("ParticleGenerator"):
		generator.emitting = false


func _physics_process(delta):

	press = TouchInputHandler.just_tapped
	swipe_left = TouchInputHandler.just_swiped_left
	swipe_right = TouchInputHandler.just_swiped_right
	swipe_up = TouchInputHandler.just_swiped_up
	swipe_down = TouchInputHandler.just_swiped_down
	
	if is_walking:	
		drop_straight = false
		if not is_on_floor():
			is_walking = false
			is_falling = true	
		else:
			if is_on_wall():
				change_direction(null)
				
			else:
				if swipe_left:
					change_direction(false)
				elif swipe_right:
					change_direction(true)
			if swipe_down:
				_drop_through()
	
	if is_falling:
		if is_on_floor():
			is_falling = false
			is_walking = true
		else:
			if is_on_wall():
				is_falling = false
				is_wall_sliding = true
			else:
				if velocity.y < 0:
					is_falling = false
					is_jumping = true
	
	if is_jumping:
		drop_straight = false
		if is_on_wall() and not wall_jump:
			is_jumping = false
			is_wall_sliding = true
		else:
			if velocity.y > 0:
				is_jumping = false
				is_falling = true
		wall_jump = false
	
	if is_wall_sliding:
		drop_straight = false
		if is_on_floor():
			is_wall_sliding = false
			is_walking = true
		else:
			if not is_on_wall() and velocity.y > 0:
				is_wall_sliding = false
				is_falling = true
				drop_straight = true
				change_direction(null)
	
	if is_dashing:
		drop_straight = false
		if is_on_floor():
			is_dashing = false
			is_walking = true
		else:
			if is_on_wall():
				is_dashing = false
				is_wall_sliding = true
	
	# When the player is droping off a wall
	if drop_straight:
		velocity.x = 0
		
	elif is_wall_sliding:
		if move_right:
			velocity.x = 1
		elif move_left:
			velocity.x = -1
	else:
		# Movement left/right
		if not is_dashing:
			if move_right:
				if velocity.x > max_speed:
					velocity.x = max_speed
				else:
					velocity.x += acceleration * delta
			
			elif move_left:
				if velocity.x < -max_speed:
					velocity.x = -max_speed
				else:
					velocity.x -= acceleration * delta
	
	
	## Gravity
	if velocity.y > 0:
		applied_gravity = gravity_scale * descending_gravity_factor
	else:
		applied_gravity = gravity_scale
	#
	if is_wall_sliding:
		# Stop sliding upwarts on walls
		if velocity.y < 0:	
			velocity.y *= 0.7
			
		applied_terminal_velocity = terminal_velocity / wall_sliding

		if velocity.y > 0:
			applied_gravity = applied_gravity / wall_sliding
			
	else:
		applied_terminal_velocity = terminal_velocity
	#
	if gravity_active:
		if velocity.y <= applied_terminal_velocity:
			velocity.y += applied_gravity
		elif velocity.y > applied_terminal_velocity:
			velocity.y = applied_terminal_velocity
	
	
	## Jumping
	# Handle coyote Time when you fall of a ledge
	if not is_dashing:
		if was_on_floor and not is_on_wall() and not is_on_floor():
			coyote_active = true
			_coyote_time()
		
		if is_jumping:
			if press:
				if double_jump:
					double_jump = false
					velocity.y = -jump_magnitude
					is_jumping = true
		
		if is_walking:
			if press and not is_on_wall():
				coyote_active = false
				velocity.y = -jump_magnitude
				_emit_jump_particle()
				is_walking = false
				is_jumping = true
		
		if is_falling:
			if press:
				if coyote_active:
					coyote_active = false
					velocity.y = -jump_magnitude
					_emit_jump_particle()
					is_jumping = true
					
				elif double_jump:
					double_jump = false
					velocity.y = -jump_magnitude
					is_falling = false
					is_jumping = true
		
		if is_wall_sliding:
			if press:
				coyote_active = false
				velocity.y = -jump_magnitude
				wall_jump = true
				change_direction(null)
				is_wall_sliding = false
				is_jumping = true
	
	if is_on_floor():
		double_jump = true
		coyote_active = true
	
	if is_on_wall():
		double_jump = true
	
	
	## Dashing
	if not is_walking:
		if dash:
			if swipe_down or swipe_left or swipe_right or swipe_up:
				if not is_in_tight_spot:
					if is_wall_sliding:
						if swipe_left and move_right:
							is_wall_sliding = false
							is_dashing = true
							_dash(Vector2i(-1,0))
							dash = false
							change_direction(false)
						elif swipe_right and move_left:
							is_wall_sliding = false
							is_dashing = true
							_dash(Vector2(1,0))
							dash = false
							change_direction(true)
					else:
						if swipe_left and move_left:
							is_falling = false
							is_jumping = false
							is_dashing = true
							_dash(Vector2i(-1,0))
							dash = false
						elif swipe_right and move_right:
							is_falling = false
							is_jumping = false
							is_dashing = true
							_dash(Vector2(1,0))
							dash = false
	
	if is_on_floor():
		dash = true
	
	was_on_floor = is_on_floor()
	move_and_slide()


func _drop_through():

	dropping_through = true
	set_collision_layer_value(2,false)
	set_collision_mask_value(2,false)
	await get_tree().create_timer(drop_through_time).timeout
	dropping_through = false
	set_collision_layer_value(2,true)
	set_collision_mask_value(2,true)


func _dash(direction: Vector2i):

	var d_time = 0.0625 * dash_length

	_dashing_time(d_time)
	_pause_gravity(d_time)
	velocity.x = dash_magnitude * direction.x
	velocity.y = dash_magnitude * direction.y
	


func _reset_dash():

	is_dashing = false
	is_falling = true


func change_direction(to_right):

	if to_right != null:
		move_right = to_right
	else:
		move_right = not move_right
	
	move_left = not move_right
	
	_stop_all_particles()


func _coyote_time():

	await get_tree().create_timer(coyote_time).timeout
	coyote_active = false


func _decelerate(delta, vertical):

	if !vertical:
		if velocity.x > 0:
			velocity.x += deceleration * delta
		elif velocity.x < 0:
			velocity.x -= deceleration * delta
	elif vertical and velocity.y > 0:
		velocity.y += deceleration * delta


func _input_pause_reset(time):

	await get_tree().create_timer(time).timeout
	movement_input_monitoring = Vector2(true, true)


func _pause_gravity(time):

	gravity_active = false
	await get_tree().create_timer(time).timeout
	gravity_active = true


func _dashing_time(time):

	is_dashing = true
	await get_tree().create_timer(time).timeout
	_reset_dash()
