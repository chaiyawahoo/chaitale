extends MeshInstance3D


var material: StandardMaterial3D = preload("res://client/hover_cube/hover_cube_material.tres")


func _ready() -> void:
	create_mesh()
	mesh.surface_set_material(0, material)
	visible = false


# from https://github.com/Zylann/godot_debug_draw/blob/master/addons/zylann.debug_draw/debug_draw.gd
func create_mesh() -> void:
	var positions := PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1)
	])
	var indices := PackedInt32Array([
		0, 1, 1, 2, 2, 3, 3, 0,
		4, 5, 5, 6, 6, 7, 7, 4,
		0, 4, 1, 5, 2, 6, 3, 7
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
