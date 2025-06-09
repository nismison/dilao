extends CharacterBody2D
class_name EnemyBase

@export var enemy_speed: float = 100.0
@export var enemy_health: float = 100.0
@export var enemy_godmode: bool = false
@export var attack_damage: int = 10
@export var chest_scene: PackedScene
@export var min_distance_to_player: float = 200

@onready var enemy_sprite: AnimatedSprite2D
@onready var player: Node2D = get_tree().get_nodes_in_group('player')[0]

var flash_material: ShaderMaterial

# 状态枚举
enum EnemyState {
	IDLE,
	MOVING,
	ATTACKING,
	STUNNED
}

var current_state: EnemyState = EnemyState.IDLE

func _ready():
	# 子类初始化方法
	init_enemy()
	
	add_to_group("enemy")
	set_collision_layer_value(2, true)  # 指定为Enemy层
	set_collision_mask_value(3, true)   # 指定和Bullet碰撞
	set_collision_mask_value(4, true)   # 指定和Wall碰撞
	y_sort_enabled = true
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	flash_material = enemy_sprite.material as ShaderMaterial

# 子类初始化入口 在子类脚本中重写
func init_enemy() -> void:
	pass

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	if not enemy_sprite:
		print("没有指定敌人Sprite，请检查！")
		return
	
	# 子类可以重写这个方法来实现不同的行为
	handle_behavior(delta)
	
	# 处理翻转
	if velocity.x < -1:
		enemy_sprite.flip_h = true  # 向左
	elif velocity.x > 1:
		enemy_sprite.flip_h = false  # 向右
	
	# 更新动画
	if velocity.length() > 0.1:
		enemy_sprite.play("walk")
	else:
		enemy_sprite.play("idle")

# 基础行为，子类可以重写
func handle_behavior(delta: float):
	var to_player = player.global_position - global_position
	if to_player.length() > min_distance_to_player:
		var move_dir = (player.global_position - global_position).normalized()
		velocity = move_dir * enemy_speed
		current_state = EnemyState.MOVING
	else:
		velocity = Vector2.ZERO
		current_state = EnemyState.IDLE
	move_and_slide()

# 造成伤害
func take_damage(from_direction: Vector2, damage: float):
	if enemy_godmode:
		print("Enemy 无敌状态中！")
		return
	
	print("Enemy 被击中了！")
	flash_white()
	calculate_health(damage)

# 击中闪白
func flash_white():
	if flash_material == null:
		return
	flash_material.set_shader_parameter("flash", true)
	flash_material.set_shader_parameter("flash_strength", 0.5)
	flash_material.set_shader_parameter("enable_outline", false)
	await get_tree().create_timer(0.1).timeout
	flash_material.set_shader_parameter("flash", false)

# 计算血量
func calculate_health(damage: float):
	enemy_health -= damage
	
	if enemy_health <= 0:
		queue_free()

# 获取到玩家的距离
func get_distance_to_player() -> float:
	if player == null:
		return INF
	return global_position.distance_to(player.global_position)
