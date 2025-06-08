extends Area2D
class_name DropItemBase

# 基本物品信息
@export var item_name: String = "未知物品"
@export var item_description: String = "这是一个神秘的物品"
@export var item_icon: Texture2D  # 物品图标
@export var item_rarity: String = "common"  # 物品稀有度

# UI相关
@export var info_panel_scene: PackedScene  # 信息面板场景
@export var show_distance: float = 50.0  # 显示信息的距离
@export var panel_offset: Vector2 = Vector2(0, -30)  # 面板相对物品的偏移

# 内部变量
var info_panel: Control
var player_in_range: bool = false
var current_player: Node2D

# 信号
signal item_picked_up(item: DropItemBase)
signal player_entered_range(player: Node2D)
signal player_exited_range(player: Node2D)

func _ready() -> void:
	# 连接区域信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 如果没有指定信息面板场景，创建默认的
	if not info_panel_scene:
		_create_default_info_panel()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		_show_info_panel()
		player_entered_range.emit(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		current_player = null
		_hide_info_panel()
		player_exited_range.emit(body)

func _show_info_panel() -> void:
	if info_panel:
		return
	
	if info_panel_scene:
		info_panel = info_panel_scene.instantiate()
	else:
		info_panel = _create_default_info_panel()
	
	# 将面板添加到场景树的UI层
	var ui_layer = get_viewport().get_child(0).get_node_or_null("UILayer")
	if not ui_layer:
		ui_layer = get_viewport().get_child(0)
	
	ui_layer.add_child(info_panel)
	
	# 更新面板信息
	_update_info_panel()
	
	# 设置面板位置
	_update_info_panel_position()

func _hide_info_panel() -> void:
	if info_panel:
		info_panel.queue_free()
		info_panel = null

func _update_info_panel() -> void:
	if not info_panel:
		return
	
	# 获取扩展信息
	var info_data = get_item_info()
	
	# 更新基本信息
	var name_label = info_panel.get_node_or_null("VBox/NameLabel")
	if name_label:
		name_label.text = info_data.name
	
	var desc_label = info_panel.get_node_or_null("VBox/DescLabel")
	if desc_label:
		desc_label.text = info_data.description
	
	var icon_rect = info_panel.get_node_or_null("VBox/HBox/IconRect")
	if icon_rect and info_data.has("icon") and info_data.icon:
		icon_rect.texture = info_data.icon
	
	# 调用虚函数，允许子类自定义更新逻辑
	_on_update_info_panel(info_data)

func _update_info_panel_position() -> void:
	if not info_panel:
		return
	
	var screen_pos = get_global_position()
	if get_viewport():
		var camera = get_viewport().get_camera_2d()
		if camera:
			screen_pos = camera.to_screen_coord_unclipped(global_position)
	
	info_panel.global_position = screen_pos + panel_offset

func _process(_delta: float) -> void:
	if info_panel and player_in_range:
		_update_info_panel_position()

# 获取物品信息的虚函数，子类可以重写来添加更多信息
func get_item_info() -> Dictionary:
	var info = {
		"name": item_name,
		"description": item_description,
		"rarity": item_rarity
	}
	
	if item_icon:
		info["icon"] = item_icon
	
	return info

# 虚函数：子类可以重写来自定义信息面板更新逻辑
func _on_update_info_panel(info_data: Dictionary) -> void:
	pass

# 虚函数：物品被拾取时调用
func pickup_item(player: Node2D) -> bool:
	# 子类应该重写这个方法来实现具体的拾取逻辑
	item_picked_up.emit(self)
	queue_free()
	return true

# 创建默认信息面板
func _create_default_info_panel() -> Control:
	var panel = PanelContainer.new()
	panel.name = "ItemInfoPanel"
	
	# 设置面板样式
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style_box)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	# 创建水平布局用于图标和信息
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	vbox.add_child(hbox)
	
	# 图标
	var icon_rect = TextureRect.new()
	icon_rect.name = "IconRect"
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	hbox.add_child(icon_rect)
	
	# 信息容器
	var info_vbox = VBoxContainer.new()
	hbox.add_child(info_vbox)
	
	# 名称标签
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(name_label)
	
	# 描述标签
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.x = 200
	info_vbox.add_child(desc_label)
	
	return panel

# 工具函数：设置物品信息
func set_item_info(name: String, description: String, icon: Texture2D = null, rarity: String = "common") -> void:
	item_name = name
	item_description = description
	item_icon = icon
	item_rarity = rarity
	
	if info_panel:
		_update_info_panel()

# 工具函数：检查玩家是否在范围内
func is_player_in_range() -> bool:
	return player_in_range

# 工具函数：获取当前范围内的玩家
func get_current_player() -> Node2D:
	return current_player
