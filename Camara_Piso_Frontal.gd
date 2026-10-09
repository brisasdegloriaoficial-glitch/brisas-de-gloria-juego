extends Camera

# ============================================================
# CAMARA DE PARTIDA - DIAGONAL, ADELANTE DEL APARATO
# ============================================================
# Se para en la parte DELANTERA del aparato de partida, corrida
# en diagonal hacia un costado, y mira para atras al lote. Los
# caballos salen de la gatera hacia la camara, en tres cuartos.
# Despues los sigue manteniendo esa misma diagonal.
#
# El angulo es regulable:
#   0   = de frente, de punta (NO es lo que se busca)
#   35  = tres cuartos delantero - la toma de partida
#   85  = casi de costado
# Nunca se pasa de 85, asi que la camara siempre queda adelante,
# nunca detras del aparato.
# ============================================================

export(NodePath) var objetivo_node

# --- La toma ---
# Cuanto se abre la camara hacia el costado, en grados.
export var angulo_diagonal = 35.0

# Si la diagonal te queda del lado equivocado de la pista,
# tildalo. Es lo unico que hay que tocar para cambiar de lado.
export var invertir_lado = false

# A que distancia del lote se para.
export var distancia = 45.0 setget set_distancia

# Altura de la camara y altura del punto que mira.
export var altura_camara = 10.0
export var altura_de_mira = 1.5

# Prendido = mira al lote, pero NUNCA a los que vienen detras de tu
# caballo: si el lote queda atras, se centra en ti. Apagado = sigue
# solo a tu caballo.
export var seguir_a_todo_el_lote = true
# Cuanto se deja llevar por el lote cuando la camara esta lejos.
# 0 = siempre tu caballo; 1 = el lote (sin pasar nunca atras de ti).
# Al acercar con el zoom, se va centrando sola en tu caballo.
export var peso_del_lote = 1.0

# Escribe una linea por segundo en el panel de Salida con las
# posiciones. Solo para cuando algo no se ve.
export var mostrar_diagnostico = false

# --- Zoom (pellizco en el telefono, rueda en la PC) ---
export var distancia_minima = 10.0
export var distancia_maxima = 160.0
export var velocidad_zoom = 0.4
export var velocidad_zoom_rueda = 40.0
export var suavidad_zoom = 8.0

var objetivo: Spatial
var _toques = {}
var _distancia_anterior_toque = 0.0
var _zoom_buscado = 45.0
var _enrutadores = []
var _busque = false
var _reloj_diagnostico = 0.0
var _avise_problema = false
var _modelo = null


func _ready():
	distancia = clamp(distancia, distancia_minima, distancia_maxima)
	_zoom_buscado = distancia


func set_distancia(valor):
	distancia = clamp(valor, distancia_minima, distancia_maxima)
	_zoom_buscado = distancia


# Busca al caballo del jugador. Primero por lo que diga el
# Inspector; si eso viene vacio, lo busca por nombre en la escena.
func _conseguir_objetivo():
	if objetivo and is_instance_valid(objetivo):
		return

	if objetivo_node:
		var n = get_node_or_null(objetivo_node)
		if n and n is Spatial:
			objetivo = n
			return

	var encontrado = get_tree().get_root().find_node("Enrutador_Caballo1", true, false)
	if encontrado and encontrado is Spatial:
		objetivo = encontrado
		return

	if not _avise_problema:
		_avise_problema = true
		print("[BDG-CamaraPartida] NO SE ENCONTRO Enrutador_Caballo1.")


func _process(delta):
	_conseguir_objetivo()
	if not objetivo:
		return

	distancia = lerp(distancia, _zoom_buscado, min(suavidad_zoom * delta, 1.0))

	var centro = _centro_del_lote()
	var adelante = _direccion_de_carrera()

	# El angulo se limita a 85 para que la camara NUNCA termine
	# detras del aparato de partida.
	var grados = clamp(angulo_diagonal, 0.0, 85.0)
	if invertir_lado:
		grados = -grados
	var direccion = adelante.rotated(Vector3.UP, deg2rad(grados))

	global_transform.origin = centro \
		+ direccion * distancia \
		+ Vector3(0, altura_camara, 0)

	var punto_mira = centro + Vector3(0, altura_de_mira, 0)
	if global_transform.origin.distance_to(punto_mira) > 0.1:
		look_at(punto_mira, Vector3.UP)

	if mostrar_diagnostico:
		_reloj_diagnostico += delta
		if _reloj_diagnostico >= 1.0:
			_reloj_diagnostico = 0.0
			print("[BDG-CamaraPartida] lote en=", centro,
				" | camara en=", global_transform.origin,
				" | angulo=", grados)


# ------------------------------------------------------------
# Donde esta el lote
# ------------------------------------------------------------
func _centro_del_lote() -> Vector3:
	_buscar_enrutadores()
	var jugador = _centro_jugador()

	if not seguir_a_todo_el_lote or _enrutadores.size() == 0:
		return jugador

	var suma = Vector3.ZERO
	var cuantos = 0
	for e in _enrutadores:
		if is_instance_valid(e):
			suma += e.global_transform.origin
			cuantos += 1
	if cuantos == 0:
		return jugador
	var lote = suma / cuantos
	# Nunca mas atras que tu caballo: si el lote va detras, se corre
	# hacia adelante hasta quedar a tu altura.
	var adelante = _direccion_de_carrera()
	var avance = (lote - jugador).dot(adelante)
	if avance < 0.0:
		lote -= adelante * avance
	# Lejos = mira al lote; cerca = mira a tu caballo.
	var rango = max(distancia_maxima - distancia_minima, 0.001)
	var t = clamp((distancia - distancia_minima) / rango, 0.0, 1.0)
	return jugador.linear_interpolate(lote, t * clamp(peso_del_lote, 0.0, 1.0))


# Centro del caballo del jugador que se ve (no el punto del enrutador,
# que queda corrido unos metros).
func _centro_jugador() -> Vector3:
	var p = objetivo.global_transform.origin
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


func _buscar_enrutadores():
	if _busque:
		return
	_busque = true
	_enrutadores.clear()
	var pista = objetivo.get_parent()
	if not pista:
		return
	for hijo in pista.get_children():
		if hijo is Spatial and str(hijo.name).begins_with("Enrutador_Caballo"):
			_enrutadores.append(hijo)


# ------------------------------------------------------------
# Hacia donde se corre. Se lo pregunta a la pista.
# ------------------------------------------------------------
func _direccion_de_carrera() -> Vector3:
	var pista = objetivo.get_parent()
	if pista and ("curve" in pista) and pista.curve:
		var largo = pista.curve.get_baked_length()
		if largo > 0.0:
			var aca = fposmod(objetivo.offset, largo)
			var p0 = pista.to_global(pista.curve.interpolate_baked(aca))
			var p1 = pista.to_global(pista.curve.interpolate_baked(fposmod(aca + 2.0, largo)))
			var avance = p1 - p0
			avance.y = 0.0
			if avance.length() > 0.001:
				return avance.normalized()
	var respaldo = -objetivo.global_transform.basis.z
	respaldo.y = 0.0
	if respaldo.length() < 0.001:
		return Vector3(0, 0, -1)
	return respaldo.normalized()


func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			_toques[event.index] = event.position
		else:
			_toques.erase(event.index)
			_distancia_anterior_toque = 0.0

	elif event is InputEventScreenDrag:
		_toques[event.index] = event.position

		if _toques.size() == 2:
			var puntos = _toques.values()
			var distancia_actual_toque = puntos[0].distance_to(puntos[1])

			if _distancia_anterior_toque > 0.0:
				var diferencia = distancia_actual_toque - _distancia_anterior_toque
				_zoom_buscado -= diferencia * velocidad_zoom
				_zoom_buscado = clamp(_zoom_buscado, distancia_minima, distancia_maxima)

			_distancia_anterior_toque = distancia_actual_toque

	elif event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_WHEEL_UP:
				_zoom_buscado -= velocidad_zoom_rueda
			elif event.button_index == BUTTON_WHEEL_DOWN:
				_zoom_buscado += velocidad_zoom_rueda
			_zoom_buscado = clamp(_zoom_buscado, distancia_minima, distancia_maxima)
