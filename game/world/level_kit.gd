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
