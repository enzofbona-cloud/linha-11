extends SceneTree
## Imprime o tamanho (caixa envolvente) de cada modelo de móvel e objeto.
## Uso: godot --headless --path . -s tools/model_sizes.gd


func _init() -> void:
	var paths: Array[String] = []
	for dir in ["res://assets/models/furniture", "res://assets/models/props"]:
		for file in DirAccess.get_files_at(dir):
			if file.ends_with(".glb"):
				paths.append(dir + "/" + file)
	for folder in DirAccess.get_directories_at("res://assets/models/polyhaven"):
		for file in DirAccess.get_files_at("res://assets/models/polyhaven/" + folder):
			if file.ends_with(".gltf"):
				paths.append("res://assets/models/polyhaven/%s/%s" % [folder, file])
	for path in paths:
		var node := (load(path) as PackedScene).instantiate() as Node3D
		var box := AABB()
		var first := true
		for candidate in node.find_children("*", "MeshInstance3D", true, false):
			var mesh := candidate as MeshInstance3D
			var local := _to_root(mesh, node) * mesh.get_aabb()
			box = local if first else box.merge(local)
			first = false
		print("%s  min(%.2f %.2f %.2f)  tam(%.2f %.2f %.2f)" % [path.get_file(),
			box.position.x, box.position.y, box.position.z, box.size.x, box.size.y, box.size.z])
		node.free()
	quit()


func _to_root(node: Node3D, root: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		if current is Node3D:
			xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return root.transform * xform
