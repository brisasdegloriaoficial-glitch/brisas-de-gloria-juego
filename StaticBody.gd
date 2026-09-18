tool
extends StaticBody

export (NodePath) var mesh_instance_node
export (NodePath) var collision_shape_node
export var regenerar_colision = false setget set_regenerar_colision

func set_regenerar_colision(valor):
	if valor:
		generar_colision()
	regenerar_colision = false

func generar_colision():
	if mesh_instance_node == null or mesh_instance_node == NodePath(""):
		return
	if collision_shape_node == null or collision_shape_node == NodePath(""):
		return

	var mesh_nodo = get_node(mesh_instance_node)
	var shape_nodo = get_node(collision_shape_node)

	if mesh_nodo == null or shape_nodo == null:
		return
	if mesh_nodo.mesh == null:
		return

	var nueva_forma = ConcavePolygonShape.new()
	nueva_forma.set_faces(mesh_nodo.mesh.get_faces())
	shape_nodo.shape = nueva_forma
