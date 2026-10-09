extends Camera

# CamaraJugador_LateralD.gd — Camara externa (lado derecho de tu caballo).
# Ahora con zoom: rueda del raton en la PC y pellizco en el telefono.
# Siempre apunta al cuerpo de tu caballo.

export var distancia = 40.0
export var altura = 15.0
export var lado = 1.0
export var adelante = 25.0
export var angulo_extra = 0.0
export var altura_de_mira = 1.5
# Al acercar con el zoom la camara baja, pero nunca de esta altura,
# para que no quede entre las patas de los caballos.
export var altura_minima = 12.0

# --- Zoom ---
# 1 = como estaba. Mas bajo = mas cerca. Mas alto = mas lejos.
export var zoom = 1.0
export var zoom_minimo = 0.25
export var zoom_maximo = 2.5
# Cuanto acerca o aleja cada vuelta de la ruedita.
export var paso_zoom_rueda = 0.12
# Cuanto acerca o aleja el pellizco en el telefono.
export var velocidad_zoom = 0.004
export var suavidad_zoom = 8.0

# Encendido = apunta al cuerpo del caballo que se ve, no al punto del
# enrutador (que queda corrido unos metros).
export var centrar_en_caballo = true

var _zoom_buscado = 1.0
var _toques = {}
var _distancia_anterior = 0.0
var _modelo = null


func _ready():
	zoom = clamp(zoom, zoom_minimo, zoom_maximo)
	_zoom_buscado = zoom


func _process(delta):
	var enrutador = get_parent()
	if enrutador == null:
		return
	zoom = lerp(zoom, _zoom_buscado, min(suavidad_zoom * delta, 1.0))
	var base = _centro_jugador(enrutador)
	var derecha = enrutador.global_transform.basis.x.normalized()
	var hacia_adelante = -enrutador.global_transform.basis.z.normalized()
	global_transform.origin = base \
		+ derecha * distancia * lado * zoom \
		+ hacia_adelante * adelante * zoom \
		+ Vector3(0, max(altura * zoom, altura_minima), 0)
	var mira = base + Vector3(0, altura_de_mira, 0)
	if global_transform.origin.distance_to(mira) > 0.1:
		look_at(mira, Vector3.UP)
	rotate_object_local(Vector3.UP, deg2rad(angulo_extra))


func _centro_jugador(enrutador) -> Vector3:
	var p = enrutador.global_transform.origin
	if not centrar_en_caballo:
		return p
	if _modelo == null or not is_instance_valid(_modelo) or not _modelo.is_visible_in_tree():
		_modelo = null
		for h in enrutador.get_children():
			if h is Spatial and h.name.begins_with("Caballo") and h.is_visible_in_tree():
				_modelo = h
				break
	if _modelo == null:
		return p
	var caja = _caja(_modelo)
	if caja == null:
		return p
	var centro = caja.position + caja.size * 0.5
	return Vector3(centro.x, p.y, centro.z)


func _caja(n):
	var total = null
	for h in n.get_children():
		if h is MeshInstance and h.is_visible_in_tree():
			var c = h.get_transformed_aabb()
			total = c if total == null else total.merge(c)
		var sub = _caja(h)
		if sub != null:
			total = sub if total == null else total.merge(sub)
	return total


# El zoom solo responde cuando esta es la camara que se esta viendo.
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
				_zoom_buscado -= (actual - _distancia_anterior) * velocidad_zoom
				_zoom_buscado = clamp(_zoom_buscado, zoom_minimo, zoom_maximo)
			_distancia_anterior = actual
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_WHEEL_UP:
			_zoom_buscado -= paso_zoom_rueda
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_zoom_buscado += paso_zoom_rueda
		_zoom_buscado = clamp(_zoom_buscado, zoom_minimo, zoom_maximo)
