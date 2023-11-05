extends CanvasLayer
class_name UILayer


@onready var unit_energy: ProgressBar = $UnitEnergy
@onready var take_control: TextureButton = $TakeControl

var selected_npc: NPC = null

@export_group("Cursors")
@export var cursor_default: CompressedTexture2D
@export var cursor_clicked: CompressedTexture2D
@export_group("")


func touch(npc: NPC, energy: int, max_energy: int) -> void:
	unit_energy.visible = npc != null
	take_control.visible = npc != null
	if selected_npc != npc: take_control.button_pressed = false

	if npc == null:
		if take_control.pressed.is_connected(selected_npc.obey): take_control.pressed.disconnect(selected_npc.obey)
		take_control.disabled = false
		return
	
	selected_npc = npc
	if !take_control.pressed.is_connected(selected_npc.obey): take_control.pressed.connect(selected_npc.obey)
	unit_energy.max_value = max_energy
	unit_energy.value = energy

	
func _ready() -> void:
	for it in get_children():
		it.hide()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("LMB"):
		Input.set_custom_mouse_cursor(cursor_clicked)
	if Input.is_action_just_released("LMB"):
		Input.set_custom_mouse_cursor(cursor_default)
		

func _on_take_control_pressed() -> void:
	$TakeControl.disabled = true
