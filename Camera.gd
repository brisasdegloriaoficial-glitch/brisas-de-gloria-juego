extends Camera

export(NodePath) var objetivo_node
export var altura = 160.0 setget set_altura
export var altura_minima = 25.0
export var altura_maxima = 350.0
export var velocidad_zoom = 0.4
export var velocidad_zoom_rueda = 40.0
export var suavidad_zoom = 8.0
# Encendido = la camara se centra en el CUERPO del caballo del jugador
# (el modelo que se ve), no en el punto del enrutador, que queda
# corrido. Asi, por mas que acerques, tu caballo queda en el centro.
export var centrar_en_caballo = true
# Correccion fina por si quieres el caballo un poco mas arriba o abajo
# en pantalla (adelante/atras en la pista). 0 = justo al centro.
export var ajuste_adelante = 0.0

var objetivo: Spatial
var _toques = {}
var _distancia_anterior = 0.0
var _altura_objetivo = 160.0
var _modelo = null


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	if objetivo_node:
		objetivo = get_node(objetivo_node)
	altura = clamp(altura, altura_minima, altura_maxima)
	_altura_objetivo = altura
	_colocar_camara()


func set_altura(valor):
	altura = clamp(valor, altura_minima, altura_maxima)
	_altura_objetivo = valor


func _colocar_camara():
	if objetivo:
		global_transform.origin = _punto_objetivo() + Vector3(0, altura, 0)
		rotation_degrees = Vector3(-90, 0, 0)


# Centro del caballo que se ve (el hijo "Caballo..." visible del enrutador).
func _punto_objetivo() -> Vector3:
	var p = objetivo.global_transform.origin
	if not centrar_en_caballo:
		return p
	if _modelo == null or not is_instance_valid(_modelo) or not _modelo.is_visible_in_tree():
		_modelo = null
		for h in objetivo.get_children():
			if h is Spatial and h.name.begins_with("Caballo") and h.is_visible_in_tree():
				_modelo = h
				break
	if _modelo == null:
		return p
	var caja = _caja(_modelo)
	if caja == null:
		return p
	var centro = caja.position + caja.size * 0.5
	var adelante = -objetivo.global_transform.basis.z.normalized()
	return Vector3(centro.x, p.y, centro.z) + adelante * ajuste_adelante


func _caja(n):
	var total = null
	for h in n.get_children():
		if h is VisualInstance and h.is_visible_in_tree() and h is MeshInstance:
			var c = h.get_transformed_aabb()
			total = c if total == null else total.merge(c)
		var sub = _caja(h)
		if sub != null:
			total = sub if total == null else total.merge(sub)
	return total


func _process(delta):
	altura = lerp(altura, _altura_objetivo, min(suavidad_zoom * delta, 1.0))
	_colocar_camara()


func _input(event):
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
			var distancia_actual = puntos[0].distance_to(puntos[1])

			if _distancia_anterior > 0.0:
				var diferencia = distancia_actual - _distancia_anterior
				_altura_objetivo += diferencia * velocidad_zoom
				_altura_objetivo = clamp(_altura_objetivo, altura_minima, altura_maxima)

			_distancia_anterior = distancia_actual

	elif event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_WHEEL_UP:
				_altura_objetivo -= velocidad_zoom_rueda
			elif event.button_index == BUTTON_WHEEL_DOWN:
				_altura_objetivo += velocidad_zoom_rueda
			_altura_objetivo = clamp(_altura_objetivo, altura_minima, altura_maxima)
