extends Camera

# Camara en primera persona del jugador.
# Objetivo Posicion: el caballo visible (Caballo_Americano_Completo).
# Objetivo Direccion: el enrutador (..), que marca hacia donde corre.
export(NodePath) var objetivo_posicion
export(NodePath) var objetivo_direccion
export var altura = 7.0             # hacia arriba
export var adelante = 1.0           # hacia adelante (negativo = atras)
export var lado = 0.0               # hacia la derecha (negativo = izquierda)
export var mirar_abajo = 0.0        # grados: inclina la vista hacia abajo
export var angulo_extra = 0.0       # grados: gira la vista (negativo = derecha)
export var angulo_giro_maximo = 0.0 # vaiven de lado a lado (0 = sin vaiven)
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
	var hacia_derecha = dir_ref.global_transform.basis.x.normalized()
	global_transform.origin = pos_ref.global_transform.origin \
		+ hacia_adelante * adelante \
		+ hacia_derecha * lado \
		+ Vector3(0, altura, 0)
	look_at(global_transform.origin + hacia_adelante, Vector3.UP)
	var giro = sin(_tiempo * velocidad_giro) * angulo_giro_maximo
	rotate_object_local(Vector3.UP, deg2rad(angulo_extra + giro))
	rotate_object_local(Vector3.RIGHT, deg2rad(-mirar_abajo))
