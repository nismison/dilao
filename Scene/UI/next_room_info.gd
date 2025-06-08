extends Control

@onready var label: Label = $PanelContainer/Label


func _ready() -> void:
	set_label_text("Init")


func set_label_text(_label_text: String) -> void:
	label.text = _label_text
