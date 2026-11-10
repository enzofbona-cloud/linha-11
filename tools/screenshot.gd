extends SceneTree
## Tira capturas do protótipo para conferência visual.
## Uso: godot --path . --rendering-method gl_compatibility --resolution 1280x720 -s tools/screenshot.gd -- <pasta de saída>

const SHOTS := [
	# [nome, posição, yaw em graus, lanterna]
	["01_corredor", Vector3(0, 0.05, -1.0), 0.0, false],
	["02_corredor_lanterna", Vector3(0, 0.05, -7.0), 0.0, true],
	["03_porta_304", Vector3(0, 0.05, -13.6), 0.0, true],
	["04_apto_303", Vector3(2.0, 0.05, -10.5), -75.0, true],
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
		for i in 20:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [out_dir, shot[0]])
	quit()
