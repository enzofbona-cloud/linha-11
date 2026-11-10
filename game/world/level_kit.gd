class_name LevelKit
## Peças básicas para montar cenários por código: materiais e caixas com colisão.
## É provisório (blocagem): os modelos e texturas finais entram nas fases de arte.

static var _grime: NoiseTexture2D


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
