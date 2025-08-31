# TouchInputHandler.gd
extends Node2D

# --- Configuration ---
@export var min_swipe_distance_px: float = 50.0 # Minimum distance for a swipe to be registered on release
@export var immediate_swipe_distance_px: float = 30.0 # Movement for swipe to be registered *during* drag (should be < min_swipe_distance_px for nuanced behavior)
@export var max_tap_movement_px: float = 10.0 # Max movement for a touch to still count as a tap/press/hold
@export var min_tap_delay_s: float = 0.08 # Minimum time for a 'delayed tap' gesture to be detected (short delay)
@export var min_hold_time_s: float = 0.5 # Minimum time for a hold gesture to be detected (longer delay)

# --- Public 'Just Occurred' Flags (Read-only for other scripts) ---
var just_tapped: bool = false # Can be instant (on release) or delayed (in process)
var just_held: bool = false
var just_swiped_left: bool = false
var just_swiped_right: bool = false
var just_swiped_up: bool = false
var just_swiped_down: bool = false

# --- Public 'Continuous' Flags (Read-only for other scripts) ---
var is_held: bool = false # True as long as the finger is held down after min_hold_time_s
var _previous_is_held_state: bool = false # Internal to detect state changes for debug prints

# --- Internal State Variables for Gesture Detection ---
var _touch_start_pos: Vector2 = Vector2.ZERO # Screen coordinates (where touch started)
var _current_touch_pos: Vector2 = Vector2.ZERO # Screen coordinates (current position of the touch)
var _touch_start_time: float = 0.0
var _is_touching: bool = false # True if a finger is currently down (index 0)
var _is_tap_gesture_detected_once: bool = false # True if *any* tap (instant or delayed) has already fired for this touch
var _is_hold_gesture_detected_once: bool = false # True if 'just_held' has already fired for this touch
var _is_swipe_gesture_detected_once: bool = false # True if a swipe has already fired for this touch
var _current_touch_id: int = -1 # To track the specific finger for our single-touch logic


# Camera remains available for screen_to_world conversion if needed elsewhere.
var game_camera: Camera2D = null:
	set(value):
		game_camera = value


# Public method to convert screen position to world position using the assigned camera
func screen_to_world(screen_pos: Vector2) -> Vector2:
	if is_instance_valid(game_camera):
		return game_camera.screen_to_world(screen_pos)
	return screen_pos # Fallback to screen position if no camera is assigned

func _process(_delta: float) -> void:
	# --- RESET ALL 'JUST OCCURRED' FLAGS AT THE START OF EACH FRAME ---
	just_tapped = false
	just_held = false
	just_swiped_left = false
	just_swiped_right = false
	just_swiped_up = false
	just_swiped_down = false

	# --- Update 'is_held' and 'just_tapped' continuous flags based on current touch state ---
	# These will only be detected if a swipe hasn't already occurred for this touch.
	if _is_touching and _current_touch_id != -1 and not _is_swipe_gesture_detected_once:
		var current_time = Time.get_ticks_msec() / 1000.0
		var touch_duration = current_time - _touch_start_time
		
		# Check how much the touch has moved from its start position
		var current_movement = _touch_start_pos.distance_to(_current_touch_pos)
		var is_static_enough_for_gesture = (current_movement < max_tap_movement_px)

		# 1. Detect HOLD gesture (longer static press)
		if touch_duration >= min_hold_time_s and is_static_enough_for_gesture:
			is_held = true
			if not _is_hold_gesture_detected_once:
				just_held = true
				print("DEBUG: JUST HELD detected!")
				_is_hold_gesture_detected_once = true
			# If it becomes a hold, it's not a tap anymore
			_is_tap_gesture_detected_once = true 
		else:
			is_held = false # Not a hold if duration not met or moved too much

		# 2. Detect DELAYED TAP gesture (shorter static press, not a hold yet)
		# A delayed tap fires if it's static enough, passed the tap delay, but hasn't become a hold yet.
		if not _is_tap_gesture_detected_once and not _is_hold_gesture_detected_once:
			if touch_duration >= min_tap_delay_s and is_static_enough_for_gesture:
				just_tapped = true
				print("DEBUG: DELAYED TAP detected (in _process)!")
				_is_tap_gesture_detected_once = true
	else:
		# If not touching, or if a swipe was already detected, reset continuous flags
		is_held = false

	# Debug print for is_held when its state changes
	if is_held != _previous_is_held_state:
		if is_held:
			print("DEBUG: is_held = TRUE")
		else:
			print("DEBUG: is_held = FALSE")
		_previous_is_held_state = is_held


func _input(event: InputEvent) -> void:
	# --- Debug Keyboard Input (for testing on desktop) ---
	# Ensure these actions are defined in Project Settings -> Input Map (ui_accept, ui_left, etc.)
	if event.is_action_pressed("ui_accept"): # Spacebar by default
		if event.is_pressed() and not event.is_echo(): # Avoid continuous triggers from holding key down
			# Simulate a quick tap for debugging
			just_tapped = true 
			print("DEBUG: SPACEBAR pressed - just_tapped = TRUE (Keyboard Simulation)")
			get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("ui_left"): # 'A' or Left Arrow by default
		if event.is_pressed() and not event.is_echo():
			just_swiped_left = true
			print("DEBUG: A/LEFT pressed - just_swiped_left = TRUE (Keyboard Simulation)")
			get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_right"): # 'D' or Right Arrow by default
		if event.is_pressed() and not event.is_echo():
			just_swiped_right = true
			print("DEBUG: D/RIGHT pressed - just_swiped_right = TRUE (Keyboard Simulation)")
			get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_up"): # 'W' or Up Arrow by default
		if event.is_pressed() and not event.is_echo():
			just_swiped_up = true
			print("DEBUG: W/UP pressed - just_swiped_up = TRUE (Keyboard Simulation)")
			get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_down"): # 'S' or Down Arrow by default
		if event.is_pressed() and not event.is_echo():
			just_swiped_down = true
			print("DEBUG: S/DOWN pressed - just_swiped_down = TRUE (Keyboard Simulation)")
			get_viewport().set_input_as_handled()

	# --- ONLY PROCESS TOUCH EVENTS BELOW THIS POINT ---
	if !(event is InputEventScreenDrag or event is InputEventScreenTouch):
		return # Ignore non-touch events that weren't handled as debug input

	# Only care about the first touch (index 0) for these simple flags
	if event.index != 0:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_is_touching = true
			_current_touch_id = event.index
			_touch_start_pos = event.position
			_current_touch_pos = event.position # Initialize current pos
			_touch_start_time = Time.get_ticks_msec() / 1000.0
			
			_is_tap_gesture_detected_once = false # Reset tap flag for new touch
			_is_hold_gesture_detected_once = false # Reset hold flag for new touch
			_is_swipe_gesture_detected_once = false # Reset swipe flag for new touch
			is_held = false # Ensure is_held is false at the very start of a new touch

			# just_tapped is NO LONGER SET HERE on press. It's set in _process after delay or on release.
			# print("DEBUG: Touch Pressed (start tracking)")
		else: # Touch Released
			if _is_touching && event.index == _current_touch_id: # Only process if it's our tracked touch
				_is_touching = false
				_current_touch_id = -1 # Reset tracked touch ID
				is_held = false # Touch lifted, so not held anymore

				var touch_end_pos = event.position
				var touch_duration = (Time.get_ticks_msec() / 1000.0) - _touch_start_time
				var touch_movement = _touch_start_pos.distance_to(touch_end_pos)

				# --- Gesture Priority on Release ---
				# 1. Swipe detection on release: Only if a swipe wasn't already detected mid-drag
				if not _is_swipe_gesture_detected_once and touch_movement >= min_swipe_distance_px:
					detect_swipe_direction(_touch_start_pos, touch_end_pos)
					_is_swipe_gesture_detected_once = true # Mark swipe detected
					# A swipe always takes precedence, so ensure tap/hold flags are marked as 'detected'
					_is_tap_gesture_detected_once = true
					_is_hold_gesture_detected_once = true
				
				# 2. Instant Tap detection: Only if no other major gesture (swipe, hold, or delayed tap) occurred
				if not _is_swipe_gesture_detected_once and not _is_hold_gesture_detected_once and not _is_tap_gesture_detected_once:
					if touch_duration < min_tap_delay_s and touch_movement < max_tap_movement_px:
						just_tapped = true
						print("DEBUG: INSTANT TAP detected (on release)!")
						_is_tap_gesture_detected_once = true # Mark tap detected

	elif event is InputEventScreenDrag:
		if _is_touching && event.index == _current_touch_id:
			_current_touch_pos = event.position # Update current position during drag
			
			# Immediate Swipe Detection during drag
			if not _is_swipe_gesture_detected_once: # Only detect if a swipe hasn't already fired
				var current_movement_from_start = _touch_start_pos.distance_to(_current_touch_pos)
				if current_movement_from_start >= immediate_swipe_distance_px:
					detect_swipe_direction(_touch_start_pos, _current_touch_pos) # Trigger swipe immediately
					_is_swipe_gesture_detected_once = true
					# Crucial: Cancel any potential tap/hold that was in progress
					_is_tap_gesture_detected_once = true
					_is_hold_gesture_detected_once = true


func detect_swipe_direction(start_pos: Vector2, end_pos: Vector2) -> void:
	var delta_pos = end_pos - start_pos
	var abs_delta_x = abs(delta_pos.x)
	var abs_delta_y = abs(delta_pos.y)

	if abs_delta_x > abs_delta_y:
		# Horizontal swipe
		if delta_pos.x > 0:
			just_swiped_right = true
			print("DEBUG: SWIPED RIGHT detected!")
		else:
			just_swiped_left = true
			print("DEBUG: SWIPED LEFT detected!")
	else:
		# Vertical swipe
		if delta_pos.y > 0:
			just_swiped_down = true
			print("DEBUG: SWIPED DOWN detected!")
		else:
			just_swiped_up = true
			print("DEBUG: SWIPED UP detected!")
