extends CharacterBody2D

const MAXSPEED = 175.0
var maxspeed = 175.0
const SPEED_DEPT = 35
const AIR_DEPT = 2.5
const JUMP_VELOCITY = -400
var acceleration = 25
var gravity: Vector2

var standmesh: float
var standcoll: float

var crouchmesh: float
var crouchcoll: float
var slidedash_time:float = 0

const CROUCH_SCALE = 1.35

var sprint = false

var dash_time = 0.0
var dash_dir = Vector2.ZERO
const DASH_DURATION = 0.2
const DASH_SPEED = 450
var dashing_left = 1
var isdashing = false

const WALLRUN_DOWNRES: float = 1.075
var canwallrun = false
var iswallrunning = false
var wallrunning_left = 1

var wallkick_time = 0.0
var wallkick_dir = Vector2.ZERO
const WALLKICK_DURATION = 0.2
const WALLKICK_SPEED = 450

const VAULTING_DURATION= 0.2
var vaulttime = 0.0
var vaultdir = Vector2.ZERO
var canvault = false
var vaultcd = false
@onready var raycast:ShapeCast2D = $"ShapeCast2D"

const SLOWMO_DURATION: float = 1
const SLOWMO_COOLDOWN:float = 3
const SLOWMO_SCALE:float = 0.3
var slowmo_dur = 0.0
var slowmo_cd = 0.0
var isslowmo = false

@onready var player: CharacterBody2D = $"."
var Delta = 0.0

var initialize = true

func _physics_process(delta: float) -> void:
	if initialize:
		Delta = delta
		initialize = false
		standmesh = $"MeshInstance2D".scale.y
		standcoll = $"CollisionShape2D".scale.y
		crouchmesh = $"MeshInstance2D".scale.y/ CROUCH_SCALE
		crouchcoll = $"CollisionShape2D".scale.y/ CROUCH_SCALE
	
	if raycast.is_colliding() && raycast.get_collider(0).is_in_group("vault"):
		canvault = true
	else:
		canvault = false
	
	# Add the gravity.
	if not is_on_floor():
		velocity += gravity * delta
	else:
		wallrunning_left = 1
		dashing_left = 1
		
		
#vaulting handle
	if not vaultcd && canvault && Input.is_action_just_pressed("jump"):
		vaultcd = true
		vaulttime = VAULTING_DURATION
		var front = -cos(raycast.rotation)*(abs(velocity.x)+100)
		vaultdir = Vector2(front, JUMP_VELOCITY/2.75)
	if vaulttime > 0.0:
		vaulttime -= delta
		velocity = vaultdir
		isdashing = false
		move_and_slide()
		return
	elif vaulttime <= 0.0 && vaultcd:
		vaultcd = false
		if Input.is_action_pressed("jump"):
			slidedash_init(velocity.x,true)
			move_and_slide()
			return
		
		
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		Input.action_release("jump")
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	var uprection := Input.get_axis("up", "down")
	
	# handle crouch
	if Input.is_action_just_pressed("down"):
		$MeshInstance2D.scale.y = crouchmesh
		$CollisionShape2D.scale.y = crouchcoll
	if Input.is_action_just_released("down"):
		$MeshInstance2D.scale.y = standmesh
		$CollisionShape2D.scale.y = standcoll
	#sliding handling
	if Input.is_action_pressed("down") && velocity.x != 0:
		if  is_on_floor():
			if velocity.x >= 0:
				velocity.x = velocity.x - delta*125
			else:
				velocity.x = velocity.x + delta*125

		slidedash_init(velocity.x, (Input.is_action_just_pressed("jump") && direction * velocity.x > 0 &&  is_on_floor()))
		move_and_slide()
		return
	slidedash(delta)
	
	# dash handle
	dash(delta,direction,uprection)
	
	#wallrun handling
	if canwallrun && wallrunning_left > 0 && direction != 0 && not is_on_floor() && Input.is_action_pressed("jump"):
		gravity /= WALLRUN_DOWNRES
		iswallrunning = true
	elif iswallrunning:
		iswallrunning = false
		gravity = get_gravity()
		wallrunning_left -= 1
		if Input.is_action_pressed("up"):
			wallkick(delta,direction,true)
	else:
		gravity = get_gravity()
		
	
	
	#wallkick handling
	wallkick(delta,-direction, is_on_wall() && not is_on_floor() && Input.is_action_just_pressed("jump") && direction && wallkick_time <= 0.0 && not canvault)
	
	
	#sprint handling
	if Input.is_action_just_pressed("sprint"):
		sprint = !sprint
		if sprint:
			maxspeed = MAXSPEED*2
			acceleration *= 1.25
		else:
			maxspeed = MAXSPEED
			acceleration /= 1.25
	
	#walking
	if direction:
		var move = direction * acceleration
		if direction >= 0:
			raycast.rotation_degrees = 180
			raycast.position.x = player.get_node("CollisionShape2D").shape.radius + 10
		else:
			raycast.rotation_degrees = 0
			raycast.position.x = -player.get_node("CollisionShape2D").shape.radius - 10
		if not is_on_floor():
			move /= 1.75
		if abs(velocity.x) < maxspeed || abs(velocity.x + move) < abs(velocity.x):
			if abs(velocity.x + move) < abs(velocity.x):
				velocity.x = move_toward(velocity.x,0,SPEED_DEPT)
			velocity.x += move
	else:
		if is_on_floor():
			velocity.x = move_toward(velocity.x,0,SPEED_DEPT)
		else:
			velocity.x = move_toward(velocity.x,0,AIR_DEPT)
			
	move_and_slide()
	
	#handle slow motion
	if Input.is_action_just_pressed("slow mo"):
		print(isslowmo," ", slowmo_cd," ", slowmo_dur)
		if not isslowmo && slowmo_cd <= 0 && slowmo_dur <= 0:
			isslowmo = true
			slowmo_dur = SLOWMO_DURATION
		elif  isslowmo && slowmo_dur > 0:
			Engine.time_scale = 1
			isslowmo = false
			slowmo_dur = 0
			slowmo_cd = SLOWMO_COOLDOWN
	if isslowmo && slowmo_dur > 0 && slowmo_cd <= 0:
		slowmo_dur -= delta
		Engine.time_scale = SLOWMO_SCALE
	elif slowmo_dur <= 0 && isslowmo:
		slowmo_cd = SLOWMO_COOLDOWN
		isslowmo = false
		Engine.time_scale = 1
	if not isslowmo && slowmo_cd > 0:
		slowmo_cd -= delta


func dash(delta: float,direction: float, uprection: float)->void:
	if Input.is_action_just_pressed("dash") && dash_time <= 0.0 && (direction || uprection) && dashing_left > 0:
		dashing_left -= 1
		dash_time = DASH_DURATION
		isdashing = true
		
	if dash_time > 0.0 && isdashing:
		dash_dir = Vector2(direction,uprection).normalized()
		velocity = dash_dir * DASH_SPEED
		dash_time -= delta
		move_and_slide()
		return
	else:
		isdashing = false
		dash_time = 0


func wallkick(delta:float,direction:float,condition:bool)->void:
	if condition:
		wallkick_dir = Vector2(DASH_SPEED/1.5*direction,JUMP_VELOCITY/1.45)
		wallkick_time = WALLKICK_DURATION
		isdashing = false
	
	if wallkick_time > 0.0 :
		velocity = wallkick_dir
		wallkick_time -= delta
		move_and_slide()
		return
		

func slidedash_init(x_velocity:float, condition:bool) ->void:
	if condition:
		dash_dir = Vector2(x_velocity/abs(x_velocity)*(abs(x_velocity) - JUMP_VELOCITY/2.0),JUMP_VELOCITY/1.75)
		slidedash_time = WALLKICK_DURATION
		isdashing = false
		Input.action_release("down")

func slidedash(delta:float)-> void:
	if slidedash_time > 0.0:
		velocity = dash_dir
		slidedash_time -= delta


var closetowall = false

func touched_wall(area: Area2D) -> void:
	if area.is_in_group("wallrun"):
		canwallrun = true


func exited_wall(area: Area2D) -> void:
	if area.is_in_group("wallrun"):
		canwallrun = false
