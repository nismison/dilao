extends CharacterBody2D


@export var player_move_speed: float = 200
@export var dash_speed: float = 500
@export var is_dashing := false
@export var ready_to_dash := true

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var dust_sprite: AnimatedSprite2D = $DustSprite
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cd_timer: Timer = $DashCDTimer

@onready var weapon_socket = $WeaponSocket
@export var weapon_scene: PackedScene

var dash_direction = Vector2.ZERO


func _ready():
	add_to_group("player")
	y_sort_enabled = true
	
	var weapon_instance = weapon_scene.instantiate()
	weapon_socket.add_child(weapon_instance)
	weapon_instance.target_node = weapon_socket  # 设置跟随目标为Socket


func _physics_process(delta: float) -> void:
	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		var move_derection: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = move_derection * player_move_speed
		
		# 控制播放动画
		if velocity.length() > 0:
			animated_sprite_2d.play("run")
			dust_sprite.visible = true
		else:
			animated_sprite_2d.play("idle")
			dust_sprite.visible = false
			
		# 控制水平翻转
		if velocity.x != 0:
			animated_sprite_2d.flip_h = velocity.x < 0
			dust_sprite.flip_h = velocity.x < 0
		
			
	move_and_slide()
	

func _unhandled_input(event: InputEvent) -> void:
	# 闪避监听
	if event.is_action_pressed("dash") and not is_dashing:
		start_dash()


# 闪避相关函数
func start_dash() -> void:
	if is_dashing or not ready_to_dash:
		return
	
	is_dashing = true
	ready_to_dash = false
	
	var _dash_derection = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 冲刺
	dash_direction = _dash_derection.normalized()
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT
	
	# 定时清除冲刺状态
	dash_timer.start()
	await dash_timer.timeout
	is_dashing = false
	
	# 冲刺cd
	dash_cd_timer.start()
	await dash_cd_timer.timeout
	ready_to_dash = true
