extends Camera2D


@onready var player: CharacterBody2D = $".."
@onready var look_ahead: float = 0.3
@onready var follow_wieght: float = 8.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("left") || Input.is_action_pressed("right"):
		var target = player.velocity * look_ahead
		if player.isdashing:
			target /= player.DASH_SPEED
		offset = offset.lerp(target, delta*follow_wieght)
	else:
		offset = offset.lerp(Vector2.ZERO, delta*follow_wieght)
