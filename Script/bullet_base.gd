extends Area2D

class_name BulletBase


@export var explosion_scene: PackedScene  # ⬅️ 指向爆炸特效
@export var speed := 300.0
@export var damage: float = 20

var direction := Vector2.ZERO
var exploded := false


func _ready() -> void:
	add_to_group("bullet")
	
	body_entered.connect(on_body_enter)


func _process(delta):
	if not exploded:
		position += direction * speed * delta


func on_body_enter(body: Node2D) -> void:
	if exploded:
		return
		
	if body.is_in_group("enemy"):  # 击中 Enemy
		exploded = true
	
		# 计算方向并击退
		var hit_direction = body.global_position - get_tree().get_first_node_in_group("player").global_position
		body.take_damage(hit_direction, damage)
	
	spawn_explosion(global_position)  # ⬅️ 当前位置作为爆炸点
	exploded = false
	queue_free()


# 生成爆炸特效
func spawn_explosion(pos: Vector2):
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = pos
		get_tree().current_scene.add_child(explosion)
