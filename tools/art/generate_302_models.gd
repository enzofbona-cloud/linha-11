extends SceneTree
## Assets originais gerados por malhas procedurais Godot; materiais PBR são aplicados pelo LevelKit.

var _flat_materials: Dictionary = {}

func _initialize() -> void:
	call_deferred("_generate")

func _generate() -> void:
	var furniture := "furniture"
	var props := "props"
	_export_asset(furniture, "bed_80s", _build_bed())
	_export_asset(furniture, "headboard_80s", _build_headboard())
	_export_asset(furniture, "nightstand_80s", _build_nightstand())
	_export_asset(furniture, "wardrobe_80s", _build_wardrobe())
	_export_asset(furniture, "dresser_mirror_80s", _build_dresser())
	_export_asset(furniture, "chair_wood_80s", _build_chair())
	_export_asset(furniture, "bookcase_short_80s", _build_bookcase())
	_export_asset(furniture, "suitcase_open_80s", _build_suitcase())
	_export_asset(furniture, "standing_fan_80s", _build_fan())
	_export_asset(furniture, "window_curtains_80s", _build_window())
	_export_asset(props, "table_lamp_80s", _build_lamp())
	_export_asset(props, "alarm_clock_analog", _build_clock())
	_export_asset(props, "glass_tumbler", _build_tumbler())
	_export_asset(furniture, "table_80s", _build_table())
	_export_asset(furniture, "sofa_80s", _build_sofa())
	_export_asset(furniture, "armchair_80s", _build_armchair())
	_export_asset(furniture, "bench_wood_80s", _build_bench())
	_export_asset(furniture, "metal_shelf_80s", _build_metal_shelf())
	_export_asset(furniture, "sideboard_80s", _build_sideboard())
	_export_asset(furniture, "crate_wood_80s", _build_crate())
	_export_asset(props, "glass_fuse_1980s", _build_fuse())
	_export_asset(props, "medicine_blister", _build_blister())
	_export_asset(props, "slippers_pair", _build_slippers())
	_export_asset(props, "books_stack", _build_books())
	_export_asset(props, "open_book", _build_open_book())
	_export_asset(props, "paper_stack", _build_papers())
	_export_asset(props, "clothes_pile", _build_clothes())
	_export_asset(props, "toy_truck", _build_toy_truck())
	_export_asset(props, "photo_frame", _build_photo_frame())
	_export_asset(props, "wall_calendar_august", _build_calendar())
	_export_asset(props, "perfume_bottle", _build_perfume())
	_export_asset(props, "comb", _build_comb())
	_export_asset(props, "shoebox_pair", _build_shoeboxes())
	_export_asset(props, "wall_crucifix", _build_crucifix())
	print("Generated 34 original GLB assets.")
	quit()

func _export_asset(category: String, name: String, root: Node3D) -> void:
	var folder := "res://assets/models/%s" % category
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var append_error: Error = document.append_from_scene(root, state)
	if append_error != OK:
		push_error("GLTF append failed for %s: %s" % [name, append_error])
		root.free()
		return
	var path := ProjectSettings.globalize_path("%s/%s.glb" % [folder, name])
	var write_error: Error = document.write_to_filesystem(state, path)
	if write_error != OK:
		push_error("GLB write failed for %s: %s" % [name, write_error])
	else:
		print("Wrote %s (%d triangles, %.1f KiB)" % [path, _triangle_count(root), float(FileAccess.get_file_as_bytes(path).size()) / 1024.0])
	root.free()

func _triangle_count(root: Node) -> int:
	var total := 0
	for candidate in root.find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance.mesh != null:
			total += instance.mesh.get_faces().size() / 3
	return total

func _root(name: String) -> Node3D:
	var root := Node3D.new()
	root.name = name
	return root

func _flat(profile: String) -> StandardMaterial3D:
	if _flat_materials.has(profile):
		return _flat_materials[profile]
	var material := StandardMaterial3D.new()
	match profile:
		"wood":
			material.albedo_color = Color(0.35, 0.24, 0.14)
			material.roughness = 0.84
		"fabric", "cloth":
			material.albedo_color = Color(0.52, 0.45, 0.35)
			material.roughness = 0.98
		"paper":
			material.albedo_color = Color(0.76, 0.71, 0.6)
			material.roughness = 0.96
		"metal", "chrome":
			material.albedo_color = Color(0.38, 0.36, 0.32)
			material.metallic = 0.56
			material.roughness = 0.62
		"glass":
			material.albedo_color = Color(0.4, 0.48, 0.43, 0.45)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.roughness = 0.18
		"porcelain":
			material.albedo_color = Color(0.78, 0.75, 0.66)
			material.roughness = 0.34
		"rubber", "dark":
			material.albedo_color = Color(0.07, 0.065, 0.055)
			material.roughness = 0.86
		"rust":
			material.albedo_color = Color(0.32, 0.18, 0.1)
			material.metallic = 0.38
			material.roughness = 0.8
		_:
			material.albedo_color = Color(0.5, 0.45, 0.38)
			material.roughness = 0.8
	material.resource_name = "source_%s" % profile
	_flat_materials[profile] = material
	return material

func _mesh(root: Node3D, name: String, mesh: Mesh, profile: String, pos := Vector3.ZERO, rot := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = "%s__%s" % [profile, name]
	instance.mesh = mesh
	instance.material_override = _flat(profile)
	instance.position = pos
	instance.rotation = rot
	instance.scale = scale
	root.add_child(instance)
	return instance

func _box(root: Node3D, name: String, size: Vector3, pos: Vector3, profile := "wood", rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(root, name, mesh, profile, pos, rot)

func _cylinder(root: Node3D, name: String, top: float, bottom: float, height: float, pos: Vector3,
		profile := "metal", rot := Vector3.ZERO, segments := 16) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 2
	return _mesh(root, name, mesh, profile, pos, rot)

func _sphere(root: Node3D, name: String, size: Vector3, pos: Vector3, profile := "fabric", rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return _mesh(root, name, mesh, profile, pos, rot, size * 0.5)

func _capsule(root: Node3D, name: String, radius: float, height: float, pos: Vector3,
		profile := "metal", rot := Vector3.ZERO, segments := 12) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 4
	return _mesh(root, name, mesh, profile, pos, rot)

func _rod_between(root: Node3D, name: String, start: Vector3, finish: Vector3, radius: float, profile := "metal") -> void:
	var direction := finish - start
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = direction.length()
	mesh.radial_segments = 8
	var instance := _mesh(root, name, mesh, profile, (start + finish) * 0.5)
	instance.quaternion = Quaternion(Vector3.UP, direction.normalized())

func _quad(root: Node3D, name: String, size: Vector2, pos: Vector3, profile := "paper", rot := Vector3.ZERO) -> void:
	var mesh := QuadMesh.new()
	mesh.size = size
	_mesh(root, name, mesh, profile, pos, rot)

func _build_bed() -> Node3D:
	var root := _root("Bed80s")
	for x in [-0.82, 0.82]:
		for z in [-0.4, 0.4]:
			_box(root, "leg", Vector3(0.075, 0.2, 0.075), Vector3(x, -0.15, z), "wood")
	_box(root, "side_rail_left", Vector3(1.72, 0.13, 0.07), Vector3(0, -0.1, -0.43), "wood")
	_box(root, "side_rail_right", Vector3(1.72, 0.13, 0.07), Vector3(0, -0.1, 0.43), "wood")
	_box(root, "foot_rail", Vector3(0.075, 0.18, 0.9), Vector3(0.85, -0.08, 0), "wood")
	_box(root, "slats", Vector3(1.72, 0.045, 0.82), Vector3(0, -0.015, 0), "wood")
	_box(root, "mattress", Vector3(1.78, 0.22, 0.88), Vector3(0, 0.14, 0), "fabric")
	_box(root, "sheet_edge", Vector3(1.75, 0.025, 0.86), Vector3(0, 0.258, 0), "paper")
	_sphere(root, "pillow", Vector3(0.48, 0.11, 0.7), Vector3(-0.6, 0.25, 0.02), "fabric")
	_add_blanket(root)
	return root

func _add_blanket(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 18
	var nz := 10
	for i in nx:
		for j in nz:
			var points: Array[Vector3] = []
			var coords: Array[Vector2] = []
			for corner in [Vector2(i, j), Vector2(i + 1, j), Vector2(i + 1, j + 1), Vector2(i, j + 1)]:
				var u: float = corner.x / float(nx)
				var v: float = corner.y / float(nz)
				var x: float = lerpf(-0.82, 0.82, u)
				var z: float = lerpf(-0.4, 0.4, v)
				var folds := sin(u * TAU * 5.0 + v * 8.0) * 0.008 + sin(u * 21.0 - v * 12.0) * 0.004
				var y := 0.267 + folds
				if v > 0.72:
					var hang: float = (v - 0.72) / 0.28
					z = lerpf(0.4, 0.49, hang)
					y = lerpf(0.267, -0.235, hang) + folds
				points.append(Vector3(x, y, z))
				coords.append(Vector2(u, v))
			for index in [0, 2, 1, 0, 3, 2]:
				st.set_uv(coords[index])
				st.add_vertex(points[index])
	st.generate_normals()
	var blanket := st.commit()
	_mesh(root, "creased_drape", blanket, "fabric")

func _build_headboard() -> Node3D:
	var root := _root("Headboard80s")
	_box(root, "panel", Vector3(0.075, 0.84, 0.94), Vector3.ZERO, "wood")
	_box(root, "crown_rail", Vector3(0.095, 0.12, 1.0), Vector3(0, 0.47, 0), "wood")
	_box(root, "lower_rail", Vector3(0.095, 0.09, 1.0), Vector3(0, -0.47, 0), "wood")
	for z in [-0.38, 0.38]:
		_cylinder(root, "brass_pin", 0.013, 0.013, 0.006, Vector3(0.051, 0.4, z), "metal", Vector3(0, 0, PI / 2), 10)
	return root

func _build_nightstand() -> Node3D:
	var root := _root("Nightstand80s")
	for x in [-0.18, 0.18]:
		for z in [-0.18, 0.18]:
			_box(root, "short_leg", Vector3(0.055, 0.16, 0.055), Vector3(x, -0.2, z), "wood")
	_box(root, "left_panel", Vector3(0.045, 0.34, 0.38), Vector3(-0.19, 0.0, 0), "wood")
	_box(root, "right_panel", Vector3(0.045, 0.34, 0.38), Vector3(0.19, 0.0, 0), "wood")
	_box(root, "back_panel", Vector3(0.38, 0.34, 0.035), Vector3(0, 0.0, -0.18), "wood")
	_box(root, "bottom", Vector3(0.38, 0.045, 0.38), Vector3(0, -0.14, 0), "wood")
	_box(root, "top", Vector3(0.45, 0.055, 0.45), Vector3(0, 0.252, 0), "wood")
	_box(root, "drawer_front", Vector3(0.34, 0.105, 0.035), Vector3(0, 0.12, 0.205), "wood")
	_box(root, "drawer_box", Vector3(0.3, 0.08, 0.24), Vector3(0, 0.12, 0.09), "wood")
	_cylinder(root, "drawer_pull", 0.018, 0.018, 0.035, Vector3(0, 0.12, 0.239), "metal", Vector3(PI / 2, 0, 0), 12)
	return root

func _build_wardrobe() -> Node3D:
	var root := _root("Wardrobe80s")
	_box(root, "back", Vector3(1.48, 1.9, 0.035), Vector3(0, 0, -0.27), "wood")
	_box(root, "left_side", Vector3(0.055, 1.92, 0.58), Vector3(-0.77, 0, 0), "wood")
	_box(root, "right_side", Vector3(0.055, 1.92, 0.58), Vector3(0.77, 0, 0), "wood")
	_box(root, "top", Vector3(1.58, 0.07, 0.62), Vector3(0, 0.965, 0), "wood")
	_box(root, "base", Vector3(1.58, 0.1, 0.62), Vector3(0, -0.95, 0), "wood")
	_box(root, "hanging_shelf", Vector3(1.45, 0.04, 0.52), Vector3(0, 0.45, 0), "wood")
	_cylinder(root, "clothes_rail", 0.018, 0.018, 1.35, Vector3(0, 0.32, 0.09), "metal", Vector3(PI / 2, 0, PI / 2), 12)
	for x in [-0.42, -0.14, 0.14, 0.42]:
		_capsule(root, "hanger_hook", 0.009, 0.08, Vector3(x, 0.28, 0.1), "metal")
		_box(root, "hanging_shirt", Vector3(0.22, 0.48, 0.04), Vector3(x, -0.1, 0.09), "fabric")
		_sphere(root, "shirt_fold", Vector3(0.27, 0.16, 0.06), Vector3(x, -0.32, 0.09), "cloth")
	var pivot := Node3D.new()
	pivot.name = "wood__ajar_door_hinge"
	pivot.position = Vector3(-0.78, 0, 0.3)
	pivot.rotation.y = deg_to_rad(-34.0)
	root.add_child(pivot)
	_box(pivot, "door_left", Vector3(0.73, 1.82, 0.045), Vector3(0.365, 0, 0), "wood")
	_cylinder(pivot, "door_knob", 0.025, 0.025, 0.028, Vector3(0.66, 0.0, 0.036), "metal", Vector3(PI / 2, 0, 0), 12)
	_box(root, "door_right", Vector3(0.73, 1.82, 0.045), Vector3(0.39, 0, 0.31), "wood")
	_cylinder(root, "right_knob", 0.024, 0.024, 0.03, Vector3(0.05, 0, 0.34), "metal", Vector3(PI / 2, 0, 0), 12)
	return root

func _build_dresser() -> Node3D:
	var root := _root("DresserMirror80s")
	_box(root, "carcass", Vector3(0.86, 0.72, 0.45), Vector3(0, -0.09, 0), "wood")
	for row in 3:
		var y := -0.31 + float(row) * 0.22
		_box(root, "drawer_front", Vector3(0.78, 0.18, 0.04), Vector3(0, y, 0.245), "wood")
		for x in [-0.21, 0.21]:
			_cylinder(root, "drawer_handle", 0.014, 0.014, 0.03, Vector3(x, y, 0.274), "metal", Vector3(PI / 2, 0, 0), 10)
	_box(root, "top", Vector3(0.93, 0.06, 0.5), Vector3(0, 0.3, 0), "wood")
	_box(root, "mirror_frame_left", Vector3(0.045, 0.66, 0.05), Vector3(-0.28, 0.66, -0.14), "wood")
	_box(root, "mirror_frame_right", Vector3(0.045, 0.66, 0.05), Vector3(0.28, 0.66, -0.14), "wood")
	_box(root, "mirror_frame_top", Vector3(0.6, 0.05, 0.05), Vector3(0, 0.98, -0.14), "wood")
	_box(root, "mirror_frame_bottom", Vector3(0.6, 0.05, 0.05), Vector3(0, 0.34, -0.14), "wood")
	_box(root, "mirror_glass", Vector3(0.51, 0.57, 0.012), Vector3(0, 0.66, -0.14), "glass")
	return root

func _build_chair() -> Node3D:
	var root := _root("Chair80s")
	for x in [-0.18, 0.18]:
		for z in [-0.18, 0.18]:
			_box(root, "leg", Vector3(0.045, 0.42, 0.045), Vector3(x, -0.22, z), "wood")
	_box(root, "seat_frame", Vector3(0.43, 0.06, 0.43), Vector3(0, 0.0, 0), "wood")
	_box(root, "seat_pad", Vector3(0.39, 0.08, 0.39), Vector3(0, 0.07, 0), "fabric")
	_box(root, "back_frame", Vector3(0.43, 0.62, 0.055), Vector3(0, 0.36, -0.19), "wood")
	_box(root, "back_cushion", Vector3(0.34, 0.42, 0.07), Vector3(0, 0.37, -0.15), "fabric")
	return root

func _build_bookcase() -> Node3D:
	var root := _root("BookcaseShort80s")
	for x in [-0.25, 0.25]:
		_box(root, "side", Vector3(0.045, 1.35, 0.4), Vector3(x, 0.675, 0), "wood")
	for y in [0.04, 0.36, 0.68, 1.0, 1.33]:
		_box(root, "shelf", Vector3(0.55, 0.045, 0.4), Vector3(0, y, 0), "wood")
	for level in 3:
		var y := 0.2 + float(level) * 0.32
		for index in 3:
			var x := -0.16 + float(index) * 0.14
			_box(root, "book_spine", Vector3(0.11, 0.22, 0.22), Vector3(x, y, 0.01), "paper", Vector3(0, 0, float(index - 1) * 0.08))
			_box(root, "book_cover", Vector3(0.115, 0.02, 0.23), Vector3(x, y - 0.1, 0.01), "wood")
	return root

func _build_suitcase() -> Node3D:
	var root := _root("OpenSuitcase80s")
	_box(root, "bottom_shell", Vector3(0.62, 0.12, 0.42), Vector3(0, 0.07, 0), "dark")
	_box(root, "inner_lining", Vector3(0.56, 0.025, 0.36), Vector3(0, 0.14, 0), "fabric")
	var lid := Node3D.new()
	lid.name = "wood__lid_hinge"
	lid.position = Vector3(0, 0.12, -0.2)
	lid.rotation.x = deg_to_rad(-58.0)
	root.add_child(lid)
	_box(lid, "open_lid", Vector3(0.62, 0.4, 0.055), Vector3(0, 0.2, 0), "dark")
	_box(lid, "lid_lining", Vector3(0.55, 0.32, 0.012), Vector3(0, 0.2, 0.034), "fabric")
	_box(root, "handle", Vector3(0.18, 0.025, 0.035), Vector3(0, 0.12, 0.23), "metal")
	_sphere(root, "shirt_in_suitcase", Vector3(0.28, 0.07, 0.25), Vector3(0.02, 0.19, 0.03), "fabric")
	return root

func _build_fan() -> Node3D:
	var root := _root("StandingFan80s")
	_cylinder(root, "weighted_base", 0.2, 0.22, 0.07, Vector3(0, 0.04, 0), "dark", Vector3.ZERO, 20)
	_cylinder(root, "pedestal", 0.027, 0.032, 0.88, Vector3(0, 0.49, 0), "metal", Vector3.ZERO, 12)
	_cylinder(root, "neck", 0.09, 0.11, 0.18, Vector3(0, 0.98, 0), "metal", Vector3.ZERO, 16)
	var center := Vector3(0, 1.16, 0)
	_cylinder(root, "motor", 0.15, 0.17, 0.24, center, "metal", Vector3(PI / 2, 0, 0), 16)
	_sphere(root, "motor_cap", Vector3(0.1, 0.1, 0.1), center + Vector3(0, 0, 0.14), "metal")
	for blade in 3:
		var angle := TAU * float(blade) / 3.0
		var blade_node := Node3D.new()
		blade_node.name = "fabric__fan_blade_pivot"
		blade_node.position = center + Vector3(0, 0, 0.15)
		blade_node.rotation.z = angle
		root.add_child(blade_node)
		_sphere(blade_node, "fan_blade", Vector3(0.16, 0.34, 0.035), Vector3(0, 0.23, 0), "metal", Vector3(0, 0, -0.18))
	for ring_radius in [0.18, 0.27, 0.36]:
		var segments := 16
		for i in segments:
			var a0 := TAU * float(i) / float(segments)
			var a1 := TAU * float(i + 1) / float(segments)
			var start := center + Vector3(cos(a0) * ring_radius, sin(a0) * ring_radius, 0.22)
			var finish := center + Vector3(cos(a1) * ring_radius, sin(a1) * ring_radius, 0.22)
			_rod_between(root, "guard_ring", start, finish, 0.006, "metal")
	for i in 12:
		var angle := TAU * float(i) / 12.0
		_rod_between(root, "guard_spoke", center + Vector3.ZERO + Vector3(cos(angle) * 0.08, sin(angle) * 0.08, 0.22),
			center + Vector3(cos(angle) * 0.36, sin(angle) * 0.36, 0.22), 0.004, "metal")
	return root

func _build_window() -> Node3D:
	var root := _root("WindowCurtains80s")
	_box(root, "left_jamb", Vector3(0.06, 1.45, 0.07), Vector3(-0.68, 0, 0), "wood")
	_box(root, "right_jamb", Vector3(0.06, 1.45, 0.07), Vector3(0.68, 0, 0), "wood")
	_box(root, "top_frame", Vector3(1.42, 0.06, 0.07), Vector3(0, 0.7, 0), "wood")
	_box(root, "sill", Vector3(1.46, 0.08, 0.2), Vector3(0, -0.68, 0.04), "wood")
	_box(root, "glass_left", Vector3(0.63, 1.28, 0.025), Vector3(-0.34, 0, -0.025), "glass")
	_box(root, "glass_right", Vector3(0.63, 1.28, 0.025), Vector3(0.34, 0, -0.025), "glass")
	_box(root, "mullion", Vector3(0.035, 1.3, 0.035), Vector3(0, 0, -0.005), "wood")
	_box(root, "crossbar", Vector3(1.3, 0.035, 0.035), Vector3(0, 0.08, -0.005), "wood")
	_cylinder(root, "curtain_rod", 0.018, 0.018, 1.75, Vector3(0, 0.78, 0.18), "metal", Vector3(0, 0, PI / 2), 12)
	for side in [-1.0, 1.0]:
		_box(root, "torn_curtain", Vector3(0.34, 1.28, 0.045), Vector3(side * 0.56, -0.02, 0.16), "fabric")
		_cylinder(root, "curtain_ring", 0.035, 0.035, 0.018, Vector3(side * 0.56, 0.7, 0.18), "metal", Vector3(0, 0, PI / 2), 10)
	return root

func _build_lamp() -> Node3D:
	var root := _root("TableLamp80s")
	_cylinder(root, "base", 0.09, 0.12, 0.035, Vector3(0, 0.018, 0), "porcelain", Vector3.ZERO, 20)
	_cylinder(root, "stem", 0.018, 0.022, 0.18, Vector3(0, 0.12, 0), "metal", Vector3.ZERO, 12)
	_cylinder(root, "shade", 0.055, 0.15, 0.2, Vector3(0, 0.31, 0), "fabric", Vector3.ZERO, 20)
	_sphere(root, "bulb", Vector3(0.055, 0.07, 0.055), Vector3(0, 0.27, 0), "glass")
	return root

func _build_clock() -> Node3D:
	var root := _root("AnalogAlarmClock")
	_box(root, "case", Vector3(0.19, 0.13, 0.09), Vector3(0, 0.07, 0), "dark")
	_cylinder(root, "face", 0.058, 0.058, 0.018, Vector3(0, 0.09, 0.052), "paper", Vector3(PI / 2, 0, 0), 24)
	_cylinder(root, "bezel", 0.066, 0.066, 0.014, Vector3(0, 0.09, 0.044), "metal", Vector3(PI / 2, 0, 0), 24)
	_box(root, "hour_hand", Vector3(0.009, 0.035, 0.006), Vector3(-0.006, 0.095, 0.065), "dark", Vector3(0, 0, -0.6))
	_box(root, "minute_hand", Vector3(0.006, 0.048, 0.006), Vector3(0.008, 0.1, 0.064), "dark", Vector3(0, 0, 0.1))
	for x in [-0.055, 0.055]:
		_cylinder(root, "bell", 0.045, 0.045, 0.025, Vector3(x, 0.15, -0.01), "metal", Vector3(0, 0, PI / 2), 12)
	return root

func _build_tumbler() -> Node3D:
	var root := _root("GlassTumbler")
	_cylinder(root, "glass_body", 0.042, 0.05, 0.12, Vector3(0, 0.06, 0), "glass", Vector3.ZERO, 18)
	_cylinder(root, "base", 0.049, 0.049, 0.009, Vector3(0, 0.009, 0), "glass", Vector3.ZERO, 18)
	return root

func _build_fuse() -> Node3D:
	var root := _root("GlassFuse1980s")
	_cylinder(root, "glass_core", 0.018, 0.018, 0.095, Vector3(0, 0, 0), "glass", Vector3(PI / 2, 0, 0), 12)
	_cylinder(root, "brass_contact_front", 0.022, 0.022, 0.018, Vector3(0, 0, 0.056), "metal", Vector3(PI / 2, 0, 0), 12)
	_cylinder(root, "brass_contact_back", 0.022, 0.022, 0.018, Vector3(0, 0, -0.056), "metal", Vector3(PI / 2, 0, 0), 12)
	_cylinder(root, "filament", 0.003, 0.003, 0.06, Vector3(0, 0, 0), "rust", Vector3(PI / 2, 0, 0), 8)
	return root
func _build_blister() -> Node3D:
	var root := _root("MedicineBlister")
	_box(root, "foil_card", Vector3(0.11, 0.008, 0.16), Vector3.ZERO, "paper", Vector3(0, 0, 0.06))
	for x in [-0.027, 0.027]:
		for z in [-0.045, 0.0, 0.045]:
			_sphere(root, "pill_dome", Vector3(0.027, 0.013, 0.023), Vector3(x, 0.009, z), "porcelain")
	return root

func _build_slippers() -> Node3D:
	var root := _root("SlippersPair")
	for side in [-1.0, 1.0]:
		var x: float = side * 0.11
		_sphere(root, "rubber_sole", Vector3(0.12, 0.035, 0.28), Vector3(x, 0.02, side * 0.04), "rubber")
		_capsule(root, "fabric_strap", 0.018, 0.1, Vector3(x, 0.065, side * 0.04), "fabric", Vector3(PI / 2, 0, side * 0.3), 10)
	return root

func _build_books() -> Node3D:
	var root := _root("BooksStack")
	for i in 3:
		var y := float(i) * 0.045
		var x := float(i - 1) * 0.018
		var rotation := float(i - 1) * 0.06
		_box(root, "book_pages", Vector3(0.22, 0.035, 0.15), Vector3(x, y + 0.02, 0), "paper", Vector3(0, rotation, 0))
		_box(root, "book_cover", Vector3(0.23, 0.012, 0.16), Vector3(x, y + 0.044, 0), "wood", Vector3(0, rotation, 0))
		_box(root, "book_back", Vector3(0.23, 0.009, 0.16), Vector3(x, y - 0.002, 0), "wood", Vector3(0, rotation, 0))
	return root

func _build_open_book() -> Node3D:
	var root := _root("OpenBook")
	_box(root, "left_page", Vector3(0.22, 0.018, 0.16), Vector3(-0.11, 0.015, 0), "paper", Vector3(0, 0, -0.08))
	_box(root, "right_page", Vector3(0.22, 0.018, 0.16), Vector3(0.11, 0.015, 0), "paper", Vector3(0, 0, 0.08))
	_box(root, "cover", Vector3(0.46, 0.018, 0.17), Vector3(0, -0.012, 0), "wood")
	for z in [-0.04, -0.015, 0.01, 0.035]:
		_box(root, "ink_left", Vector3(0.13, 0.002, 0.003), Vector3(-0.11, 0.026, z), "dark")
		_box(root, "ink_right", Vector3(0.13, 0.002, 0.003), Vector3(0.11, 0.026, z), "dark")
	return root

func _build_papers() -> Node3D:
	var root := _root("PaperStack")
	for i in 5:
		var shift := float(i) * 0.006
		_box(root, "loose_paper", Vector3(0.25, 0.003, 0.18), Vector3(shift, float(i) * 0.004, -shift), "paper", Vector3(0, float(i - 2) * 0.025, float(i - 2) * 0.012))
	for line in 4:
		_box(root, "ink_line", Vector3(0.14, 0.001, 0.002), Vector3(0.0, 0.026, -0.045 + float(line) * 0.024), "dark")
	return root

func _build_clothes() -> Node3D:
	var root := _root("ClothesPile")
	_sphere(root, "folded_sweater", Vector3(0.38, 0.11, 0.3), Vector3(0, 0.07, 0), "fabric")
	_sphere(root, "shirt_fold", Vector3(0.3, 0.08, 0.25), Vector3(-0.08, 0.14, 0.02), "cloth", Vector3(0, 0, -0.12))
	_capsule(root, "trouser_leg", 0.055, 0.36, Vector3(0.12, 0.06, 0.03), "dark", Vector3(0, 0, PI / 2), 10)
	return root

func _build_toy_truck() -> Node3D:
	var root := _root("OldToyTruck")
	_box(root, "tin_body", Vector3(0.22, 0.09, 0.12), Vector3(0, 0.06, 0), "rust")
	_box(root, "cab", Vector3(0.09, 0.085, 0.11), Vector3(-0.035, 0.145, 0), "rust")
	_box(root, "window", Vector3(0.06, 0.05, 0.008), Vector3(-0.035, 0.15, 0.058), "glass")
	for x in [-0.075, 0.075]:
		for z in [-0.065, 0.065]:
			_cylinder(root, "metal_wheel", 0.035, 0.035, 0.018, Vector3(x, 0.03, z), "dark", Vector3(PI / 2, 0, 0), 12)
	return root

func _build_photo_frame() -> Node3D:
	var root := _root("PhotoFrame")
	_box(root, "wood_frame_left", Vector3(0.035, 0.36, 0.04), Vector3(-0.17, 0, 0), "wood")
	_box(root, "wood_frame_right", Vector3(0.035, 0.36, 0.04), Vector3(0.17, 0, 0), "wood")
	_box(root, "wood_frame_top", Vector3(0.36, 0.035, 0.04), Vector3(0, 0.17, 0), "wood")
	_box(root, "wood_frame_bottom", Vector3(0.36, 0.035, 0.04), Vector3(0, -0.17, 0), "wood")
	_box(root, "photo_surface", Vector3(0.29, 0.29, 0.012), Vector3(0, 0, 0.01), "paper")
	_sphere(root, "photo_silhouette", Vector3(0.11, 0.14, 0.006), Vector3(-0.055, -0.015, 0.02), "dark")
	_sphere(root, "photo_silhouette_2", Vector3(0.095, 0.12, 0.006), Vector3(0.075, -0.035, 0.02), "wood")
	return root

func _build_calendar() -> Node3D:
	var root := _root("AugustCalendar")
	_box(root, "backing", Vector3(0.38, 0.54, 0.025), Vector3(0, 0, 0), "paper")
	_box(root, "header", Vector3(0.38, 0.12, 0.035), Vector3(0, 0.21, 0.02), "wood")
	for row in 5:
		_box(root, "calendar_row", Vector3(0.31, 0.004, 0.002), Vector3(0, 0.1 - float(row) * 0.075, 0.022), "dark")
	for column in 6:
		_box(root, "calendar_column", Vector3(0.002, 0.36, 0.002), Vector3(-0.13 + float(column) * 0.052, -0.06, 0.022), "dark")
	_box(root, "marked_day_9", Vector3(0.035, 0.035, 0.004), Vector3(-0.05, -0.065, 0.026), "rust")
	for x in [-0.12, -0.06, 0.0, 0.06, 0.12]:
		_cylinder(root, "wire_binding", 0.009, 0.009, 0.03, Vector3(x, 0.29, 0.035), "metal", Vector3(PI / 2, 0, 0), 8)
	return root

func _build_perfume() -> Node3D:
	var root := _root("PerfumeBottle")
	_cylinder(root, "glass_bottle", 0.055, 0.07, 0.14, Vector3(0, 0.08, 0), "glass", Vector3.ZERO, 16)
	_cylinder(root, "neck", 0.024, 0.03, 0.04, Vector3(0, 0.17, 0), "glass", Vector3.ZERO, 12)
	_box(root, "label", Vector3(0.065, 0.055, 0.003), Vector3(0, 0.08, 0.071), "paper")
	_cylinder(root, "cap", 0.03, 0.03, 0.035, Vector3(0, 0.21, 0), "metal", Vector3.ZERO, 12)
	return root

func _build_comb() -> Node3D:
	var root := _root("Comb")
	_box(root, "handle", Vector3(0.045, 0.16, 0.012), Vector3(0, -0.02, 0), "dark", Vector3(0, 0, -0.2))
	_box(root, "back", Vector3(0.16, 0.035, 0.012), Vector3(0, 0.075, 0), "dark")
	for i in 11:
		_box(root, "tooth", Vector3(0.006, 0.05, 0.008), Vector3(-0.075 + float(i) * 0.015, 0.035, 0), "dark")
	return root

func _build_shoeboxes() -> Node3D:
	var root := _root("AbandonedShoeboxes")
	_box(root, "box_bottom", Vector3(0.36, 0.13, 0.25), Vector3(0, 0.07, 0), "paper")
	_box(root, "box_lid", Vector3(0.38, 0.035, 0.27), Vector3(0, 0.16, 0), "paper")
	_box(root, "second_box", Vector3(0.32, 0.12, 0.22), Vector3(0.06, 0.28, -0.015), "paper", Vector3(0, 0.08, 0.04))
	return root

func _build_crucifix() -> Node3D:
	var root := _root("WallCrucifix")
	_box(root, "cross_vertical", Vector3(0.055, 0.38, 0.025), Vector3(0, 0, 0), "wood")
	_box(root, "cross_horizontal", Vector3(0.23, 0.055, 0.025), Vector3(0, 0.07, 0), "wood")
	return root
func _build_table() -> Node3D:
	var root := _root("Table80s")
	for x in [-0.54, 0.54]:
		for z in [-0.28, 0.28]:
			_box(root, "wood_leg", Vector3(0.075, 0.72, 0.075), Vector3(x, 0.36, z), "wood")
	_box(root, "front_apron", Vector3(1.08, 0.15, 0.045), Vector3(0, 0.62, 0.27), "wood")
	_box(root, "back_apron", Vector3(1.08, 0.15, 0.045), Vector3(0, 0.62, -0.27), "wood")
	_box(root, "left_apron", Vector3(0.045, 0.15, 0.5), Vector3(-0.54, 0.62, 0), "wood")
	_box(root, "right_apron", Vector3(0.045, 0.15, 0.5), Vector3(0.54, 0.62, 0), "wood")
	_box(root, "solid_top", Vector3(1.24, 0.075, 0.72), Vector3(0, 0.735, 0), "wood")
	_box(root, "top_edge", Vector3(1.28, 0.025, 0.76), Vector3(0, 0.685, 0), "wood")
	return root


func _build_sofa() -> Node3D:
	var root := _root("Sofa80s")
	for x in [-0.88, 0.88]:
		for z in [-0.31, 0.31]:
			_box(root, "short_wood_foot", Vector3(0.09, 0.16, 0.09), Vector3(x, 0.08, z), "wood")
	_box(root, "upholstered_base", Vector3(2.0, 0.34, 0.78), Vector3(0, 0.32, 0), "fabric")
	_box(root, "lower_rail", Vector3(1.94, 0.09, 0.8), Vector3(0, 0.15, 0), "wood")
	_box(root, "back_shell", Vector3(2.0, 0.82, 0.19), Vector3(0, 0.79, -0.31), "fabric")
	_box(root, "seat_cushion_left", Vector3(0.94, 0.16, 0.59), Vector3(-0.48, 0.57, 0.08), "cloth")
	_box(root, "seat_cushion_right", Vector3(0.94, 0.16, 0.59), Vector3(0.48, 0.57, 0.08), "fabric")
	_box(root, "back_cushion_left", Vector3(0.91, 0.58, 0.13), Vector3(-0.49, 0.91, -0.18), "cloth")
	_box(root, "back_cushion_right", Vector3(0.91, 0.58, 0.13), Vector3(0.49, 0.91, -0.18), "fabric")
	_box(root, "left_arm", Vector3(0.24, 0.54, 0.82), Vector3(-1.0, 0.61, 0), "fabric")
	_box(root, "right_arm", Vector3(0.24, 0.54, 0.82), Vector3(1.0, 0.61, 0), "fabric")
	for x in [-0.95, 0.95]:
		for y in [0.38, 0.52]:
			_sphere(root, "seam_button", Vector3(0.025, 0.025, 0.012), Vector3(x, y, -0.2), "wood")
	return root


func _build_armchair() -> Node3D:
	var root := _root("Armchair80s")
	for x in [-0.33, 0.33]:
		for z in [-0.3, 0.3]:
			_box(root, "wood_foot", Vector3(0.07, 0.18, 0.07), Vector3(x, 0.09, z), "wood")
	_box(root, "upholstered_base", Vector3(0.82, 0.38, 0.78), Vector3(0, 0.34, 0), "fabric")
	_box(root, "seat_cushion", Vector3(0.69, 0.15, 0.56), Vector3(0, 0.56, 0.09), "cloth")
	_box(root, "back_shell", Vector3(0.82, 0.82, 0.17), Vector3(0, 0.82, -0.3), "fabric")
	_box(root, "back_cushion", Vector3(0.65, 0.6, 0.12), Vector3(0, 0.86, -0.19), "cloth")
	_box(root, "left_arm", Vector3(0.15, 0.46, 0.72), Vector3(-0.42, 0.62, 0), "fabric")
	_box(root, "right_arm", Vector3(0.15, 0.46, 0.72), Vector3(0.42, 0.62, 0), "fabric")
	return root


func _build_bench() -> Node3D:
	var root := _root("Bench80s")
	for x in [-0.58, 0.58]:
		for z in [-0.14, 0.14]:
			_box(root, "square_leg", Vector3(0.07, 0.42, 0.07), Vector3(x, 0.21, z), "wood")
	_box(root, "seat", Vector3(1.34, 0.09, 0.38), Vector3(0, 0.46, 0), "wood")
	_box(root, "underside_rail", Vector3(1.18, 0.07, 0.08), Vector3(0, 0.37, 0), "wood")
	return root


func _build_metal_shelf() -> Node3D:
	var root := _root("MetalShelf80s")
	for x in [-0.62, 0.62]:
		for z in [-0.16, 0.16]:
			_box(root, "upright", Vector3(0.035, 1.82, 0.035), Vector3(x, 0.91, z), "metal")
	for y in [0.12, 0.54, 0.96, 1.38, 1.78]:
		_box(root, "steel_shelf", Vector3(1.3, 0.045, 0.4), Vector3(0, y, 0), "metal")
		_box(root, "front_lip", Vector3(1.3, 0.045, 0.025), Vector3(0, y + 0.025, 0.19), "rust")
	for x in [-0.62, 0.62]:
		_box(root, "diagonal_brace", Vector3(0.025, 1.25, 0.025), Vector3(x, 0.9, 0.18), "metal", Vector3(0, 0, 0.18))
	return root


func _build_sideboard() -> Node3D:
	var root := _root("Sideboard80s")
	_box(root, "carcass", Vector3(1.36, 0.72, 0.46), Vector3(0, 0.42, 0), "wood")
	_box(root, "top", Vector3(1.46, 0.065, 0.54), Vector3(0, 0.81, 0), "wood")
	for x in [-0.43, 0, 0.43]:
		_box(root, "drawer_front", Vector3(0.38, 0.18, 0.035), Vector3(x, 0.66, 0.25), "wood")
		_cylinder(root, "drawer_pull", 0.018, 0.018, 0.035, Vector3(x, 0.66, 0.278), "metal", Vector3(PI / 2, 0, 0), 10)
	for x in [-0.48, 0.48]:
		_box(root, "lower_door", Vector3(0.39, 0.33, 0.035), Vector3(x, 0.31, 0.25), "wood")
		_cylinder(root, "door_knob", 0.018, 0.018, 0.035, Vector3(x + 0.12, 0.31, 0.278), "metal", Vector3(PI / 2, 0, 0), 10)
	for x in [-0.54, 0.54]:
		_box(root, "short_foot", Vector3(0.09, 0.12, 0.09), Vector3(x, 0.06, 0.16), "wood")
	return root


func _build_crate() -> Node3D:
	var root := _root("WoodCrate80s")
	_box(root, "bottom", Vector3(0.52, 0.055, 0.42), Vector3(0, 0.03, 0), "wood")
	for x in [-0.24, 0.24]:
		for z in [-0.19, 0.19]:
			_box(root, "corner_post", Vector3(0.05, 0.38, 0.05), Vector3(x, 0.22, z), "wood")
	for y in [0.09, 0.2, 0.31]:
		_box(root, "front_slats", Vector3(0.5, 0.07, 0.035), Vector3(0, y, 0.2), "wood")
		_box(root, "back_slats", Vector3(0.5, 0.07, 0.035), Vector3(0, y, -0.2), "wood")
		_box(root, "left_slats", Vector3(0.035, 0.07, 0.38), Vector3(-0.24, y, 0), "wood")
		_box(root, "right_slats", Vector3(0.035, 0.07, 0.38), Vector3(0.24, y, 0), "wood")
	return root