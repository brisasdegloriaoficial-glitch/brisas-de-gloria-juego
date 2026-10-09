extends Camera

# Camara por encima del jinete (tercera persona alta), sigue al jugador.
# Objetivo Posicion: el caballo visible (Caballo_Americano_Completo).
# Objetivo Direccion: el enrutador (..), que marca hacia donde corre.
# Subir y bajar: ruedita del raton (hacia arriba = sube) y pellizco
# en el telefono. Nunca baja de donde nace (altura).
export(NodePath) var objetivo_posicion
export(NodePath) var objetivo_direccion
export var altura = 16.0            # donde nace la camara (la mas baja)
export var adelante = 6.0           # hacia adelante (negativo = atras)
export var lado = 7.0               # hacia la derecha (negativo = izquierda)
export var mirar_abajo = 25.0       # grados: inclina la vista hacia abajo
export var angulo_extra = 0.0       # grados: gira la vista (negativo = derecha)
export var angulo_giro_maximo = 0.0 # vaiven de lado a lado (0 = sin vaiven)
export var velocidad_giro = 0.4

# --- Subir y bajar ---
export var altura_maxima = 60.0      # lo mas alto que puede subir
export var mirar_abajo_arriba = 55.0 # grados hacia abajo cuando esta en lo mas alto
export var paso_rueda = 4.0          # cuanto sube cada vuelta de la ruedita
export var velocidad_pellizco = 0.1  # cuanto sube el pellizco en el telefono
export var suavidad_subida = 8.0

# --- Movimiento parejo ---
# La camara se mueve DESPUES de que se movieron todos los caballos,
# asi no se ven saltitos entre un cuadro y otro. Mas alto = mas tarde.
export var orden_de_movimiento = 100

var pos_ref: Spatial
var dir_ref: Spatial
var _tiempo = 0.0
var _subida = 0.0
var _subida_buscada = 0.0
var _toques = {}
var _distancia_anterior = 0.0


func _ready():
	process_priority = orden_de_movimiento
	if objetivo_posicion:
		pos_ref = get_node(objetivo_posicion)
	if objetivo_direccion:
		dir_ref = get_node(objetivo_direccion)


func _process(delta):
	if not pos_ref or not dir_ref:
		return
	_tiempo += delta
	_subida_buscada = clamp(_subida_buscada, 0.0, max(0.0, altura_maxima - altura))
	_subida = lerp(_subida, _subida_buscada, min(suavidad_subida * delta, 1.0))
	var hacia_adelante = -dir_ref.global_transform.basis.z.normalized()
	var hacia_derecha = dir_ref.global_transform.basis.x.normalized()
	global_transform.origin = pos_ref.global_transform.origin \
		+ hacia_adelante * adelante \
		+ hacia_derecha * lado \
		+ Vector3(0, altura + _subida, 0)
	look_at(global_transform.origin + hacia_adelante, Vector3.UP)
	var giro = sin(_tiempo * velocidad_giro) * angulo_giro_maximo
	rotate_object_local(Vector3.UP, deg2rad(angulo_extra + giro))
	var tramo = 0.0
	if altura_maxima > altura:
		tramo = _subida / (altura_maxima - altura)
	rotate_object_local(Vector3.RIGHT, deg2rad(-lerp(mirar_abajo, mirar_abajo_arriba, tramo)))


# Solo responde cuando esta es la camara que se esta viendo.
func _input(event):
	if not current:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_toques[event.index] = event.position
		else:
			_toques.erase(event.index)
			_distancia_anterior = 0.0
	elif event is InputEventScreenDrag:
		_toques[event.index] = event.position
		if _toques.size() == 2:
			var puntos = _toques.values()
			var actual = puntos[0].distance_to(puntos[1])
			if _distancia_anterior > 0.0:
				_subida_buscada -= (actual - _distancia_anterior) * velocidad_pellizco
			_distancia_anterior = actual
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_WHEEL_UP:
			_subida_buscada += paso_rueda
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_subida_buscada -= paso_rueda
