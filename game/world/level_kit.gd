class_name LevelKit
## Utilitários de cenário e materiais PBR usados pelos capítulos 1 e 2.

static var _grime: NoiseTexture2D
static var _model_materials: Dictionary = {}


## Instancia o modelo. Assets Poly Haven mantêm os materiais e UVs PBR originais;
## as malhas procedurais do projeto recebem os materiais PBR locais.
static func model_visual(path: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Não foi possível carregar o modelo: %s" % path)
		return Node3D.new()
	var visual := packed.instantiate() as Node3D
	if not path.begins_with("res://assets/models/polyhaven/"):
		apply_model_materials(visual)
	return visual


static func tint_model_surfaces(root: Node, tint: Color, min_roughness := 0.0) -> void:
	for candidate in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := candidate as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.get_active_material(surface) as StandardMaterial3D
			if original == null:
				continue
			var adjusted := original.duplicate() as StandardMaterial3D
			adjusted.albedo_color *= tint
			adjusted.roughness = maxf(adjusted.roughness, min_roughness)
			mesh.set_surface_override_material(surface, adjusted)


## Aplica texturas PBR locais somente aos modelos procedurais sem mapas próprios.
static func apply_model_materials(root: Node) -> void:
	for candidate in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := candidate as MeshInstance3D
		var profile := mesh.name.get_slice("__", 0).to_lower()
		mesh.material_override = _model_material(profile)


## Crea un mueble con una única colisión de caja, conservando el tamaño indicado.
static func model(parent: Node, node_name: String, path: String, center: Vector3,
		rotation_y: float, collision_size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = center
	body.rotation.y = rotation_y
	var visual := model_visual(path)
	visual.name = "Visual"
	body.add_child(visual)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = collision_size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	return body


static func _model_material(profile: String) -> StandardMaterial3D:
	if _model_materials.has(profile):
		return _model_materials[profile]
	var material: StandardMaterial3D
	match profile:
		"wood":
			material = textured("wood", 0.72, Color(0.78, 0.65, 0.48))
			material.roughness = 0.82
		"fabric", "cloth":
			material = textured("fabric", 0.82, Color(0.72, 0.66, 0.55))
			material.roughness = 0.94
		"metal", "chrome", "rust":
			var tint := Color(0.62, 0.59, 0.52) if profile == "metal" else Color(0.46, 0.39, 0.28)
			material = textured("metal", 0.9, tint)
			material.metallic = 0.58 if profile != "rust" else 0.42
			material.roughness = 0.72
		"paper", "plaster", "porcelain":
			var tint := Color(0.78, 0.72, 0.61) if profile == "paper" else Color(0.83, 0.8, 0.72)
			material = textured("wall", 0.45, tint)
			material.roughness = 0.96 if profile == "paper" else 0.68
		"glass":
			material = StandardMaterial3D.new()
			material.albedo_color = Color(0.36, 0.46, 0.44, 0.38)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.metallic = 0.18
			material.roughness = 0.16
		"rubber", "dark":
			material = textured("door", 0.6, Color(0.24, 0.21, 0.18))
			material.roughness = 0.88
		_:
			material = textured("wood", 0.72, Color(0.78, 0.65, 0.48))
	material.resource_name = "Model_%s" % profile
	_model_materials[profile] = material
	return material


## Textura de ruído compartilhada, usada para tirar a aparência de cor chapada.
static func grime() -> NoiseTexture2D:
	if _grime == null:
		var noise := FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.012
		noise.fractal_octaves = 5
		var ramp := Gradient.new()
		ramp.set_color(0, Color(0.55, 0.53, 0.5))
		ramp.set_color(1, Color(1, 1, 1))
		_grime = NoiseTexture2D.new()
		_grime.width = 256
		_grime.height = 256
		_grime.seamless = true
		_grime.noise = noise
		_grime.color_ramp = ramp
	return _grime


## Material PBR com texturas reais de assets/textures/<nome>/ (cor, normal, rugosidade).
## `tint` multiplica a cor; `uv_scale` é repetições por metro.
static func textured(tex_name: String, uv_scale := 0.5, tint := Color.WHITE) -> StandardMaterial3D:
	var dir := "res://assets/textures/%s/" % tex_name
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.albedo_texture = load(dir + "color.jpg")
	mat.normal_enabled = true
	mat.normal_texture = load(dir + "normal.jpg")
	mat.normal_scale = 0.7
	mat.roughness_texture = load(dir + "roughness.jpg")
	mat.roughness = 1.0
	var ao_path := dir + "ao.jpg"
	if ResourceLoader.exists(ao_path):
		mat.ao_enabled = true
		mat.ao_texture = load(ao_path)
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * uv_scale
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


static func material(color: Color, roughness := 0.9, uv_scale := 0.35) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.albedo_texture = grime()
	mat.roughness = roughness
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * uv_scale
	return mat


## Caixa sólida (parede, piso, móvel) com colisão.
static func box(parent: Node, node_name: String, center: Vector3, size: Vector3, mat: Material, solid := true) -> Node3D:
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	box_mesh.material = mat
	mesh.mesh = box_mesh
	if not solid:
		mesh.name = node_name
		mesh.position = center
		parent.add_child(mesh)
		return mesh
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = center
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	parent.add_child(body)
	return body


## Luminária de teto visível (corpo + difusor aceso) com a luz logo abaixo.
static func ceiling_light(parent: Node, pos: Vector3, color: Color, energy: float, light_range: float, shadows := false) -> OmniLight3D:
	var glow := StandardMaterial3D.new()
	glow.albedo_color = color
	glow.emission_enabled = true
	glow.emission = color
	glow.emission_energy_multiplier = 1.6
	var housing := StandardMaterial3D.new()
	housing.albedo_color = Color(0.2, 0.2, 0.2)
	housing.roughness = 0.6
	box(parent, "LightHousing", pos + Vector3(0, 0.07, 0), Vector3(0.34, 0.06, 1.24), housing, false)
	var diffuser := box(parent, "LightDiffuser", pos + Vector3(0, 0.02, 0), Vector3(0.28, 0.05, 1.18), glow, false)
	var light := lamp(parent, pos + Vector3(0, -0.25, 0), color, energy, light_range, shadows)
	light.set_meta("diffuser", diffuser)
	return light


static func lamp(parent: Node, pos: Vector3, color: Color, energy: float, light_range: float, shadows := false) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.5
	light.shadow_enabled = shadows
	parent.add_child(light)
	return light
