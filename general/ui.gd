extends CanvasLayer
class_name UILayer


@onready var unit_energy: ProgressBar = $UnitEnergy
@onready var take_control: TextureButton = $TakeControl

var selected_npc: NPC = null


func touch(npc: NPC, energy: int, max_energy: int) -> void:
	unit_energy.visible = npc != null
	take_control.visible = npc != null
	if selected_npc != npc: take_control.button_pressed = false

	if npc == null:
		if take_control.pressed.is_connected(selected_npc.obey): take_control.pressed.disconnect(selected_npc.obey)
		return
	
	selected_npc = npc
	if !take_control.pressed.is_connected(selected_npc.obey): take_control.pressed.connect(selected_npc.obey)
	unit_energy.max_value = max_energy
	unit_energy.value = energy

	
func _ready() -> void:
	for it in get_children():
		it.hide()
