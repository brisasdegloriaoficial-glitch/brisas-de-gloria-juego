tool
extends Path

export var largo_recta = 804.0 setget set_largo_recta
export var radio_curva = 318.0 setget set_radio_curva
export var puntos_por_curva = 24 setget set_puntos_por_curva

# ============================================================
# PISTA DE ARENA (la anaranjada de adentro)
# ============================================================
# Cuando se elige una carrera de arena, el camino de los caballos
# se arma con estas medidas en vez de las de la grama. La grama,
# sus barandas y los arbustos NO se mueven: siguen usando el ovalo
# de grama (curva_grama).
# Largo Recta Arena: largo de cada recta de la arena.
# Radio Curva Arena: radio de las curvas de la arena, medido en la
#   baranda de adentro (por ahi va el carril 0).
# OJO: en la arena la largada tiene que caer en la recta de atras
# (la de enfrente a la meta), igual que todas las carreras de grama.
# En la arena no se dibuja la franja de salida (roja y blanca).
export var largo_recta_arena = 341.7 setget set_largo_recta_arena
export var radio_curva_arena = 137.0 setget set_radio_curva_arena
# NUEVO - Que tan pegados a la baranda interior corren los rivales en la
# arena (mas bajo = mas pegados). La grama no cambia: usa su propio
# carril (carril_baranda de GestorNivel).
export var carril_baranda_arena = 2.5

# El ovalo de grama, siempre. Lo usan los que dibujan la grama,
# las barandas y los arbustos, para que no se muden a la arena.
var curva_grama = null

# Se usa solo si por algun motivo no existe Meta_LLegada en la escena
# (caso extremo, no deberia pasar nunca en el proyecto actual).
export var margen_salida = 40.0

# ============================================================
# REGLA 4 - ZONAS PROHIBIDAS (NO PARTIDAS EN CURVA)
# ============================================================
export var margen_seguridad_recta = 60.0
export var paso_busqueda_recta = 2.0

# ============================================================
# REGLA 2 - MODO RECTA INDEPENDIENTE (800 M)
# ============================================================
# Distancia real que se corre en el modo recta.
export var distancia_recta_800m_real = 724.0

# CORRECCION: Meta_Recta YA NO copia la posicion de Meta_Ovalo. La
# meta del ovalo esta a la MITAD de la recta delantera (804/2 = 402
# unidades libres antes de ella) - no alcanza para 724. Meta_Recta
# usa en cambio la recta TRASERA, que no tiene ninguna meta
# compitiendo por espacio y tiene sus 804 unidades completas
# disponibles. offset_meta_recta = 780 dentro de esa recta deja
# ~780 unidades libres antes (de sobra para 724 + margen) y ~24
# unidades de colchon antes de que empiece la curva siguiente.
export var offset_meta_recta = 780.0

# ============================================================
# REGLA 2b - MODO VUELTA COMPLETA (2000m)
# ============================================================
# Cuantos metros PASANDO la meta (en la misma recta delantera,
# siguiendo de largo hacia la proxima curva) arranca la carrera de
# "2000m". Antes este modo reutilizaba el mismo gate del modo 800m
# (en la recta trasera) y quedaba demasiado parecido al arranque de
# "1600m" - las dos se sentian iguales. Ahora tiene su propio lugar,
# bien distinto, tunable aca sin tocar el script de nuevo.
export var margen_inicio_vuelta_completa = 200.0


# ============================================================
# LINEA DE LARGADA PAREJA  (arregla el ORDEN DE LLEGADA)
# ============================================================
# Los 10 caballos arrancan todos en el MISMO offset del camino, pero
# cada modelo esta corrido hacia adelante dentro de su enrutador:
# el 1 esta en z = -4.7 y el 10 en z = -58.9. Como en un PathFollow
# el -Z es "hacia adelante", eso significa que el caballo 10 largaba
# 54 unidades ADELANTE del caballo 1, en diagonal.
# El juego nunca vio esa diferencia (cuenta por offset del enrutador,
# no por donde esta el modelo), asi que el orden de llegada que
# mostraba nunca coincidio con lo que se ve en pantalla.
# Esto empareja a los 10 en la misma linea al arrancar la carrera.
# No modifica la escena guardada: se aplica al dar Play.
export var alinear_caballos_en_la_largada = true

# En que z quedan alineados los 10. Por defecto es el valor que ya
# tenia el caballo del jugador (-4.72), para no descolocarle las
# camaras, que cuelgan del enrutador y no del modelo.
# Bajalo (mas negativo) para adelantar todo el lote, subilo para
# atrasarlo.
export var z_comun_en_la_largada = -4.72


func _ready():
	generar_ovalo()
	if es_carrera_de_arena():
		_ocultar_franja_de_salida()
	_poner_carril_baranda()


# NUEVO - En la arena los rivales usan Carril Baranda Arena. En la grama
# se devuelve el carril de siempre (el que trae GestorNivel).
func _poner_carril_baranda():
	if Engine.is_editor_hint():
		return
	var gestor = get_node_or_null("/root/GestorNivel")
	if gestor == null:
		return
	if not gestor.has_meta("carril_baranda_grama"):
		gestor.set_meta("carril_baranda_grama", gestor.carril_baranda)
	if es_carrera_de_arena():
		gestor.carril_baranda = carril_baranda_arena
	else:
		gestor.carril_baranda = gestor.get_meta("carril_baranda_grama")


func _enter_tree():
	if Engine.is_editor_hint():
		return
	generar_ovalo()
	if es_carrera_de_arena():
		_poner_meta_en_recta_de_arena()
	_centrar_meta_ovalo()
	_preparar_meta_recta()
	_ubicar_salida()


# Centra Meta_LLegada en el punto medio real de la recta delantera.
# No usa ninguna formula a mano: camina sobre la curva real, offset
# por offset, desde donde esta la meta ahora, hasta encontrar donde
# empieza y donde termina de verdad esa recta - y la deja
# exactamente en la mitad. Se corre una sola vez al arrancar.
func _centrar_meta_ovalo():
	if not curve:
		return
	var meta_ovalo = get_node_or_null("Meta_LLegada")
	if not meta_ovalo:
		return
	var longitud_total = curve.get_baked_length()
	if longitud_total <= 0:
		return

	var paso = 1.0
	var inicio = meta_ovalo.offset
	var recorrido_atras = 0.0
	while es_zona_recta(fposmod(inicio - paso, longitud_total)) and recorrido_atras < longitud_total:
		inicio = fposmod(inicio - paso, longitud_total)
		recorrido_atras += paso

	var fin = meta_ovalo.offset
	var recorrido_adelante = 0.0
	while es_zona_recta(fposmod(fin + paso, longitud_total)) and recorrido_adelante < longitud_total:
		fin = fposmod(fin + paso, longitud_total)
		recorrido_adelante += paso

	var largo_recta_real = recorrido_atras + recorrido_adelante
	var punto_medio_real = fposmod(inicio + largo_recta_real / 2.0, longitud_total)

	meta_ovalo.offset = punto_medio_real

	if GestorNivel and GestorNivel.mostrar_diagnostico:
		print("[BDG-Track] Meta_LLegada centrada: inicio_recta=", inicio,
			" fin_recta=", fin, " largo=", largo_recta_real,
			" | offset nuevo=", punto_medio_real)


# ------------------------------------------------------------
# REGLA 2 - crea Meta_Recta si todavia no existe en la escena, en
# la recta TRASERA (offset_meta_recta), totalmente independiente
# de Meta_Ovalo. Ojo: al crearse en tiempo de ejecucion, este nodo
# NO aparece en el arbol del editor mientras editas la escena.
# ------------------------------------------------------------
func _preparar_meta_recta():
	if has_node("Meta_Recta"):
		return
	var meta_ovalo = get_node_or_null("Meta_LLegada")
	var meta_recta = PathFollow.new()
	meta_recta.name = "Meta_Recta"
	var script_linea = load("res://LineaMarcador.gd")
	if script_linea:
		meta_recta.set_script(script_linea)
	add_child(meta_recta)
	meta_recta.offset = offset_meta_recta
	if meta_ovalo:
		meta_recta.h_offset = meta_ovalo.h_offset
	meta_recta.visible = false


# ------------------------------------------------------------
# REGLA 1 - META FIJA, SOLO SE MUEVE EL STARTING GATE
# REGLA 2 - dos metas independientes (Meta_Ovalo / Meta_Recta),
#           activa una u otra segun el modo.
# ------------------------------------------------------------
func _ubicar_salida():
	if not curve:
		return
	var longitud_total = curve.get_baked_length()
	if longitud_total <= 0:
		return

	GestorNivel.registrar_longitud_pista(longitud_total)

	var meta_ovalo = get_node_or_null("Meta_LLegada")
	var meta_recta = get_node_or_null("Meta_Recta")
	var modo_recta = ConfiguracionCarrera and ConfiguracionCarrera.modo_recta

	var salida
	var vueltas_totales

	if modo_recta and meta_recta:
		# --- MODO RECTA: la meta del ovalo queda desactivada para esta
		# carrera, monitoreamos solo Meta_Recta (en la recta trasera). ---
		var offset_crudo = fposmod(meta_recta.offset - distancia_recta_800m_real, longitud_total)
		salida = _ajustar_offset_a_recta(offset_crudo, longitud_total)
		vueltas_totales = 1
		GestorNivel.configurar_meta(meta_ovalo, meta_recta, true, vueltas_totales)

	elif meta_ovalo:
		# --- MODO OVALO: Meta_Ovalo desactiva Meta_Recta para esta carrera. ---
		var distancia_pedida = largo_recta + PI * radio_curva
		if ConfiguracionCarrera:
			distancia_pedida = ConfiguracionCarrera.distancia_metros

		if ConfiguracionCarrera and ConfiguracionCarrera.modo_vuelta_completa:
			# CORREGIDO (2da vuelta de ajuste) - la version anterior
			# reutilizaba el gate del modo 800m (en la recta trasera)
			# para el arranque de "2000m", y quedaba demasiado cerca del
			# arranque de "1600m" - las dos carreras se sentian iguales
			# al arrancar. Ahora arranca en un lugar propio: X metros
			# PASANDO la meta, siguiendo de largo por la MISMA recta
			# delantera, antes de entrar a la curva siguiente - bien
			# distinto de cualquier otro arranque. _ajustar_offset_a_recta
			# mide la pista real (no un numero asumido) para confirmar
			# que este punto sigue estando en zona de recta.
			var offset_crudo = fposmod(meta_ovalo.offset + margen_inicio_vuelta_completa, longitud_total)
			salida = _ajustar_offset_a_recta(offset_crudo, longitud_total)
			# Vuelta completa = 1 sola vuelta, a mano. No se calcula con
			# la formula de abajo (distancia_pedida / longitud_total)
			# porque esta carrera arranca X metros pasada la meta, no
			# justo en la meta - esa formula asumiria mal la distancia
			# real a recorrer.
			vueltas_totales = 1
		else:
			var offset_crudo = fposmod(meta_ovalo.offset - distancia_pedida, longitud_total)
			salida = _ajustar_offset_a_recta(offset_crudo, longitud_total)
			# CORREGIDO: antes esta cuenta usaba "distancia_real" (lo que
			# sobra despues de dar una vuelta, que SIEMPRE es menor a una
			# vuelta completa) en vez de la distancia total pedida. Por
			# eso cualquier carrera de mas de una vuelta terminaba
			# contando solo 1 vuelta y cortaba la carrera antes de tiempo.
			vueltas_totales = int(ceil(distancia_pedida / longitud_total))

		GestorNivel.configurar_meta(meta_ovalo, meta_recta, false, vueltas_totales)

	else:
		salida = fposmod(margen_salida, longitud_total)
		vueltas_totales = 1
		GestorNivel.configurar_meta(null, meta_recta, false, vueltas_totales)

	var partida = get_node_or_null("Aparato_Partida")
	if partida:
		partida.offset = salida

	for hijo in get_children():
		if hijo is PathFollow and hijo.name.begins_with("Enrutador_Caballo"):
			hijo.offset = salida
			if alinear_caballos_en_la_largada:
				_emparejar_modelo(hijo)

	if GestorNivel and GestorNivel.mostrar_diagnostico:
		print("[BDG-Track] largo_recta=", largo_recta, " radio_curva=", radio_curva,
			" longitud_total_baked=", longitud_total,
			" | gate final (salida)=", salida,
			" | es_zona_recta(salida)=", es_zona_recta(salida))


func es_zona_recta(offset) -> bool:
	if not curve:
		return false
	var longitud_total = curve.get_baked_length()
	if longitud_total <= 0:
		return false
	offset = fposmod(offset, longitud_total)
	var p = curve.interpolate_baked(offset)
	var p2 = curve.interpolate_baked(fposmod(offset + 1.0, longitud_total))
	var dir = (p2 - p).normalized()
	return abs(dir.x) > 0.9997


func _ajustar_offset_a_recta(offset_crudo, longitud_total) -> float:
	if es_zona_recta(offset_crudo):
		return offset_crudo

	# CORRECCION verificada por simulacion: buscar solo hacia atras
	# hacia una recta hacia (contra el sentido de carrera) hacia una
	# unica recta hacia atras del recta hacia atras (contra el
	# sentido) puede llevar a DOS distancias distintas a exactamente
	# el mismo lugar (le paso a 2400m y 3000m: ambas retrocedian
	# hasta la misma recta delantera y colapsaban en el mismo punto).
	# Ahora se busca en las DOS direcciones y se usa la mas cercana,
	# para que cada distancia caiga en un lugar propio.
	var atras = offset_crudo
	var pasos_atras = 0.0
	while pasos_atras < longitud_total:
		atras = fposmod(atras - paso_busqueda_recta, longitud_total)
		pasos_atras += paso_busqueda_recta
		if es_zona_recta(atras):
			break

	var adelante = offset_crudo
	var pasos_adelante = 0.0
	while pasos_adelante < longitud_total:
		adelante = fposmod(adelante + paso_busqueda_recta, longitud_total)
		pasos_adelante += paso_busqueda_recta
		if es_zona_recta(adelante):
			break

	var base
	var offset_seguro
	if pasos_atras <= pasos_adelante:
		base = atras
		offset_seguro = fposmod(atras - margen_seguridad_recta, longitud_total)
	else:
		base = adelante
		offset_seguro = fposmod(adelante + margen_seguridad_recta, longitud_total)

	if es_zona_recta(offset_seguro):
		return offset_seguro
	return base


func set_largo_recta(valor):
	largo_recta = valor
	generar_ovalo()

func set_radio_curva(valor):
	radio_curva = valor
	generar_ovalo()

func set_puntos_por_curva(valor):
	puntos_por_curva = valor
	generar_ovalo()

func set_largo_recta_arena(valor):
	largo_recta_arena = valor
	generar_ovalo()

func set_radio_curva_arena(valor):
	radio_curva_arena = valor
	generar_ovalo()


# true solo jugando (nunca en el editor) y si se eligio una carrera de arena.
func es_carrera_de_arena() -> bool:
	if Engine.is_editor_hint():
		return false
	var config = get_node_or_null("/root/ConfiguracionCarrera")
	return config != null and config.get("pista_arena") == true


# Arma el ovalo de grama (siempre) y, si la carrera es de arena,
# el camino de los caballos pasa a ser el ovalo de arena.
func generar_ovalo():
	curva_grama = _armar_ovalo(largo_recta, radio_curva)
	if es_carrera_de_arena():
		curve = _armar_ovalo(largo_recta_arena, radio_curva_arena)
	else:
		curve = curva_grama


# Deja Meta_LLegada en la mitad de la recta delantera de la arena
# (despues _centrar_meta_ovalo la afina igual que en la grama).
func _poner_meta_en_recta_de_arena():
	var meta_ovalo = get_node_or_null("Meta_LLegada")
	if meta_ovalo == null or curve == null:
		return
	meta_ovalo.offset = curve.get_closest_offset(Vector3(0, 0, radio_curva_arena))


# En la arena se esconde la franja de salida (roja y blanca) del piso.
func _ocultar_franja_de_salida():
	var partida = get_node_or_null("Aparato_Partida")
	if partida == null:
		return
	for hijo in partida.get_children():
		if hijo is MeshInstance and "LineaVisual" in hijo.name:
			hijo.visible = false


func _armar_ovalo(largo, radio):
	var puntos = []
	var direcciones = []

	var dir_recta_trasera = Vector3(-1, 0, 0)
	puntos.append(Vector3(largo / 2, 0, -radio))
	direcciones.append(dir_recta_trasera)
	puntos.append(Vector3(-largo / 2, 0, -radio))
	direcciones.append(dir_recta_trasera)

	for i in range(1, puntos_por_curva):
		var angulo = -PI / 2 - (PI * i / puntos_por_curva)
		var x = -largo / 2 + radio * cos(angulo)
		var z = radio * sin(angulo)
		puntos.append(Vector3(x, 0, z))
		direcciones.append(Vector3(sin(angulo), 0, -cos(angulo)))

	var dir_recta_delantera = Vector3(1, 0, 0)
	puntos.append(Vector3(-largo / 2, 0, radio))
	direcciones.append(dir_recta_delantera)
	puntos.append(Vector3(largo / 2, 0, radio))
	direcciones.append(dir_recta_delantera)

	for i in range(1, puntos_por_curva):
		var angulo = PI / 2 - (PI * i / puntos_por_curva)
		var x = largo / 2 + radio * cos(angulo)
		var z = radio * sin(angulo)
		puntos.append(Vector3(x, 0, z))
		direcciones.append(Vector3(sin(angulo), 0, -cos(angulo)))

	var n = puntos.size()
	var nueva_curva = Curve3D.new()
	for i in range(n):
		var anterior = puntos[(i - 1 + n) % n]
		var siguiente = puntos[(i + 1) % n]
		var largo_manija = min(puntos[i].distance_to(anterior), puntos[i].distance_to(siguiente)) / 3.0
		var manija = direcciones[i] * largo_manija
		nueva_curva.add_point(puntos[i], -manija, manija)

	var largo_manija_cierre = min(puntos[n - 1].distance_to(puntos[0]), puntos[0].distance_to(puntos[1])) / 3.0
	var manija_cierre = direcciones[0] * largo_manija_cierre
	nueva_curva.add_point(puntos[0], -manija_cierre, manija_cierre)

	return nueva_curva


# Deja el modelo del caballo a la misma altura de pista que todos los
# demas. Solo toca el z (el avance sobre la pista). El x y el y no se
# tocan: esos son el carril y la altura, y estan bien.
func _emparejar_modelo(enrutador):
	for modelo in enrutador.get_children():
		if modelo is Spatial and modelo.name.begins_with("Caballo"):
			var t = modelo.translation
			t.z = z_comun_en_la_largada
			modelo.translation = t
