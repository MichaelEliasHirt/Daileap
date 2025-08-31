extends CharacterBody2D
class_name PlayerController

@export_category("Necesary Child Nodes")
@export var PlayerSprite: AnimatedSprite2D
@export var PlayerCollider: CollisionShape2D

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft

#INFO HORIZONTAL MOVEMENT 
@export_category("L/R Movement")
##The max speed your player will move
@export_range(50, 500) var maxSpeed: float = 200.0
##How fast your player will reach max speed from rest (in seconds)
@export_range(0, 4) var timeToReachMaxSpeed: float = 0.05
##How fast your player will reach zero speed from max speed (in seconds)
@export_range(0, 4) var timeToReachZeroSpeed: float = 0.2
##If true, player will instantly move and switch directions. Overrides the "timeToReach" variables, setting them to 0.
@export var directionalSnap: bool = false

#INFO JUMPING 
@export_category("Jumping and Gravity")
##The peak height of your player's jump
@export_range(0, 20) var jumpHeight: float = 2.0
##How many jumps your character can do before needing to touch the ground again. Giving more than 1 jump disables jump buffering and coyote time.
@export_range(0, 100) var gravityScale: float = 20.0
##The fastest your player can fall
@export_range(0, 1000) var terminalVelocity: float = 500.0
##Your player will move this amount faster when falling providing a less floaty jump curve.
@export_range(0.5, 3) var descendingGravityFactor: float = 1.3
##Enabling this toggle makes it so that when the player releases the jump key while still ascending, their vertical velocity will cut in half, providing variable jump height.

@export_range(0, 0.5) var coyoteTime: float = 0.2

#INFO EXTRAS
@export_category("Wall Jumping")
##How long the player's movement input will be ignored after wall jumping.
@export_range(0, 0.5) var inputPauseAfterWallJump: float = 0.1
##The angle at which your player will jump away from the wall. 0 is straight away from the wall, 90 is straight up. Does not account for gravity
@export_range(0, 90) var wallKickAngle: float = 60.0
##The player's gravity will be divided by this number when touch a wall and descending. Set to 1 by default meaning no change will be made to the gravity and there is effectively no wall sliding. THIS IS OVERRIDDED BY WALL LATCH.
@export_range(1, 20) var wallSliding: float = 1.0

@export_category("Dashing")
##How far the player will dash. One of the dashing toggles must be on for this to be used.
@export_range(0.5, 10) var dashLength: float = 2.5
@export_range(1,5) var dashSpeed: float = 1

@export_category("Drop Through")
@export_range(0.05,0.5) var dropThroughTime: float = 0.1


@export_category("Animations (Check Box if has animation)")
##Animations must be named "jump" all lowercase as the check box says
@export var jump: bool
##Animations must be named "idle" all lowercase as the check box says
@export var idle: bool
##Animations must be named "walk" all lowercase as the check box says
@export var walk: bool
##Animations must be named "slide" all lowercase as the check box says
@export var slide: bool
##Animations must be named "latch" all lowercase as the check box says
@export var falling: bool

#Variables determined by the developer set ones.

var move_right := true
var move_left := false
var drop_straight := false

var double_jump = true

var appliedGravity: float
var maxSpeedLock: float
var appliedTerminalVelocity: float

var friction: float
var acceleration: float
var deceleration: float
var instantAccel: bool = false
var instantStop: bool = false

var jumpMagnitude: float = 500.0
var jumpWasPressed: bool = false
var coyoteActive: bool = false
var dashMagnitude: float
var gravityActive: bool = true
var dashing: bool = false
var dashing_up: bool = false
var dashing_down: bool = false
var dashing_left: bool = false
var dashing_right: bool = false

var dashCount: int

var jumped: bool = false

var droppingThrough: bool = false

var wasMovingR: bool
var wasPressingR: bool
var movementInputMonitoring: Vector2 = Vector2(true, true) #movementInputMonitoring.x addresses right direction while .y addresses left direction

var gdelta: float = 1

var dset = false

var colliderScaleLockY
var colliderPosLockY

var was_on_wall = false
var was_on_floor = false


var anim: AnimatedSprite2D
var col
var animScaleLock : Vector2

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


func _ready():
	wasMovingR = true
	anim = PlayerSprite
	col = PlayerCollider
	
	_updateData()


func _updateData():
	acceleration = maxSpeed / timeToReachMaxSpeed
	deceleration = -maxSpeed / timeToReachZeroSpeed
	
	jumpMagnitude = (10.0 * jumpHeight) * gravityScale
	
	dashMagnitude = maxSpeed * dashLength * dashSpeed
	
	maxSpeedLock = maxSpeed
	
	animScaleLock = abs(anim.scale)
	colliderScaleLockY = col.scale.y
	colliderPosLockY = col.position.y
	
	if timeToReachMaxSpeed == 0:
		instantAccel = true
		timeToReachMaxSpeed = 1
	elif timeToReachMaxSpeed < 0:
		timeToReachMaxSpeed = abs(timeToReachMaxSpeed)
		instantAccel = false
	else:
		instantAccel = false
		
	if timeToReachZeroSpeed == 0:
		instantStop = true
		timeToReachZeroSpeed = 1
	elif timeToReachMaxSpeed < 0:
		timeToReachMaxSpeed = abs(timeToReachMaxSpeed)
		instantStop = false
	else:
		instantStop = false
		
	
	coyoteTime = abs(coyoteTime)
	
	if directionalSnap:
		instantAccel = true
		instantStop = true



func _process(_delta):
	
	if ray_cast_right.is_colliding() and ray_cast_left.is_colliding():
		is_in_tight_spot_frames += 1
		if is_in_tight_spot_frames >= is_in_tight_spot_min_frames:
			is_in_tight_spot = true
	else:
		is_in_tight_spot_frames = 0
		is_in_tight_spot = false
	
	
	instantStop = false
	instantAccel = false
	#INFO animations
	if move_right:
		
		anim.scale.x = animScaleLock.x
	elif move_left:
		anim.scale.x = animScaleLock.x * -1
		

		
	if is_on_wall():
		if velocity.y > 0 and slide and wallSliding != 1:
			anim.speed_scale = 1
			anim.play("wallslide")
			was_on_wall = true
	
	else:
		if is_on_floor():
			if idle and walk and !dashing:
				if abs(velocity.x) > 0.1 and is_on_floor() and !is_on_wall():
					#anim.speed_scale = abs(velocity.x / 150)
					anim.play("run")
					
			was_on_wall = false
		else:
			if velocity.y < 0 and jump and !dashing:
				
				if was_on_wall:
					if anim.animation != "jump_up_wall":
						anim.speed_scale = 1
						anim.play("jump_up_wall")
					
				elif anim.animation != "jump_up":
					
					anim.speed_scale = 1
					anim.play("jump_up")
				
			elif velocity.y >= 0 and falling and !dashing and anim.animation != "jump_down":
				anim.speed_scale = 1
				anim.play("jump_down")
		
	
	if dashing:
		anim.speed_scale = 1
		anim.play("dash")


func _physics_process(delta):
	jumped = false
	if !dset:
		gdelta = delta
		dset = true
		
	press = TouchInputHandler.just_tapped
	hold = TouchInputHandler.just_held
	swipe_left = TouchInputHandler.just_swiped_left
	swipe_right = TouchInputHandler.just_swiped_right
	swipe_up = TouchInputHandler.just_swiped_up
	swipe_down = TouchInputHandler.just_swiped_down
	still_hold = TouchInputHandler.is_held
	
	if is_on_floor() or is_on_wall():
		drop_straight = false
	
	if is_on_wall() and is_on_floor():
		if move_right:
			change_direction(false)
		elif move_left:
			change_direction(true)
		instantStop = true
		instantAccel = true
	
	
	elif is_on_floor() and not is_on_wall():
		if swipe_left:
			change_direction(false)
		elif swipe_right:
			change_direction(true)
		if swipe_down:
			_dropThrough()
	
	if not drop_straight:
		if move_right:
			if not dashing:
				if velocity.x > maxSpeed or instantAccel:
					velocity.x = maxSpeed
				else:
					velocity.x += acceleration * delta
			if velocity.x < 0:
				if !instantStop:
					_decelerate(delta, false)
				else:
					velocity.x = -0.1
					
		elif move_left:
			if not dashing:
				if velocity.x < -maxSpeed or instantAccel:
					velocity.x = -maxSpeed
				else:
					velocity.x -= acceleration * delta
			if velocity.x > 0:
				if !instantStop:
					_decelerate(delta, false)
				else:
					velocity.x = 0.1
	else:
		velocity.x = 0
						
	if velocity.x > 0:
		wasMovingR = true
	elif velocity.x < 0:
		wasMovingR = false
		
		
	#INFO Jump and Gravity
	if velocity.y > 0:
		appliedGravity = gravityScale * descendingGravityFactor
	else:
		appliedGravity = gravityScale
	
	if is_on_wall():
		if velocity.y < 0:
			velocity.y *= 0.8
		appliedTerminalVelocity = terminalVelocity / wallSliding

		if wallSliding != 1 and velocity.y > 0:
			appliedGravity = appliedGravity / wallSliding
			
	elif !is_on_wall():
		appliedTerminalVelocity = terminalVelocity
	
	if gravityActive:
		if velocity.y < appliedTerminalVelocity:
			velocity.y += appliedGravity
		elif velocity.y > appliedTerminalVelocity:
			velocity.y = appliedTerminalVelocity
			
	if not dashing: 
		if was_on_floor and not is_on_wall() and not is_on_floor():
			coyoteActive = true
			_coyoteTime()
				
		if press and !is_on_wall():
			drop_straight = false
			if is_on_floor(): 
				coyoteActive = false
				velocity.y = -jumpMagnitude
			
			elif coyoteActive:
				coyoteActive = false
				velocity.y = -jumpMagnitude
			
			elif double_jump:
				double_jump = false
				velocity.y = -jumpMagnitude
			
		elif press and is_on_wall() and !is_on_floor():
			drop_straight = false
			_wallJump()
			coyoteActive = false
			was_on_wall = true
			
		if is_on_floor():
			double_jump = true
			coyoteActive = true
		
		if is_on_wall():
			double_jump = true
	
		
	if not is_on_floor():
		if dashCount > 0:
			
			if not is_on_wall():
				if swipe_left and move_left:
					drop_straight = false
					dashing = true
					dashing_left = true
					_dash(Vector2i(-1,0))
				elif swipe_right and move_right:
					drop_straight = false
					dashing = true
					dashing_right = true
					_dash(Vector2i(1,0))
			
			else:
				if not is_in_tight_spot:
					if swipe_left and move_right:
						drop_straight = false
						dashing = true
						dashing_left = true
						_dash(Vector2i(-1,0))
						change_direction(false)
					elif swipe_right and move_left:
						drop_straight = false
						dashing = true
						dashing_right = true
						_dash(Vector2i(1,0))
						change_direction(true)
	
	else:
		dashCount = 1
	
	var _was_on_wall = is_on_wall()
	was_on_floor = is_on_floor()
	move_and_slide()
	
	if not jumped and not was_on_floor and not dashing:
		if _was_on_wall and not is_on_wall():
			change_direction(null)
			drop_straight = true
			

func _dropThrough():
	droppingThrough = true
	set_collision_layer_value(2,false)
	set_collision_mask_value(2,false)
	await get_tree().create_timer(dropThroughTime).timeout
	droppingThrough = false
	set_collision_layer_value(2,true)
	set_collision_mask_value(2,true)


func _dash(direction: Vector2i):
	dashCount -= 1
	double_jump = false
	var dTime = 0.0625 * dashLength

	_dashingTime(dTime)
	_pauseGravity(dTime)
	velocity.x = dashMagnitude * direction.x
	velocity.y = dashMagnitude * direction.y
		

func _reset_dash():
	dashing = false
	dashing_down = false
	dashing_left = false
	dashing_right = false
	dashing_up = false


func _wallJump():
	jumped = true
	var horizontalWallKick = abs(jumpMagnitude * cos(wallKickAngle * (PI / 180)))
	var verticalWallKick = abs(jumpMagnitude * sin(wallKickAngle * (PI / 180)))
	velocity.y = -verticalWallKick
	var dir = 1
	
	if wasMovingR:
		
		change_direction(false)
		velocity.x = -horizontalWallKick  * dir
		
	else:
		change_direction(true)
		velocity.x = horizontalWallKick * dir
		
	if inputPauseAfterWallJump != 0:
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(inputPauseAfterWallJump)


func change_direction(to_right):
	if to_right != null:
		move_right = to_right
	else:
		move_right = not move_right
	
	move_left = not move_right


func _coyoteTime():
	await get_tree().create_timer(coyoteTime).timeout
	coyoteActive = false


func _decelerate(delta, vertical):
	if !vertical:
		if velocity.x > 0:
			velocity.x += deceleration * delta
		elif velocity.x < 0:
			velocity.x -= deceleration * delta
	elif vertical and velocity.y > 0:
		velocity.y += deceleration * delta


func _inputPauseReset(time):
	await get_tree().create_timer(time).timeout
	movementInputMonitoring = Vector2(true, true)

func _pauseGravity(time):
	gravityActive = false
	await get_tree().create_timer(time).timeout
	gravityActive = true

func _dashingTime(time):
	dashing = true
	await get_tree().create_timer(time).timeout
	_reset_dash()
