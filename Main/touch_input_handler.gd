# TouchInputHandler.gd - MODIFIED: TAP DELAY REINTRODUCED, INDENTED WITH TABS
# Thanks AI
extends Node2D

# --- Configuration ---
@export var min_swipe_distance_px: float = 50.0 # Minimum distance for a swipe to be registered on release
@export var immediate_swipe_distance_px: float = 30.0 # Movement for swipe to be registered *during* drag
@export var max_tap_movement_px: float = 10.0 # Max movement for a touch to still count as a tap/press
@export var min_tap_delay_s: float = 0.08 # The critical minimum time for a TAP gesture to be detected (short delay)

# --- Public 'Just Occurred' Flags (Read-only for other scripts) ---
var just_tapped: bool = false # Can now fire in _process (after delay) or on release (instant)
var just_swiped_left: bool = false
var just_swiped_right: bool = false
var just_swiped_up: bool = false
var just_swiped_down: bool = false

# --- Internal State Variables for Gesture Detection ---
var _touch_start_pos: Vector2 = Vector2.ZERO # Screen coordinates (where touch started)
var _current_touch_pos: Vector2 = Vector2.ZERO # Screen coordinates (current position of the touch)
var _touch_start_time: float = 0.0
var _is_touching: bool = false # True if a finger is currently down (index 0)
var _is_tap_gesture_detected_once: bool = false # True if a tap has already fired for this touch
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
	just_swiped_left = false
	just_swiped_right = false
	just_swiped_up = false
	just_swiped_down = false

	# --- Check for Delayed Tap (Tap on Press) ---
	if _is_touching and not _is_tap_gesture_detected_once and not _is_swipe_gesture_detected_once:
		var current_time = Time.get_ticks_msec() / 1000.0
		var touch_duration = current_time - _touch_start_time
		
		# Check how much the touch has moved from its start position
		var current_movement = _touch_start_pos.distance_to(_current_touch_pos)
		var is_static_enough_for_tap = (current_movement < max_tap_movement_px)

		# Detect DELAYED TAP (Fires 'on press' after a short delay)
		if touch_duration >= min_tap_delay_s and is_static_enough_for_tap:
			just_tapped = true
			print("DEBUG: DELAYED TAP detected (Fires on Press)!")
			_is_tap_gesture_detected_once = true


func _input(event: InputEvent) -> void:
	# --- Debug Keyboard Input (for testing on desktop) ---
	if event.is_action_pressed("press"): # Spacebar by default
		if event.is_pressed() and not event.is_echo(): 
			just_tapped = true	
			print("DEBUG: SPACEBAR pressed - just_tapped = TRUE (Keyboard Simulation)")
	
	if event.is_action_pressed("left"): 
		if event.is_pressed() and not event.is_echo():
			just_swiped_left = true
			print("DEBUG: A/LEFT pressed - just_swiped_left = TRUE (Keyboard Simulation)")

	if event.is_action_pressed("right"): 
		if event.is_pressed() and not event.is_echo():
			just_swiped_right = true
			print("DEBUG: D/RIGHT pressed - just_swiped_right = TRUE (Keyboard Simulation)")

	if event.is_action_pressed("up"): 
		if event.is_pressed() and not event.is_echo():
			just_swiped_up = true
			print("DEBUG: W/UP pressed - just_swiped_up = TRUE (Keyboard Simulation)")

	if event.is_action_pressed("down"): 
		if event.is_pressed() and not event.is_echo():
			just_swiped_down = true
			print("DEBUG: S/DOWN pressed - just_swiped_down = TRUE (Keyboard Simulation)")

	# --- ONLY PROCESS TOUCH EVENTS BELOW THIS POINT ---
	if !(event is InputEventScreenDrag or event is InputEventScreenTouch):
		return

	# Only care about the first touch (index 0)
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
			_is_swipe_gesture_detected_once = false # Reset swipe flag for new touch

		else: # Touch Released
			if _is_touching && event.index == _current_touch_id:
				_is_touching = false
				_current_touch_id = -1 # Reset tracked touch ID

				var touch_end_pos = event.position
				var touch_movement = _touch_start_pos.distance_to(touch_end_pos)

				# --- Gesture Priority on Release ---
				# 1. Swipe detection on release: Only if a swipe wasn't already detected mid-drag
				if not _is_swipe_gesture_detected_once and touch_movement >= min_swipe_distance_px:
					detect_swipe_direction(_touch_start_pos, touch_end_pos)
					_is_swipe_gesture_detected_once = true # Mark swipe detected
					_is_tap_gesture_detected_once = true # Swipe cancels any potential tap

				# 2. Instant Tap on Release: Only occurs if NO tap was already detected by the delay
				# This catches rapid presses that didn't meet the min_tap_delay_s
				if not _is_swipe_gesture_detected_once and not _is_tap_gesture_detected_once:
					if touch_movement < max_tap_movement_px:
						just_tapped = true
						print("DEBUG: INSTANT TAP detected (Fires on Release)!")
						_is_tap_gesture_detected_once = true

	elif event is InputEventScreenDrag:
		if _is_touching && event.index == _current_touch_id:
			_current_touch_pos = event.position # Update current position during drag
			
			# Immediate Swipe Detection during drag
			if not _is_swipe_gesture_detected_once:
				var current_movement_from_start = _touch_start_pos.distance_to(_current_touch_pos)
				
				if current_movement_from_start >= immediate_swipe_distance_px:
					detect_swipe_direction(_touch_start_pos, _current_touch_pos) # Trigger swipe immediately
					_is_swipe_gesture_detected_once = true
					# Crucial: Cancel any potential tap that was in progress
					_is_tap_gesture_detected_once = true


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
