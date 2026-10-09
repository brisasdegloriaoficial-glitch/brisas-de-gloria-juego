extends Spatial

export(NodePath) var camara_partida_path
export(NodePath) var camara_aerea_path
export(NodePath) var camara_primera_persona_path
# Camara nueva por encima del jinete. Si se deja vacio, la busca sola
# (CamaraJugador_SobreJinete dentro del enrutador del jugador).
export(NodePath) var camara_sobre_jinete_path
export(NodePath) var camara_llegada_path
# Camara externa: va por fuera de la pista mirando hacia adentro (se ve el
# lado interno: jardin, paddock). Se asigna en el Inspector.
export(NodePath) var camara_externa_path
export(NodePath) var jockey_path
export(NodePath) var enrutador_jugador_path

# Metros que le tienen que quedar al caballo QUE VA PRIMERO para
# que se active la camara de llegada (todas las carreras menos la de 800).
export var distancia_activacion_llegada = 800.0
# Lo mismo, pero solo para la de 800 (la recta).
export var distancia_activacion_llegada_800 = 200.0

# --- CAMARAS AUTOMATICAS ---
# Camara de partida solo en el aparato y estos primeros metros.
# Despues va la rueda: primera persona -> sobre el jinete -> externa
# (-> aerea, solo si Usar Camara Aerea esta marcado), cada tantos metros.
export var camaras_automaticas = true
export var metros_camara_partida = 10.0
export var metros_por_camara = 200.0
# La aerea queda fuera de la rueda hasta nuevo aviso.
export var usar_camara_aerea = false
# En la de 800 va en orden fijo, segun los metros que llevas:
# partida -> primera persona -> sobre el jinete -> llegada.
export var metros_partida_800 = 200.0
export var metros_primera_persona_800 = 200.0
export var metros_sobre_jinete_800 = 200.0
# Cambio a mano (tecla Ctrl en la computadora, boton CAMBIO DE CAMARA
# en el celular). En el celular funciona desde el nivel indicado
# (1 = desde el principio). Si el jugador cambia a mano, la rueda
# automatica se apaga en esa carrera (la de llegada entra igual).
export var cambio_manual_en_pc = true
export var cambio_manual_desde_nivel = 1
# La camara aerea (si esta en la rueda) no entra hasta estos metros.
export var metros_bloqueo_aerea = 400.0

var camara_partida
var _camara_primera
var _camara_sobre_jinete
var rueda = []
var rueda_800 = []
var indice_actual = -1
var _manual = false

# "carrera"   = carrera en curso, revisando si hay que activar la
#               camara de llegada.
# "llegada"   = camara de llegada activa y fija en la meta, viendo
#               pasar a los caballos que van llegando.
# "terminada" = ya paso el ultimo, no se vuelve a tocar nada mas.
var _fase = "carrera"

var jockey: Node
var enrutador_jugador: Node


func _ready():
	if camara_partida_path:
		camara_partida = get_node_or_null(camara_partida_path)
	if jockey_path:
		jockey = get_node_or_null(jockey_path)
	if enrutador_jugador_path:
		enrutador_jugador = get_node_or_null(enrutador_jugador_path)

	var primera = null
	if camara_primera_persona_path:
		primera = get_node_or_null(camara_primera_persona_path)
	var sobre_jinete = null
	if camara_sobre_jinete_path:
		sobre_jinete = get_node_or_null(camara_sobre_jinete_path)
	elif enrutador_jugador:
		sobre_jinete = enrutador_jugador.get_node_or_null("Camara_PP_2")
	var externa = null
	if camara_externa_path:
		externa = get_node_or_null(camara_externa_path)
	var aerea = null
	if camara_aerea_path:
		aerea = get_node_or_null(camara_aerea_path)

	for c in [primera, sobre_jinete, externa, camara_partida]:
		if c:
			rueda.append(c)
	if usar_camara_aerea and aerea:
		rueda.append(aerea)
	for c in [primera, sobre_jinete]:
		if c:
			rueda_800.append(c)
	_camara_primera = primera
	_camara_sobre_jinete = sobre_jinete
	print("[BDG-Camaras] partida=", _nombre(camara_partida), " | primera=", _nombre(primera),
		" | sobre jinete=", _nombre(sobre_jinete), " | externa=", _nombre(externa),
		" | llegada=", _nombre(get_node_or_null(camara_llegada_path)))

	if camara_partida:
		_activar_camara(camara_partida)
	elif rueda.size() > 0:
		_activar_camara(rueda[0])


func _process(delta):
	if _fase == "terminada":
		return

	if _fase == "llegada":
		if GestorNivel and GestorNivel.todos_terminaron():
			_fase = "terminada"
		return

	# --- fase "carrera" ---
	if jockey and jockey.carrera_terminada:
		_forzar_camara_llegada()
		return

	if _falta_poco_para_llegar():
		_forzar_camara_llegada()
		return

	if Input.is_action_just_pressed("cambiar_camara") and _cambio_manual_permitido():
		_manual = true
		_siguiente_camara()

	if camaras_automaticas and not _manual:
		_camara_automatica()


func _es_800() -> bool:
	return GestorNivel != null and GestorNivel.modo_recta


func _rueda_actual() -> Array:
	if _es_800() and rueda_800.size() > 0:
		return rueda_800
	return rueda


func _cambio_manual_permitido() -> bool:
	if cambio_manual_en_pc and not OS.has_touchscreen_ui_hint():
		return true
	return GestorNivel != null and GestorNivel.nivel_actual >= cambio_manual_desde_nivel


func _nombre(n) -> String:
	if n == null:
		return "(NO ENCONTRADA)"
	return n.name


# La de 800: orden fijo segun los metros del jugador.
func _camara_800(recorrido):
	var c = null
	if recorrido < metros_partida_800:
		c = camara_partida
	elif recorrido < metros_partida_800 + metros_primera_persona_800:
		c = _camara_primera
	else:
		c = _camara_sobre_jinete
	if c and not c.current:
		_activar_camara(c)


# Partida en el aparato y los primeros metros; despues la rueda.
func _camara_automatica():
	if enrutador_jugador == null or not GestorNivel:
		return
	if _es_800():
		_camara_800(GestorNivel.obtener_recorrido(enrutador_jugador))
		return
	var lista = _rueda_actual()
	if lista.size() == 0:
		return
	var recorrido = GestorNivel.obtener_recorrido(enrutador_jugador)
	if recorrido < metros_camara_partida and camara_partida:
		if indice_actual != -1:
			indice_actual = -1
			_activar_camara(camara_partida)
		return
	var tramo = int(floor((recorrido - metros_camara_partida) / max(metros_por_camara, 1.0)))
	var indice = tramo % lista.size()
	if indice != indice_actual:
		indice_actual = indice
		_activar_camara(lista[indice])


func _falta_poco_para_llegar() -> bool:
	if not GestorNivel:
		return false
	# En la de 800 tambien entra cuando TU llegas a tus metros de llegada.
	if _es_800() and enrutador_jugador:
		var tuyo = GestorNivel.obtener_recorrido(enrutador_jugador)
		if tuyo >= metros_partida_800 + metros_primera_persona_800 + metros_sobre_jinete_800:
			return true
	var restante = GestorNivel.obtener_distancia_lider_hasta_meta()
	if restante < 0.0:
		return false
	var limite = distancia_activacion_llegada
	if _es_800():
		limite = distancia_activacion_llegada_800
	return restante <= limite


func _forzar_camara_llegada():
	_fase = "llegada"
	_activar_camara(get_node_or_null(camara_llegada_path))


func _siguiente_camara():
	var lista = _rueda_actual()
	if lista.size() == 0:
		return
	indice_actual = (indice_actual + 1) % lista.size()
	_activar_camara(lista[indice_actual])


func _aerea_bloqueada(camara) -> bool:
	if not camara_aerea_path or camara != get_node_or_null(camara_aerea_path):
		return false
	if enrutador_jugador == null or not GestorNivel:
		return false
	return GestorNivel.obtener_recorrido(enrutador_jugador) < metros_bloqueo_aerea


func _activar_camara(camara):
	if camara and _aerea_bloqueada(camara):
		var lista = _rueda_actual()
		if lista.size() > 0 and lista[0] != camara:
			camara = lista[0]
	if camara:
		camara.current = true
