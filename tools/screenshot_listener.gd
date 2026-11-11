extends SceneTree
## Captura quadros seguidos do Ouvinte andando, para conferir a animação.
## Uso: godot --path . --rendering-method gl_compatibility --resolution 1280x720 -s tools/screenshot_listener.gd -- <pasta>

const FRAMES := 6
const GAP := 14 # quadros de jogo entre uma captura e outra


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "build/shots_listener"
	DirAccess.make_dir_recursive_absolute(out_dir)

	var scene: Node = load("res://game/scenes/prototype/prototype.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.session.process_mode = Node.PROCESS_MODE_DISABLED
	scene.get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var player: Player = scene.player
	player.global_position = Vector3(0, 0.05, -13.0)
	player.rotation_degrees.y = 180.0
	player.flashlight.visible = true
	scene.set_power(false)
	scene.listener.position.z = -5.0
	scene.listener.wake()
	# faz ele vir andando na direção da câmera
	scene.listener.hear(Vector3(0, 0, -11.0), 100.0)

	for i in 20:
		await physics_frame
	for shot in FRAMES:
		for i in GAP:
			await physics_frame
		await process_frame
		root.get_texture().get_image().save_png("%s/ouvinte_%02d.png" % [out_dir, shot + 1])
	quit()
