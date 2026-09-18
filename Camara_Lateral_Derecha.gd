extends Camera

export var distancia = 20.0
export var altura = 10.0
export var lado = 1.0
export var adelante = 0.0
export var angulo_extra = 0.0

func _process(delta):
	var derecha = get_parent().global_transform.basis.x.normalized()
	var hacia_adelante = -get_parent().global_transform.basis.z.normalized()
	global_transform.origin = get_parent().global_transform.origin \
		+ derecha * distancia * lado \
		+ hacia_adelante * adelante \
		+ Vector3(0, altura, 0)
	look_at(get_parent().global_transform.origin + Vector3(0, 1.5, 0), Vector3.UP)
	rotate_object_local(Vector3.UP, deg2rad(angulo_extra))
