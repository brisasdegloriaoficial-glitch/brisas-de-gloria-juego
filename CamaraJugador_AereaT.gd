extends Camera

export(NodePath) var objetivo_posicion
export(NodePath) var objetivo_direccion
export var altura = 5.0
export var adelante = 25.0
export var angulo_extra = 0.0
export var angulo_giro_maximo = 30.0
export var velocidad_giro = 0.4

var pos_ref: Spatial
var dir_ref: Spatial
var _tiempo = 0.0


func _ready():
	if objetivo_posicion:
		pos_ref = get_node(objetivo_posicion)
	if objetivo_direccion:
		dir_ref = get_node(objetivo_direccion)


func _process(delta):
	if not pos_ref or not dir_ref:
		return
	_tiempo += delta
	var hacia_adelante = -dir_ref.global_transform.basis.z.normalized()
	global_transform.origin = pos_ref.global_transform.origin \
		+ hacia_adelante * adelante \
		+ Vector3(0, altura, 0)
	look_at(global_transform.origin + hacia_adelante, Vector3.UP)
	var giro = sin(_tiempo * velocidad_giro) * angulo_giro_maximo
	rotate_object_local(Vector3.UP, deg2rad(angulo_extra + giro))
