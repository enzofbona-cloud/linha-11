extends SceneTree

const CAPTURES := [
	["01_entrada_corredor", Vector3(0, 0.05, 3.6), 0.0],
	["02_sala_tv", Vector3(-2.0, 0.05, 0.6), 136.0],
	["03_sala_leitura", Vector3(-2.2, 0.05, 1.2), 31.0],
	["04_sala_jantar", Vector3(1.7, 0.05, 3.9), -37.0],
	["05_quarto_casal", Vector3(-1.5, 0.05, -5.6), 90.0],
	["06_quarto_menino", Vector3(1.6, 0.05, -4.4), -90.0],
	["07_escritorio", Vector3(-1.6, 0.05, -11.1), 90.0],
	["08_deposito", Vector3(1.6, 0.05, -9.7), -90.0],
	["09_corredor_fundo", Vector3(0, 0.05, -14.2), 0.0],
]


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "build/shots-chapter2"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var scene: Node3D = load("res://game/scenes/chapter2/apartment_304.tscn").instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.session.process_mode = Node.PROCESS_MODE_DISABLED  # sem captura nem pausa automática
	scene.get_tree().paused = false
	for i in 40:
		await process_frame
	scene.set_process(false)
	scene.get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	scene.player.flashlight.visible = true
	for shot in CAPTURES:
		scene.player.global_position = shot[1]
		scene.player.rotation_degrees.y = shot[2]
		for i in 12:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [out_dir, shot[0]])
	quit()
