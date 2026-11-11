class_name SequencePhone
extends StaticBody3D
## Telefone analógico do puzzle sonoro, com disco e auricular modelados.

@export_range(0, 2) var tone_index := 0
var puzzle: PhoneSequence
var _sound: AudioStreamPlayer3D


func _init() -> void:
	add_to_group("interactables")


func _ready() -> void:
	_sound = SoundKit.player_3d(self, SoundKit.sequence_note(tone_index), 12.0, -2.0)
	_build_phone()


func _build_phone() -> void:
	var plastic := StandardMaterial3D.new()
	plastic.albedo_color = Color(0.065, 0.045, 0.035)
	plastic.roughness = 0.38
	var bakelite := StandardMaterial3D.new()
	bakelite.albedo_color = Color(0.022, 0.018, 0.015)
	bakelite.roughness = 0.3
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.38, 0.27, 0.12)
	brass.metallic = 0.58
	brass.roughness = 0.42
	var hole_mat := StandardMaterial3D.new()
	hole_mat.albedo_color = Color(0.004, 0.004, 0.004)

	var base := MeshInstance3D.new()
	var housing := BoxMesh.new()
	housing.size = Vector3(0.29, 0.095, 0.22)
	housing.material = plastic
	base.mesh = housing
	base.position.y = 0.055
	add_child(base)

	var dial := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.083
	disc.bottom_radius = 0.083
	disc.height = 0.014
	disc.radial_segments = 32
	disc.material = brass
	dial.mesh = disc
	dial.position = Vector3(0, 0.11, 0.015)
	add_child(dial)
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var hole := MeshInstance3D.new()
		var hole_mesh := CylinderMesh.new()
		hole_mesh.top_radius = 0.009
		hole_mesh.bottom_radius = 0.009
		hole_mesh.height = 0.003
		hole_mesh.material = hole_mat
		hole.mesh = hole_mesh
		hole.position = Vector3(cos(angle) * 0.057, 0.12, 0.015 + sin(angle) * 0.057)
		add_child(hole)
	var center := MeshInstance3D.new()
	var center_disc := CylinderMesh.new()
	center_disc.top_radius = 0.026
	center_disc.bottom_radius = 0.026
	center_disc.height = 0.008
	center_disc.material = plastic
	center.mesh = center_disc
	center.position = Vector3(0, 0.122, 0.015)
	add_child(center)

	var handset := MeshInstance3D.new()
	var grip := CapsuleMesh.new()
	grip.radius = 0.044
	grip.height = 0.31
	grip.material = bakelite
	handset.mesh = grip
	handset.position = Vector3(0, 0.16, -0.055)
	handset.rotation.z = PI / 2.0
	add_child(handset)
	for side in [-1.0, 1.0]:
		var cup := MeshInstance3D.new()
		var cup_mesh := SphereMesh.new()
		cup_mesh.radius = 0.055
		cup_mesh.height = 0.09
		cup_mesh.material = bakelite
		cup.mesh = cup_mesh
		cup.position = Vector3(side * 0.13, 0.16, -0.055)
		add_child(cup)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.38, 0.32, 0.34)
	shape.shape = box
	shape.position.y = 0.12
	add_child(shape)


func get_prompt(_player: Player) -> String:
	return "[E] Ouvir o tom do telefone"


func interact(player: Player) -> void:
	if _sound != null:
		_sound.play()
	player.make_noise(2.0)
	if puzzle != null:
		puzzle.press(tone_index, player)
