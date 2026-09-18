extends Camera

export(NodePath) var camino_pista_path
export(NodePath) var jockey_path
export var altura = 20.0
export var distancia_lateral = 200.0
export var invertir_lado = false
export var angulo_diagonal = 40.0
export var mostrar_diagnostico = true

# ============================================================
# ARREGLO DE ESTA SESION - la camara terminaba mirando en
# DIAGONAL en vez de frontal al poste.
#
# CAUSA: la camara seguia al lider hasta el instante mismo del
# cruce, y recien ahi se congelaba. Pero cuando el ganador
# cruza, la camara ya venia arrastrada DETRAS del punto de
# meta (en los logs: meta en offset 650, camara siguiendo al
# lider en 550), y ademas todo ese seguimiento usa el angulo
# diagonal. Resultado: quedaba clavada en un punto que no era
# el poste, y mirando de costado.
#
# SOLUCION: la camara deja de seguir al lider ANTES de que
# lleguen (ver distancia_para_plantarse), se va derecho al
# punto EXACTO del poste de llegada, y desde ahi solo GIRA
# para seguir a los caballos que se acercan de frente. Cuando
# el ganador cruza, ya esta plantada en el lugar correcto y
# queda mirando frontal al poste, como en un foto finish real.
# ============================================================

# Cuantos metros antes de la meta la camara deja de seguir al
# lider y se planta en el poste. Subilo para que se plante mas
# temprano (espera mas tiempo a los caballos), bajalo para que
# siga al lote mas rato antes de plantarse.
export var distancia_para_plantarse = 100.0

# Altura a la que apunta la camara sobre el poste cuando queda
# congelada. Subilo para mirar mas arriba (mas hacia la moneda
# BDG), bajalo para mirar mas a la altura de los caballos.
export var altura_mira_frontal = 3.0

# Destildar para volver al comportamiento viejo (seguir al
# lider hasta el cruce y congelarse en diagonal).
export var congelar_frontal = true

var _rastreador: PathFollow
var _congelada = false
var _plantada = false
var _diagnostico_hecho = false
var _diagnostico_pos_hecho = false


func _ready():
	var camino = null
	if camino_pista_path:
		camino = get_node_or_null(camino_pista_path)
	if not camino:
		camino = get_node_or_null("../TrackPath")
	if camino:
		_rastreador = PathFollow.new()
		camino.add_child(_rastreador)
		if mostrar_diagnostico:
			print("[BDG-CamaraLlegada] camino encontrado: ", camino.get_path())
	elif mostrar_diagnostico:
		print("[BDG-CamaraLlegada] ERROR: no se encontro TrackPath")


func _process(delta):
	if not current:
		return

	if mostrar_diagnostico and not _diagnostico_hecho:
		_diagnostico_hecho = true
		print("[BDG-CamaraLlegada] SE ACTIVO.")

	# Una vez congelada, no se toca nunca mas - ahi se queda.
	if _congelada:
		return

	# Se congela apenas el PRIMERO en cruzar (el ganador real).
	if GestorNivel and GestorNivel.obtener_ganador() != null:
		_congelada = true
		if congelar_frontal:
			_plantarse_en_el_poste()
			_mirar_al_poste()
		if mostrar_diagnostico:
			print("[BDG-CamaraLlegada] CONGELADA en ", global_transform.origin)
		return

	if not congelar_frontal:
		_seguir_al_lider()
		return

	# Mientras el lider esta lejos, la camara lo sigue en diagonal
	# como una camara de TV. Cuando se acerca lo suficiente, se va
	# al poste y se queda ahi, solo girando para seguirlos.
	if not _plantada:
		var falta = _obtener_distancia_lider_a_meta()
		if falta >= 0.0 and falta <= distancia_para_plantarse:
			_plantada = true
			_plantarse_en_el_poste()
			if mostrar_diagnostico:
				print("[BDG-CamaraLlegada] SE PLANTO EN EL POSTE. Faltaban ", falta,
					" | camara en=", global_transform.origin)
		else:
			_seguir_al_lider()
			return

	# Ya plantada: no se mueve mas de lugar, solo gira siguiendo al
	# lote que se acerca de frente.
	_mirar_al_lider()


# Cuanto le falta al lider para cruzar la meta. Es SOLO LECTURA
# de GestorNivel - ese archivo no se toca.
func _obtener_distancia_lider_a_meta() -> float:
	if not GestorNivel:
		return -1.0
	return GestorNivel.obtener_distancia_lider_hasta_meta()


func _obtener_offset_meta() -> float:
	if not GestorNivel:
		return -1.0
	if GestorNivel.modo_recta and GestorNivel._meta_recta:
		return GestorNivel._meta_recta.offset
	elif GestorNivel._meta_ovalo:
		return GestorNivel._meta_ovalo.offset
	return -1.0


# Devuelve el punto exacto de la meta sobre la pista, y hacia
# donde apunta la pista en ese punto.
func _obtener_datos_meta():
	var offset_meta = _obtener_offset_meta()
	if offset_meta < 0.0 or not _rastreador:
		return null

	_rastreador.offset = offset_meta
	var punto_meta = _rastreador.global_transform.origin

	_rastreador.offset = offset_meta + 1.0
	var punto_adelante = _rastreador.global_transform.origin
	_rastreador.offset = offset_meta

	var avance = punto_adelante - punto_meta
	avance.y = 0.0
	if avance.length() < 0.001:
		avance = Vector3(0, 0, -1)
	avance = avance.normalized()

	return {"punto": punto_meta, "avance": avance}


# Coloca la camara en la linea perpendicular que sale de la
# meta - o sea, enfrentada al poste. Sin el angulo diagonal.
func _plantarse_en_el_poste():
	var datos = _obtener_datos_meta()
	if datos == null:
		return

	var lado = datos["avance"].cross(Vector3.UP).normalized()
	if invertir_lado:
		lado = -lado

	global_transform.origin = datos["punto"] + (lado * distancia_lateral) + Vector3.UP * altura


# Mira derecho al poste de llegada (encuadre final del foto
# finish).
func _mirar_al_poste():
	var datos = _obtener_datos_meta()
	if datos == null:
		return
	look_at(datos["punto"] + Vector3.UP * altura_mira_frontal, Vector3.UP)
	if mostrar_diagnostico:
		print("[BDG-CamaraLlegada] FRONTAL -> punto_meta=", datos["punto"],
			" | camara en=", global_transform.origin)


# Ya plantada en el poste: gira para seguir a los caballos que
# se vienen acercando, sin moverse de lugar.
func _mirar_al_lider():
	if not _rastreador or not GestorNivel:
		return
	var offset_lider = GestorNivel.obtener_offset_lider()
	_rastreador.offset = offset_lider
	var punto_lider = _rastreador.global_transform.origin
	look_at(punto_lider + Vector3.UP * altura_mira_frontal, Vector3.UP)


# Seguimiento en diagonal, como camara de TV, mientras el lote
# todavia esta lejos de la meta.
func _seguir_al_lider():
	if not _rastreador or not GestorNivel:
		return

	var offset_lider = GestorNivel.obtener_offset_lider()
	_rastreador.offset = offset_lider
	var punto_pista = _rastreador.global_transform.origin

	_rastreador.offset = offset_lider + 1.0
	var punto_adelante = _rastreador.global_transform.origin
	_rastreador.offset = offset_lider

	var avance = punto_adelante - punto_pista
	avance.y = 0.0
	if avance.length() < 0.001:
		avance = Vector3(0, 0, -1)
	avance = avance.normalized()

	var lado = avance.cross(Vector3.UP).normalized()
	if invertir_lado:
		lado = -lado
	lado = lado.rotated(Vector3.UP, deg2rad(angulo_diagonal))

	global_transform.origin = punto_pista + (lado * distancia_lateral) + Vector3.UP * altura
	look_at(punto_pista, Vector3.UP)

	if mostrar_diagnostico and not _diagnostico_pos_hecho:
		_diagnostico_pos_hecho = true
		print("[BDG-CamaraLlegada] offset_lider=", offset_lider,
			" | punto_pista=", punto_pista, " | camara en=", global_transform.origin)
