extends SceneTree

const CAPTURES := [
	["01_304_entrada", Vector3(0, 0.05, 1.0), 0.0],
	["02_fotografia_riscada", Vector3(6.4, 0.05, -5.2), -90.0],
	["03_telefone_puzzle", Vector3(-3.3, 0.05, -23.0), 90.0],
	["04_gravador", Vector3(4.4, 0.05, -9.9), -90.0],
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
