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

# --- TOMA DE FRENTE (ultima curva) ---
# La camara va DELANTE de los caballos, a media pista, bajita,
# mirandolos de frente. A medida que el lider se acerca a la meta
# se va abriendo hacia afuera, hasta quedar pegada a la baranda
# exterior, frente al photo finish. Desmarcar = como estaba antes.
export var toma_de_frente = true
# Cuantos metros por delante del lider va la camara.
export var adelante_del_lider = 40.0
# Donde va de costado al empezar (0 = baranda interior; 59 = media pista).
export var lateral_inicio = 59.0
# Donde termina de costado: la baranda exterior esta en 118, asi que
# 126 queda pegada a la baranda, por fuera.
export var lateral_final = 126.0
# Altura al empezar y al terminar. Empieza al ras de la pista
# (1.5) y va subiendo hasta altura_final.
export var altura_inicio = 1.5
export var altura_final = 10.0
# Apertura del lente al empezar (amplia, para que quepa todo el lote)
# y al terminar (mas cerrada, sobre los primeros).
export var fov_inicio = 50.0
export var fov_final = 30.0
# Al final se queda con estos primeros lugares.
export var cuantos_primeros = 3
# En la carrera de 800 (la recta) se queda con estos primeros lugares.
export var cuantos_primeros_800 = 3
# Que tan suave sigue el punto al que mira (mas bajo = mas suave).
export var suavidad_mira = 3.0
# 0 = termina frente al photo finish (perpendicular). Mas alto = termina
# unos metros pasada la meta, en diagonal.
export var adelante_final = 0.0
# Altura del punto al que mira (caballos) mientras se acercan.
export var altura_mira = 4.0
# NUEVO - Altura del punto al que mira al final, frente a la meta. Subelo
# junto con Altura Final para que no se recorte el logo de arriba.
# Pasa de Altura Mira a esta, suave, mientras la camara va subiendo.
export var altura_mira_final = 4.0
# Metros que le faltan al lider cuando la camara empieza a abrirse.
export var metros_inicio_salida = 400.0
# Acercar la toma: 1 = como estaba, mas alto = mas cerca (1.5, 2...).
export var zoom = 1.5
# Despues de que cruza el ganador, la camara sigue girando detras de
# los primeros estos segundos antes de quedarse quieta.
# Desmarcar = se congela en el instante del cruce, como antes.
export var seguir_despues_de_meta = false
export var segundos_despues_de_meta = 4.0
# Al llegar a su sitio final, la camara deja de seguir caballos y se
# queda fija mirando derecho la raya del photo finish (perpendicular).
# Los caballos que pasan, pasan. Desmarcar = sigue a los primeros.
export var fija_en_la_meta = true
# Desde que parte del recorrido de la camara empieza a girar hacia la
# raya (0 = desde el principio, 1 = recien al final). Mas bajo = se
# fija antes.
export var empezar_a_fijar = 0.7 # (ya no se usa: ahora manda Metros Para Fijar)
# Cuantos metros le faltan al lider cuando la vista empieza a girar,
# suave, hacia la raya, justo donde van los primeros (no al centro
# de la pista). Mas alto = gira antes; mas bajo = gira mas tarde.
export var metros_para_fijar = 30.0
# NUEVO - Que el primero nunca se salga de la toma, aunque se escape.
# Hasta donde puede llegar hacia el borde de la pantalla antes de que la
# camara gire a buscarlo (0.7 = 70% del camino al borde). 0 = apagado.
export var margen_primero = 0.7

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

	if toma_de_frente:
		_toma_de_frente(delta)
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


# Toma de frente: delante del lider a media pista, abriendose hacia
# la baranda exterior hasta quedar frente al photo finish.
var _mira_suave = null
# Punto fijo de la raya al que queda mirando al final (se elige una sola vez).
var _mira_fija = null
# Donde esta el caballo que SE VE respecto a su punto de control (se mide una vez).
var _offset_modelo = {}
var _tiempo_despues_meta = 0.0
var _aviso_cruce_hecho = false

func _toma_de_frente(delta):
	if not _rastreador or not GestorNivel:
		return
	var offset_meta = _obtener_offset_meta()
	if offset_meta < 0.0:
		return
	var falta = _obtener_distancia_lider_a_meta()
	if falta < 0.0:
		falta = 0.0

	# Cruzo el ganador.
	if GestorNivel.obtener_ganador() != null:
		var pos_final = _punto_de_pista(offset_meta + adelante_final, lateral_final, altura_final)
		global_transform.origin = pos_final
		fov = fov_final / max(zoom, 0.1)
		# Como antes: fija mirando derecho a la meta.
		if not seguir_despues_de_meta:
			# Se queda quieta en su sitio, mirando recto el punto fijo de
			# la raya. No sigue a nadie: el que cruzo, cruzo. Si todavia
			# le faltaba un poquito para llegar a ese punto, termina de
			# girar suave, sin salto.
			if _mira_fija == null:
				var primeros_fin = _centro_corredores(_cuantos_primeros())
				if primeros_fin != null:
					_mira_fija = _raya_frente_a(primeros_fin) + Vector3.UP * altura_mira_final
				else:
					_mira_fija = _punto_de_pista(offset_meta, lateral_inicio, altura_mira_final)
			if _mira_suave == null:
				_mira_suave = _mira_fija
			else:
				_mira_suave = _mira_suave.linear_interpolate(_mira_fija, clamp(suavidad_mira * delta, 0.0, 1.0))
			if global_transform.origin.distance_to(_mira_suave) > 0.5:
				look_at(_mira_suave, Vector3.UP)
			if mostrar_diagnostico and not _aviso_cruce_hecho:
				_aviso_cruce_hecho = true
				print("[BDG-CamaraLlegada] FOTO DE FRENTE en ", global_transform.origin)
			return
		# Nuevo: se queda en su sitio pero sigue girando detras de los
		# primeros mientras pasan la raya, y despues se queda quieta.
		if mostrar_diagnostico and not _aviso_cruce_hecho:
			_aviso_cruce_hecho = true
			print("[BDG-CamaraLlegada] cruzo el ganador, sigo ", segundos_despues_de_meta, " s")
		_tiempo_despues_meta += delta
		if _tiempo_despues_meta >= segundos_despues_de_meta:
			_congelada = true
			return
		var primeros = _centro_corredores(_cuantos_primeros())
		if primeros != null:
			var mira_fin = primeros + Vector3.UP * altura_mira
			if _mira_suave == null:
				_mira_suave = mira_fin
			else:
				_mira_suave = _mira_suave.linear_interpolate(mira_fin, clamp(suavidad_mira * delta, 0.0, 1.0))
			if global_transform.origin.distance_to(_mira_suave) > 0.5:
				look_at(_mira_suave, Vector3.UP)
		return

	var tramo = max(metros_inicio_salida - distancia_para_plantarse, 1.0)
	var t = clamp((metros_inicio_salida - falta) / tramo, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)

	# Cuanto le falta a la camara para su sitio final. Va por delante
	# del lider y, en vez de pararse en seco, frena suave hasta quedar
	# en su sitio justo cuando cruza el primero.
	var antes_de_meta = max(falta - adelante_del_lider, 0.0)
	var margen = adelante_del_lider * 0.25
	if margen > 0.0 and abs(falta - adelante_del_lider) < margen:
		var d = falta - adelante_del_lider + margen
		antes_de_meta = d * d / (4.0 * margen)
	var offset_camara = offset_meta + adelante_final * t - antes_de_meta
	var lateral = lerp(lateral_inicio, lateral_final, t)
	var alto = lerp(altura_inicio, altura_final, t)
	global_transform.origin = _punto_de_pista(offset_camara, lateral, alto)

	fov = lerp(fov_inicio, fov_final, t) / max(zoom, 0.1)

	# Al empezar mira al centro de TODO el lote; poco a poco se va
	# quedando con los primeros lugares.
	var lote = _centro_corredores(0)
	var punteros = _centro_corredores(_cuantos_primeros())
	if lote == null or punteros == null:
		var offset_lider = GestorNivel.obtener_offset_lider()
		lote = _punto_de_pista(offset_lider, lateral_inicio, 0.0)
		punteros = lote
	var alto_mira = lerp(altura_mira, altura_mira_final, t)
	var mira = lote.linear_interpolate(punteros, t) + Vector3.UP * alto_mira
	if fija_en_la_meta:
		# Cuando a los primeros les faltan Metros Para Fijar, se elige UNA
		# sola vez el punto de la raya frente a donde vienen, y desde ahi
		# la camara gira suave hasta quedar mirando recto ese punto fijo.
		if _mira_fija == null and falta <= metros_para_fijar:
			_mira_fija = _raya_frente_a(punteros) + Vector3.UP * altura_mira_final
		if _mira_fija != null:
			var peso = clamp(1.0 - falta / max(metros_para_fijar, 0.01), 0.0, 1.0)
			mira = mira.linear_interpolate(_mira_fija, peso)
	if _mira_suave == null:
		_mira_suave = mira
	else:
		_mira_suave = _mira_suave.linear_interpolate(mira, clamp(suavidad_mira * delta, 0.0, 1.0))
	# NUEVO - Si el primero se escapa, la camara gira lo justo para no perderlo.
	var primero = _centro_corredores(1)
	if margen_primero > 0.0 and primero != null:
		_mira_suave = _mantener_en_toma(_mira_suave, primero + Vector3.UP * alto_mira)
	if global_transform.origin.distance_to(_mira_suave) > 0.5:
		look_at(_mira_suave, Vector3.UP)


# NUEVO - Gira la mira lo justo para que "punto" quede dentro de la toma.
func _mantener_en_toma(mira, punto):
	var cam = global_transform.origin
	var hacia_mira = mira - cam
	var hacia_punto = punto - cam
	if hacia_mira.length() < 0.01 or hacia_punto.length() < 0.01:
		return mira
	var tam = get_viewport().get_visible_rect().size
	var mitad = atan(tan(deg2rad(fov * 0.5)) * tam.x / max(tam.y, 1.0))
	var limite = mitad * margen_primero
	var angulo = hacia_mira.angle_to(hacia_punto)
	if angulo <= limite:
		return mira
	var giro = hacia_mira.normalized().slerp(hacia_punto.normalized(), 1.0 - limite / angulo)
	return cam + giro * hacia_mira.length()


# Cuantos primeros sigue: en la de 800 (recta) usa su propio numero.
func _cuantos_primeros() -> int:
	if GestorNivel and GestorNivel.modo_recta:
		return cuantos_primeros_800
	return cuantos_primeros


# Centro de los caballos. cuantos = 0 -> todos; si no, los primeros N.
func _centro_corredores(cuantos):
	if not ("_corredores" in GestorNivel):
		return null
	var lista = []
	for c in GestorNivel._corredores:
		if is_instance_valid(c):
			lista.append([GestorNivel.obtener_recorrido(c), c])
	if lista.empty():
		return null
	lista.sort_custom(self, "_mas_adelante")
	var n = lista.size() if cuantos <= 0 else min(cuantos, lista.size())
	var suma = Vector3.ZERO
	for i in range(n):
		suma += _punto_visible(lista[i][1])
	return suma / n


func _mas_adelante(a, b):
	return a[0] > b[0]


# El caballo que se VE va unos metros adelante (y corrido de lado) de su
# punto de control. La camara apunta al caballo que se ve, no al punto.
# La distancia se mide una sola vez por caballo, asi que no pesa.
func _punto_visible(c) -> Vector3:
	if not _offset_modelo.has(c):
		var local = Vector3.ZERO
		for h in c.get_children():
			if h is Spatial and h.name.begins_with("Caballo") and h.is_visible_in_tree():
				var caja = _caja_modelo(h)
				if caja != null:
					var centro = caja.position + caja.size * 0.5
					local = c.global_transform.affine_inverse().xform(centro)
				break
		_offset_modelo[c] = local
	var p = c.global_transform.xform(_offset_modelo[c])
	p.y = c.global_transform.origin.y
	return p


func _caja_modelo(n):
	var total = null
	for h in n.get_children():
		if h is MeshInstance and h.is_visible_in_tree():
			var c = h.get_transformed_aabb()
			total = c if total == null else total.merge(c)
		var sub = _caja_modelo(h)
		if sub != null:
			total = sub if total == null else total.merge(sub)
	return total


# El punto de la raya que queda justo frente a "punto": la misma
# distancia de costado, pero sobre la linea de meta.
func _raya_frente_a(punto: Vector3) -> Vector3:
	var datos = _obtener_datos_meta()
	if datos == null:
		return punto
	var desde_meta = punto - datos.punto
	desde_meta.y = 0.0
	var resultado = punto - datos.avance * desde_meta.dot(datos.avance)
	resultado.y = datos.punto.y
	return resultado


# Un punto de la pista: a tantos metros del recorrido, tanto de costado
# (0 = baranda interior, positivo = hacia afuera) y a tal altura.
func _punto_de_pista(offset_pista, lateral, alto) -> Vector3:
	_rastreador.offset = offset_pista
	var p0 = _rastreador.global_transform.origin
	_rastreador.offset = offset_pista + 1.0
	var p1 = _rastreador.global_transform.origin
	_rastreador.offset = offset_pista
	var avance = p1 - p0
	avance.y = 0.0
	if avance.length() < 0.001:
		avance = Vector3(0, 0, -1)
	avance = avance.normalized()
	var lado = avance.cross(Vector3.UP).normalized()
	if invertir_lado:
		lado = -lado
	return p0 + lado * lateral + Vector3.UP * alto


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
