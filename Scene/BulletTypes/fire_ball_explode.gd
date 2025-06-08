extends Node2D

@onready var anim = $AnimatedSprite2D

func _ready():
	anim.play("explode")
	anim.animation_finished.connect(queue_free)
