extends EnemyBase

# Fire Spirit特有属性
@export var dash_speed: float = 400.0
@export var dash_damage: int = 25
@export var attack_cooldown: float = 3.0
@export var deceleration_rate: float = 800.0

# 攻击相关变量
var is_preparing_attack: bool = false
var is_dashing: bool = false
var dash_direction: Vector2
var dash_target_position: Vector2
var attack_timer: float = 0.0

# 冲刺状态
enum DashState {
	NONE,
	PREPARING,
	DASHING,
	DECELERATING
}
var dash_state: DashState = DashState.NONE

func init_enemy():
	# 设置Fire Spirit的基础属性
	enemy_speed = 80.0
	enemy_health = 120.0
	attack_damage = 15
	min_distance_to_player = 150.0
	
	# 确保enemy_sprite已经准备好
	if not enemy_sprite:
		enemy_sprite = $AnimatedSprite2D

func handle_behavior(delta: float):
	# 更新攻击冷却
	if attack_timer > 0:
		attack_timer -= delta
	
	# 根据当前状态处理行为
	match dash_state:
		DashState.NONE:
			handle_normal_behavior(delta)
		DashState.PREPARING:
			handle_preparing_attack(delta)
		DashState.DASHING:
			handle_dashing(delta)
		DashState.DECELERATING:
			handle_deceleration(delta)

func handle_normal_behavior(delta: float):
	var distance_to_player = get_distance_to_player()
	
	# 检查是否应该开始攻击
	if distance_to_player <= min_distance_to_player * 1.5 and attack_timer <= 0 and not is_preparing_attack:
		start_dash_attack()
		return
	
	# 普通移动逻辑
	if distance_to_player > min_distance_to_player:
		var move_dir = (player.global_position - global_position).normalized()
		velocity = move_dir * enemy_speed
		current_state = EnemyState.MOVING
	else:
		velocity = Vector2.ZERO
		current_state = EnemyState.IDLE
	
	move_and_slide()

func start_dash_attack():
	print("Fire Spirit准备冲刺攻击！")
	
	# 开启无敌，显示描边
	enemy_godmode = true
	flash_material.set_shader_parameter("flash", false)
	flash_material.set_shader_parameter("enable_outline", true)
	flash_material.set_shader_parameter("shain", true)  # 彩虹描边
	
	dash_state = DashState.PREPARING
	is_preparing_attack = true
	current_state = EnemyState.ATTACKING
	velocity = Vector2.ZERO
	
	# 记录目标位置（玩家当前位置）
	dash_target_position = player.global_position
	dash_direction = (dash_target_position - global_position).normalized()
	
	# 播放准备攻击动画（如果有的话）
	if enemy_sprite.sprite_frames.has_animation("prepare_attack"):
		enemy_sprite.play("prepare_attack")
	else:
		enemy_sprite.play("idle")
	
	# 1秒延迟后开始冲刺
	await get_tree().create_timer(0.5).timeout
	
	if dash_state == DashState.PREPARING:  # 确保状态没有被打断
		execute_dash()

func execute_dash():
	print("Fire Spirit开始冲刺！")
	dash_state = DashState.DASHING
	is_dashing = true
	
	# 设置冲刺速度
	velocity = dash_direction * dash_speed
	
	# 播放冲刺动画
	if enemy_sprite.sprite_frames.has_animation("dash"):
		enemy_sprite.play("dash")
	else:
		enemy_sprite.play("walk")

func handle_preparing_attack(delta: float):
	# 准备阶段保持静止
	velocity = Vector2.ZERO
	move_and_slide()

func handle_dashing(delta: float):
	# 检测碰撞
	move_and_slide()
	
	# 检查是否撞到玩家或达到目标位置附近
	var distance_to_target = global_position.distance_to(dash_target_position)
	if distance_to_target < 50.0:  # 接近目标位置
		start_deceleration()

func start_deceleration():
	print("Fire Spirit开始减速停下")
	dash_state = DashState.DECELERATING

func handle_deceleration(delta: float):
	# 逐渐减速
	var current_speed = velocity.length()
	if current_speed > 10.0:
		var decel_amount = deceleration_rate * delta
		var new_speed = max(0, current_speed - decel_amount)
		velocity = velocity.normalized() * new_speed
	else:
		# 完全停止
		velocity = Vector2.ZERO
		end_dash_attack()
	
	move_and_slide()

func end_dash_attack():
	print("Fire Spirit冲刺攻击结束")
	dash_state = DashState.NONE
	is_preparing_attack = false
	is_dashing = false
	current_state = EnemyState.IDLE
	attack_timer = attack_cooldown
	
	# 恢复普通动画
	enemy_sprite.play("idle")
	
	# 关闭无敌和描边
	enemy_godmode = false
	flash_material.set_shader_parameter("flash", false)
	flash_material.set_shader_parameter("enable_outline", false)
	flash_material.set_shader_parameter("shain", false)  # 彩虹描边

# 重写伤害处理，在冲刺状态下可能有不同表现
func take_damage(from_direction: Vector2, damage: float):
	super.take_damage(from_direction, damage)
	
	# 如果在准备攻击阶段被打断，取消攻击
	if dash_state == DashState.PREPARING:
		dash_state = DashState.NONE
		is_preparing_attack = false
		current_state = EnemyState.IDLE
		attack_timer = attack_cooldown * 0.5  # 被打断后冷却时间减半

# 检测与玩家碰撞造成伤害
func _on_body_entered(body):
	if dash_state == DashState.DASHING:
		if body.is_in_group("player"):
			# 对玩家造成冲刺伤害
			if body.has_method("take_damage"):
				body.take_damage(dash_direction, dash_damage)
				print("Fire Spirit冲刺攻击命中玩家！")
			
			# 冲刺攻击命中后开始减速
			start_deceleration()
