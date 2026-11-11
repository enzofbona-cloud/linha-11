extends GutTest
## Regressoes para os modelos PBR CC0 incorporados nos dois apartamentos.

const POLYHAVEN_MODELS := [
	"res://assets/models/polyhaven/vintage_day_bed/vintage_day_bed_1k.gltf",
	"res://assets/models/polyhaven/sofa_02/sofa_02_1k.gltf",
	"res://assets/models/polyhaven/painted_wooden_nightstand/painted_wooden_nightstand_1k.gltf",
	"res://assets/models/polyhaven/painted_wooden_cabinet/painted_wooden_cabinet_1k.gltf",
	"res://assets/models/polyhaven/WoodenTable_01/WoodenTable_01_1k.gltf",
	"res://assets/models/polyhaven/Shelf_01/Shelf_01_1k.gltf",
	"res://assets/models/polyhaven/GothicCabinet_01/GothicCabinet_01_1k.gltf",
	"res://assets/models/polyhaven/ArmChair_01/ArmChair_01_1k.gltf",
	"res://assets/models/polyhaven/painted_wooden_chair_02/painted_wooden_chair_02_1k.gltf",
]


func test_polyhaven_models_keep_their_uv_pbr_materials() -> void:
	for path in POLYHAVEN_MODELS:
		var visual := LevelKit.model_visual(path)
		var meshes := visual.find_children("*", "MeshInstance3D", true, false)
		assert_gt(meshes.size(), 0, path)
		for candidate in meshes:
			var mesh := candidate as MeshInstance3D
			assert_null(mesh.material_override, "%s must keep its imported surface materials" % path)
			for surface in mesh.mesh.get_surface_count():
				var material := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
				assert_not_null(material, "%s surface %d needs a PBR material" % [path, surface])
				if material == null:
					continue
				assert_not_null(material.albedo_texture, "%s surface %d needs its color map" % [path, surface])
				assert_not_null(material.normal_texture, "%s surface %d needs its normal map" % [path, surface])
		visual.free()


func test_polyhaven_models_stay_within_the_scene_triangle_budget() -> void:
	for path in POLYHAVEN_MODELS:
		var visual := LevelKit.model_visual(path)
		var triangle_count := 0
		for candidate in visual.find_children("*", "MeshInstance3D", true, false):
			var mesh := (candidate as MeshInstance3D).mesh
			triangle_count += mesh.get_faces().size() / 3
		assert_lt(triangle_count, 15001, "%s exceeds 15,000 triangles" % path)
		visual.free()


func test_aged_room_materials_load_their_pbr_maps() -> void:
	var floor := LevelKit.textured("floor_aged", 0.4)
	assert_not_null(floor.albedo_texture)
	assert_not_null(floor.normal_texture)
	assert_not_null(floor.roughness_texture)
	var wall := LevelKit.textured("wall_aged", 0.33)
	assert_not_null(wall.albedo_texture)
	assert_not_null(wall.normal_texture)
	assert_not_null(wall.roughness_texture)
	assert_true(wall.ao_enabled)
	assert_not_null(wall.ao_texture)


func test_ouvinte_usa_corpo_3d_articulado_com_passo_sincronizado() -> void:
	var listener := Listener.new()
	add_child_autofree(listener)
	var meshes := listener.find_children("*", "MeshInstance3D", true, false)
	assert_gte(meshes.size(), 20, "a criatura precisa de volume 3D, mãos e membros articulados")
	assert_not_null(listener.find_child("LeftArm", true, false))
	assert_not_null(listener.find_child("RightArm", true, false))
	assert_not_null(listener.find_child("LeftLeg", true, false))
	assert_not_null(listener.find_child("RightLeg", true, false))
	assert_null(listener.find_child("CreatureSprite", true, false), "não deve voltar ao billboard 2.5D")
	listener.position.z = -8.0
	listener.z_min = -15.0
	listener.z_max = -1.0
	listener.wake()
	var phase_before: float = listener.animation_state().gait_phase
	listener.tick(0.1, Vector3(0, 0, -12))
	assert_gt(listener.animation_state().gait_phase, phase_before, "a passada avança com a distância percorrida")
	assert_gt(listener.animation_state().walk, 0.0, "a animação sai suavemente do repouso")
	assert_ne((listener.find_child("LeftLeg", true, false) as Node3D).rotation.x, 0.0,
		"as articulações respondem à passada")
	assert_eq(listener.physics_interpolation_mode, Node.PHYSICS_INTERPOLATION_MODE_ON)


func test_ouvinte_usa_mapas_pbr_em_pele_e_roupa() -> void:
	var listener := Listener.new()
	add_child_autofree(listener)
	var skin := listener.get("_skin") as StandardMaterial3D
	assert_not_null(skin.albedo_texture)
	assert_not_null(skin.normal_texture)
	assert_not_null(skin.roughness_texture)
	assert_gt(skin.roughness, 0.9)
	var coat := listener.find_child("TornCoat", true, false) as MeshInstance3D
	assert_not_null(coat)
	assert_true(coat.material_override is StandardMaterial3D)


func test_tint_de_material_preserva_textura_importada_e_nao_altera_a_origem() -> void:
	var visual := LevelKit.model_visual("res://assets/models/polyhaven/vintage_day_bed/vintage_day_bed_1k.gltf")
	var meshes := visual.find_children("*", "MeshInstance3D", true, false)
	assert_gt(meshes.size(), 0)
	var mesh := meshes[0] as MeshInstance3D
	var original := mesh.get_active_material(0) as StandardMaterial3D
	var original_color := original.albedo_color
	var original_texture := original.albedo_texture
	LevelKit.tint_model_surfaces(visual, Color(0.78, 0.73, 0.66), 0.9)
	var adjusted := mesh.get_active_material(0) as StandardMaterial3D
	assert_ne(adjusted, original)
	assert_ne(adjusted.albedo_color, original_color)
	assert_eq(adjusted.albedo_texture, original_texture)
	assert_gte(adjusted.roughness, 0.9)
	assert_eq(original.albedo_color, original_color, "o material partilhado importado fica intacto")
	visual.free()
