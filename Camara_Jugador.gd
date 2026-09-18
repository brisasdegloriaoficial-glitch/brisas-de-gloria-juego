extends Camera

export(NodePath) var objetivo_path
export var distancia = 8.0
export var altura = 3.0
export var angulo_extra = 0.0

onready var objetivo: Spatial = get_node(objetivo_path)

func _process(delta):
	if not objetivo:
		return
	var atras = objetivo.global_transform.basis.z.normalized()
	global_transform.origin = objetivo.global_transform.origin + atras * distancia + Vector3(0, altura, 0)
	look_at(objetivo.global_transform.origin + Vector3(0, 1.5, 0), Vector3.UP)
	rotate_object_local(Vector3.UP, deg2rad(angulo_extra))
