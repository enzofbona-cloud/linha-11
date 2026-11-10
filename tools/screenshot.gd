extends SceneTree
## Tira capturas do protótipo para conferência visual.
## Uso: godot --path . --rendering-method gl_compatibility --resolution 1280x720 -s tools/screenshot.gd -- <pasta de saída>

const SHOTS := [
	# [nome, posição, yaw em graus, lanterna, energia, ouvinte acordado em z (ou null)]
	["01_inicio_sem_energia", Vector3(0, 0.05, -1.0), 0.0, true, false, null],
	["02_corredor_com_energia", Vector3(0, 0.05, -7.0), 0.0, false, true, null],
	["03_apto_302", Vector3(-2.2, 0.05, -5.5), 80.0, true, true, null],
	["04_ouvinte_no_escuro", Vector3(0, 0.05, -12.0), 180.0, true, false, -7.5],
	["05_telefone_304", Vector3(0, 0.05, -18.6), 0.0, false, false, null],
]


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "build/shots"
	DirAccess.make_dir_recursive_absolute(out_dir)

	var scene: Node = load("res://game/scenes/prototype/prototype.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for i in 30:
		await process_frame
	scene.set_process(false)  # evita a pausa automática ao soltar o mouse
	scene.get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var player: Player = scene.player
	for shot in SHOTS:
		player.global_position = shot[1]
		player.rotation_degrees.y = shot[2]
		player.flashlight.visible = shot[3]
		scene.set_power(shot[4])
		if shot[5] != null:
			scene.listener.wake()
			scene.listener.position.z = shot[5]
			scene.listener.set_physics_process(false)
		else:
			scene.listener.sleep()
		for i in 20:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [out_dir, shot[0]])
	quit()
