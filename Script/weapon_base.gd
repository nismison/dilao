extends Node2D
class_name WeaponBase

@export var weapon_name: String = "This is name"
@export var weapon_des: String = "This is description"

# 射击相关参数
@export var bullet_scene: PackedScene = null
@export var bullet_spawn_offset: float = 0.0
@export var attack_speed: float = 5.0                  # 攻击速度 (次/秒)
@export var auto_fire: bool = true                     # 是否支持连发 (按住射击)

# 射击相关变量
var fire_timer: Timer                                   # 射击计时器
var is_attacking: bool = false                         # 是否正在攻击
var last_fire_time: float = 0.0                       # 上次射击时间
var fire_interval: float = 0.2                        # 射击间隔 (根据攻击速度计算)

# 跟随参数
var follow_speed := 200.0                      # 跟随速度
var base_offset := Vector2(-30, 0)             # 基础偏移距离
var max_follow_distance := 30.0                # 距离阈值，超过才追
var smoothing_factor := 0.1                    # 缓动因子 (0.05-0.2)
var direction_sensitivity := 1.0               # 方向跟随敏感度 (0.5-2.0)
var offset_smoothing := 0.05                   # 偏移平滑度 (越小越平滑)

# 浮动参数
var float_amplitude := 5.0                    # 上下浮动高度
var float_frequency := 0.5                     # 浮动频率
var float_randomness := 0.3                    # 浮动随机性 (0-1)

# 旋转参数
var rotation_amplitude := 0.01                  # 旋转幅度 (弧度)
var rotation_frequency := 0.3                  # 旋转频率
var rotation_follow_speed := 0.05              # 旋转跟随速度

# 延迟跟随参数
var lag_strength := 0.8                        # 延迟强度 (0-1)
var lag_smoothing := 0.15                      # 延迟平滑度

var target_node: Node2D = null                         # 外部设置挂点
var time_accumulator := 0.0
var noise: FastNoiseLite                               # 噪声生成器
var velocity := Vector2.ZERO                           # 当前速度
var lagged_position := Vector2.ZERO                    # 延迟位置
var target_rotation := 0.0                             # 目标旋转
var last_target_position := Vector2.ZERO               # 上一帧目标位置
var movement_velocity := Vector2.ZERO                   # 移动速度向量
var current_offset := Vector2.ZERO                     # 当前动态偏移
var movement_direction := Vector2.ZERO                  # 平滑的移动方向



func _ready():
	#if target_node == null:
		#push_warning("Weapon target_node 未设置，请手动设置 target_node！")
	
	# 初始化噪声
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.5
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# 初始化射击系统
	setup_fire_system()
	
	# 初始化位置
	if target_node:
		current_offset = base_offset
		lagged_position = target_node.global_position + current_offset
		global_position = lagged_position
		last_target_position = target_node.global_position

func _process(delta):
	if target_node == null:
		return
	
	time_accumulator += delta
	
	# 计算目标移动速度和方向
	var current_target_pos = target_node.global_position
	movement_velocity = (current_target_pos - last_target_position) / delta
	last_target_position = current_target_pos
	
	# 平滑移动方向，避免抖动
	if movement_velocity.length() > 10.0:  # 只在有明显移动时更新方向
		var new_direction = movement_velocity.normalized()
		movement_direction = movement_direction.lerp(new_direction, 0.1)
	
	# 根据移动方向计算动态偏移
	var target_offset = base_offset
	if movement_direction.length() > 0.1:
		# 武器应该出现在移动方向的反方向（身后）
		var behind_direction = -movement_direction * direction_sensitivity
		# 保持原有的距离，但调整方向
		var offset_distance = base_offset.length()
		target_offset = behind_direction * offset_distance
		
		# 添加一些垂直偏移，让武器不完全在正后方
		var perpendicular = Vector2(-movement_direction.y, movement_direction.x) * offset_distance * 0.3
		target_offset += perpendicular
	
	# 平滑过渡到新的偏移位置
	current_offset = current_offset.lerp(target_offset, offset_smoothing)
	
	# 1. 计算基础浮动（正弦波 + 噪声）
	var base_float = sin(time_accumulator * TAU * float_frequency) * float_amplitude
	var noise_float = noise.get_noise_1d(time_accumulator * 100) * float_amplitude * float_randomness
	var float_y = base_float + noise_float
	
	# 2. 添加水平浮动（更自然的轨迹）
	var float_x = cos(time_accumulator * TAU * float_frequency * 0.7) * float_amplitude * 0.3
	var float_offset = Vector2(float_x, float_y)
	
	# 3. 计算目标位置（使用动态偏移）
	var immediate_target = current_target_pos + current_offset + float_offset
	
	# 延迟跟随：让武器稍微滞后于玩家
	var lag_offset = movement_velocity * lag_strength * -0.1  # 反向偏移
	lagged_position = lagged_position.lerp(immediate_target + lag_offset, lag_smoothing)
	
	# 4. 平滑移动到目标位置
	var distance_to_target = global_position.distance_to(lagged_position)
	
	if distance_to_target > max_follow_distance:
		# 使用缓动而不是匀速移动
		var move_strength = min(distance_to_target / max_follow_distance, 1.0)
		velocity = velocity.lerp((lagged_position - global_position).normalized() * follow_speed * move_strength, smoothing_factor)
		global_position += velocity * delta
	else:
		# 近距离时使用更平滑的插值
		global_position = global_position.lerp(lagged_position, smoothing_factor * 2)
		velocity = velocity.lerp(Vector2.ZERO, smoothing_factor)
	
	# 5. 计算旋转（基于移动方向和浮动）
	var base_rotation = sin(time_accumulator * TAU * rotation_frequency) * rotation_amplitude
	var movement_rotation = movement_velocity.angle() * 0.1  # 根据移动方向轻微旋转
	var float_rotation = cos(time_accumulator * TAU * float_frequency * 1.3) * rotation_amplitude * 0.5
	
	target_rotation = base_rotation + movement_rotation + float_rotation
	rotation = lerp_angle(rotation, target_rotation, rotation_follow_speed)
	
	# 6. 处理连发射击
	if is_attacking and auto_fire:
		#var current_time = Time.get_time_dict_from_system()
		var time_since_last_fire = time_accumulator - last_fire_time
		if time_since_last_fire >= fire_interval:
			shoot_bullet()

## 可选：添加震屏或冲击时的反应
#func add_impulse(impulse: Vector2):
	#velocity += impulse * 0.5
#
## 可选：设置武器激活状态的不同行为
#func set_active(active: bool):
	#if active:
		#float_frequency = 1.5
		#follow_speed = 200.0
	#else:
		#float_frequency = 0.8
		#follow_speed = 100.0


# 初始化射击系统
func setup_fire_system():
	# 根据攻击速度计算射击间隔
	update_fire_interval()
	
	# 创建射击计时器
	fire_timer = Timer.new()
	fire_timer.wait_time = fire_interval
	fire_timer.one_shot = false
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)

# 更新射击间隔
func update_fire_interval():
	if attack_speed <= 0:
		fire_interval = 1.0  # 防止除零错误
	else:
		fire_interval = 1.0 / attack_speed

# 输入处理
func _unhandled_input(event: InputEvent) -> void:
	# 左键射击监听
	if event.is_action_pressed("attack"):
		start_attack()
	elif event.is_action_released("attack"):
		stop_attack()

# 开始攻击
func start_attack():
	is_attacking = true
	
	# 立即射击一次 (如果冷却时间已过)
	var time_since_last_fire = time_accumulator - last_fire_time
	if time_since_last_fire >= fire_interval:
		shoot_bullet()
	
	# 如果支持连发，启动计时器
	if auto_fire and not fire_timer.is_stopped():
		fire_timer.stop()
	if auto_fire:
		fire_timer.start()

# 停止攻击
func stop_attack():
	is_attacking = false
	fire_timer.stop()

# 计时器回调
func _on_fire_timer_timeout():
	if is_attacking and auto_fire:
		shoot_bullet()

# 射击相关函数
func shoot_bullet() -> void:
	if bullet_scene == null:
		print("武器未设置子弹场景")
		return
	
	# 检查射击冷却
	var time_since_last_fire = time_accumulator - last_fire_time
	if time_since_last_fire < fire_interval:
		return  # 还在冷却中，忽略射击请求
	
	# 记录射击时间
	last_fire_time = time_accumulator
	
	var bullet = bullet_scene.instantiate()
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	var spawn_pos = global_position + direction * bullet_spawn_offset
	
	bullet.global_position = spawn_pos
	bullet.direction = direction
	bullet.rotation = direction.angle()
	get_tree().current_scene.add_child(bullet)

# 设置攻击速度 (运行时修改)
func set_attack_speed(new_speed: float):
	attack_speed = max(0.1, new_speed)  # 最小攻击速度限制
	update_fire_interval()
	if fire_timer:
		fire_timer.wait_time = fire_interval

# 设置是否支持连发
func set_auto_fire(enabled: bool):
	auto_fire = enabled
	if not enabled and fire_timer:
		fire_timer.stop()
