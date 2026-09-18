tool
extends Spatial

# ============================================================
# POSTES DE DISTANCIA - GENERADOR
# ============================================================
# UN SOLO NODO que crea TODOS los postes de distancia de la
# vuelta: 200, 400, 600, 800, 1000, 1200, 1400, 1600...
#
# Reemplaza a los nodos sueltos PosteDistancia_200 / _400 / _600,
# que usaban tres archivos identicos y un nodo por poste.
#
# CONVENCION: el numero de cada poste es lo que FALTA para llegar
# a la meta, como en un hipodromo real. El poste "200" esta a
# 200m de la meta, no a 200m de la largada.
#
# ------------------------------------------------------------
# COMO SE USA
# ------------------------------------------------------------
# Se crea UN nodo Spatial (por ejemplo "PostesDistancia"), colgado
# directo de la pista, y se le asigna este script. No hay que
# moverlo ni rotarlo: el nodo se queda quieto donde este, y los
# postes se ubican solos como hijos suyos.
#
# Intervalo Metros -> cada cuantos metros va un poste (200).
# Cantidad Maxima  -> cuantos postes hacer. 0 = la vuelta entera.
#
# ------------------------------------------------------------
# POR QUE LOS NUMEROS SON UNA SOLA MALLA
# ------------------------------------------------------------
# Antes cada digito se dibujaba con once cajitas 3D sueltas, y el
# numero va en las dos caras del poste. Un poste "1600" eran unas
# 88 mallas. Dieciseis postes, mas de 1400.
# Aca todos los digitos de un poste se fusionan en UNA malla. Cada
# poste queda en 5 mallas y la vuelta entera en unas 80.
#
# ------------------------------------------------------------
# EN EL EDITOR
# ------------------------------------------------------------
# Los postes se ven en el editor, pero en una posicion APROXIMADA:
# el editor usa la meta guardada en la escena, y el juego recalcula
# la meta segun la distancia de carrera elegida. Sirve para ver
# donde caen y como se ven; la posicion exacta es la del juego.
#
# Los postes se crean sin "owner" a proposito: NO se guardan en el
# archivo de la escena, se regeneran en cada arranque.
# ============================================================

# --- Que postes hacer ---
export var intervalo_metros = 200.0 setget _set_intervalo_metros
export var cantidad_maxima = 0 setget _set_cantidad_maxima
export var ocultar_si_la_carrera_es_mas_corta = false setget _set_ocultar_si_corta

# --- Medidas de la columna ---
export var altura_poste = 6.0 setget _set_altura_poste
export var ancho_poste = 1.6 setget _set_ancho_poste
export var fondo_poste = 1.6 setget _set_fondo_poste

# --- Base / pedestal de abajo ---
export var altura_base = 1.6 setget _set_altura_base
export var ancho_base = 2.2 setget _set_ancho_base
export var fondo_base = 2.2 setget _set_fondo_base

# --- Ribete vino tinto ---
export var alto_ribete = 0.4 setget _set_alto_ribete

# --- Numero tallado en la cara ---
export var grosor_trazo = 0.12 setget _set_grosor_trazo
export var alto_numero = 1.4 setget _set_alto_numero
export var separacion_digitos = 1.8 setget _set_separacion_digitos

# TILDADA: los digitos se apilan de arriba hacia abajo sobre la
# columna, como el cartel del poste de meta. Es lo correcto en un
# hipodromo y permite postes delgados.
# DESTILDADA: los digitos van uno al lado del otro (necesita un
# poste mucho mas ancho).
export var numeros_verticales = true setget _set_numeros_verticales

# --- Colores ---
export var color_poste = Color(1.0, 1.0, 1.0) setget _set_color_poste
export var color_base = Color(0.95, 0.95, 0.95) setget _set_color_base
export var color_ribete = Color(0.48, 0.08, 0.17) setget _set_color_ribete
export var color_numero = Color(0.48, 0.08, 0.17) setget _set_color_numero

export var sin_sombreado = true setget _set_sin_sombreado

# --- Ubicacion ---
export var alejar_de_pista = 10.0 setget _set_alejar_de_pista
export var invertir_lado = false setget _set_invertir_lado
export(NodePath) var camino_pista_path setget _set_camino_pista_path
export var mostrar_diagnostico = true setget _set_mostrar_diagnostico

var _reconstruccion_pedida = false


# ------------------------------------------------------------
# ARRANQUE
# ------------------------------------------------------------
func _ready():
	call_deferred("_reconstruir")


func _pedir_reconstruccion():
	if not is_inside_tree():
		return
	if _reconstruccion_pedida:
		return
	_reconstruccion_pedida = true
	call_deferred("_reconstruir")


func _reconstruir():
	_reconstruccion_pedida = false
	if not is_inside_tree():
		return

	_borrar_lo_construido()

	var camino = _obtener_camino_pista()
	if camino == null or camino.curve == null:
		if mostrar_diagnostico:
			print("[BDG-Postes] No encontre TrackPath o no tiene curva. No hago nada.")
		return

	var largo_total = camino.curve.get_baked_length()
	if largo_total <= 0.0:
		return

	var offset_meta = _obtener_offset_meta_real()
	if offset_meta < 0.0:
		if mostrar_diagnostico:
			print("[BDG-Postes] No pude calcular la meta. No hago nada.")
		return

	var paso = max(intervalo_metros, 1.0)
	var cuantos = int(cantidad_maxima)
	if cuantos <= 0:
		cuantos = int(largo_total / paso)
	if cuantos < 1:
		return

	var largo_carrera = _obtener_largo_de_carrera()

	# Un solo rastreador para todos los postes.
	var rastreador = PathFollow.new()
	camino.add_child(rastreador)

	var hechos = 0
	for i in range(1, cuantos + 1):
		var distancia = i * paso

		if ocultar_si_la_carrera_es_mas_corta and largo_carrera > 0.0 and distancia > largo_carrera:
			continue

		var offset_marca = fposmod(offset_meta - distancia, largo_total)
		_crear_un_poste(distancia, offset_marca, rastreador, largo_total)
		hechos += 1

	camino.remove_child(rastreador)
	rastreador.queue_free()

	if mostrar_diagnostico:
		print("[BDG-Postes] ", hechos, " postes creados cada ", paso, "m | meta en offset=", offset_meta, " | vuelta=", largo_total, "m")


func _borrar_lo_construido():
	for hijo in get_children():
		if hijo.name.begins_with("Poste_"):
			remove_child(hijo)
			hijo.queue_free()


# ------------------------------------------------------------
# UN POSTE
# ------------------------------------------------------------
func _crear_un_poste(distancia, offset_marca, rastreador, largo_total):
	rastreador.offset = offset_marca
	var punto = rastreador.global_transform.origin
	rastreador.offset = fposmod(offset_marca + 1.0, largo_total)
	var punto_adelante = rastreador.global_transform.origin

	var avance = punto_adelante - punto
	avance.y = 0.0
	if avance.length() < 0.001:
		avance = Vector3(0, 0, -1)
	avance = avance.normalized()

	var lateral = avance.cross(Vector3.UP).normalized()
	if invertir_lado:
		lateral = -lateral
	var pos_mundial = punto - lateral * alejar_de_pista

	var poste = Spatial.new()
	poste.name = "Poste_" + str(int(round(distancia)))
	add_child(poste)

	var transformacion = Transform()
	transformacion = transformacion.looking_at(avance, Vector3.UP)
	transformacion.origin = pos_mundial
	poste.global_transform = transformacion

	_crear_caja(poste, "Base", Vector3(ancho_base, altura_base, fondo_base), altura_base / 2.0, color_base)
	_crear_caja(poste, "BasePie", Vector3(ancho_base * 1.08, alto_ribete, fondo_base * 1.08), alto_ribete / 2.0, color_ribete)
	_crear_caja(poste, "Columna", Vector3(ancho_poste, altura_poste, fondo_poste), altura_base + altura_poste / 2.0, color_poste)
	_crear_caja(poste, "Ribete", Vector3(ancho_poste * 1.15, alto_ribete, fondo_poste * 1.15), altura_base + altura_poste - alto_ribete / 2.0, color_ribete)

	_crear_numero(poste, distancia)


func _hacer_material(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	material.flags_unshaded = sin_sombreado
	return material


func _crear_caja(padre, nombre, tamano, posicion_y, color):
	var caja = MeshInstance.new()
	var malla = CubeMesh.new()
	malla.size = tamano
	caja.mesh = malla
	caja.material_override = _hacer_material(color)
	caja.translation = Vector3(0, posicion_y, 0)
	caja.name = nombre
	padre.add_child(caja)
	return caja


# ------------------------------------------------------------
# NUMERO (todos los digitos fusionados en UNA sola malla)
# ------------------------------------------------------------
func _mapa_numeros():
	return {
		"0": ["111", "101", "101", "101", "111"],
		"1": ["010", "110", "010", "010", "111"],
		"2": ["111", "001", "111", "100", "111"],
		"3": ["111", "001", "111", "001", "111"],
		"4": ["101", "101", "111", "001", "001"],
		"5": ["111", "100", "111", "001", "111"],
		"6": ["111", "100", "111", "101", "111"],
		"7": ["111", "001", "001", "001", "001"],
		"8": ["111", "101", "111", "101", "111"],
		"9": ["111", "101", "111", "001", "111"]
	}


func _crear_numero(poste, distancia):
	var texto = str(int(round(distancia)))
	var cantidad = texto.length()
	if cantidad == 0:
		return

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var z_cara = fondo_poste / 2.0 + grosor_trazo / 2.0
	var hubo_algo = false

	if numeros_verticales:
		# Apilados de arriba hacia abajo. El primer digito arranca
		# justo debajo del ribete de la punta.
		var y_arriba = altura_base + altura_poste - alto_ribete - alto_numero
		for i in range(cantidad):
			var digito_v = texto[i]
			var y_digito = y_arriba - i * separacion_digitos
			if _agregar_digito(st, digito_v, 0.0, y_digito, z_cara, false):
				hubo_algo = true
			if _agregar_digito(st, digito_v, 0.0, y_digito, -z_cara, true):
				hubo_algo = true
	else:
		var ancho_total = cantidad * separacion_digitos
		var x_arranque = -ancho_total / 2.0 + separacion_digitos / 2.0
		var y_centro = altura_base + altura_poste - alto_numero * 0.8
		for i in range(cantidad):
			var digito_h = texto[i]
			var x_digito = x_arranque + i * separacion_digitos
			if _agregar_digito(st, digito_h, x_digito, y_centro, z_cara, false):
				hubo_algo = true
			if _agregar_digito(st, digito_h, x_digito, y_centro, -z_cara, true):
				hubo_algo = true

	if not hubo_algo:
		return

	var malla = st.commit()
	var mi = MeshInstance.new()
	mi.name = "Numero"
	mi.mesh = malla

	var mat = SpatialMaterial.new()
	mat.albedo_color = color_numero
	mat.flags_unshaded = sin_sombreado
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	mi.material_override = mat

	poste.add_child(mi)


func _agregar_digito(st, digito, x_centro, y_centro, z, espejada) -> bool:
	var mapa = _mapa_numeros()
	if not mapa.has(digito):
		return false
	var filas = mapa[digito]

	var alto_celda = alto_numero / 5.0
	var ancho_celda = alto_celda

	for fila in range(5):
		var patron = filas[fila]
		for columna in range(3):
			if patron[columna] != "1":
				continue
			var x_local = (columna - 1) * ancho_celda
			var x = x_centro + x_local
			if espejada:
				x = -x
			var y = y_centro + (2 - fila) * alto_celda
			_agregar_caja_a_malla(st, Vector3(x, y, z), Vector3(ancho_celda, alto_celda, grosor_trazo))

	return true


func _agregar_caja_a_malla(st, centro, tamano):
	var h = tamano * 0.5
	var x0 = centro.x - h.x
	var x1 = centro.x + h.x
	var y0 = centro.y - h.y
	var y1 = centro.y + h.y
	var z0 = centro.z - h.z
	var z1 = centro.z + h.z

	var p = [
		Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0),
		Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1)
	]

	var caras = [
		[0, 1, 2, 0, 2, 3],
		[5, 4, 7, 5, 7, 6],
		[4, 0, 3, 4, 3, 7],
		[1, 5, 6, 1, 6, 2],
		[3, 2, 6, 3, 6, 7],
		[4, 5, 1, 4, 1, 0]
	]

	for cara in caras:
		for idx in cara:
			st.add_normal(Vector3(0, 1, 0))
			st.add_vertex(p[idx])


# ------------------------------------------------------------
# PISTA Y META
# ------------------------------------------------------------
func _obtener_camino_pista():
	var camino = null

	if camino_pista_path != NodePath(""):
		camino = get_node_or_null(camino_pista_path)
	if camino != null:
		return camino

	camino = get_node_or_null("/root/PistaDeCarrera/TrackPath")
	if camino != null:
		return camino

	var raiz = null
	if Engine.editor_hint:
		raiz = get_tree().edited_scene_root
	if raiz == null:
		raiz = get_tree().current_scene
	if raiz != null:
		camino = raiz.find_node("TrackPath", true, false)

	return camino


func _obtener_offset_meta_real() -> float:
	# En el juego: se le pregunta al autoload (solo lectura).
	var gestor = get_node_or_null("/root/GestorNivel")
	if gestor != null:
		if "modo_recta" in gestor and gestor.modo_recta and gestor._meta_recta:
			return gestor._meta_recta.offset
		elif "_meta_ovalo" in gestor and gestor._meta_ovalo:
			return gestor._meta_ovalo.offset

	# En el editor: se lee el nodo de meta de la escena.
	var camino = _obtener_camino_pista()
	if camino != null:
		for hijo in camino.get_children():
			if "Meta" in hijo.name and "offset" in hijo:
				return hijo.offset

	return -1.0


func _obtener_largo_de_carrera() -> float:
	var gestor = get_node_or_null("/root/GestorNivel")
	if gestor == null:
		return -1.0
	if "distancia_carrera" in gestor:
		return gestor.distancia_carrera
	if "largo_carrera" in gestor:
		return gestor.largo_carrera
	return -1.0


# ------------------------------------------------------------
# SETTERS
# ------------------------------------------------------------
func _set_intervalo_metros(valor):
	intervalo_metros = valor
	_pedir_reconstruccion()


func _set_cantidad_maxima(valor):
	cantidad_maxima = valor
	_pedir_reconstruccion()


func _set_ocultar_si_corta(valor):
	ocultar_si_la_carrera_es_mas_corta = valor
	_pedir_reconstruccion()


func _set_altura_poste(valor):
	altura_poste = valor
	_pedir_reconstruccion()


func _set_ancho_poste(valor):
	ancho_poste = valor
	_pedir_reconstruccion()


func _set_fondo_poste(valor):
	fondo_poste = valor
	_pedir_reconstruccion()


func _set_altura_base(valor):
	altura_base = valor
	_pedir_reconstruccion()


func _set_ancho_base(valor):
	ancho_base = valor
	_pedir_reconstruccion()


func _set_fondo_base(valor):
	fondo_base = valor
	_pedir_reconstruccion()


func _set_alto_ribete(valor):
	alto_ribete = valor
	_pedir_reconstruccion()


func _set_grosor_trazo(valor):
	grosor_trazo = valor
	_pedir_reconstruccion()


func _set_alto_numero(valor):
	alto_numero = valor
	_pedir_reconstruccion()


func _set_separacion_digitos(valor):
	separacion_digitos = valor
	_pedir_reconstruccion()


func _set_numeros_verticales(valor):
	numeros_verticales = valor
	_pedir_reconstruccion()


func _set_color_poste(valor):
	color_poste = valor
	_pedir_reconstruccion()


func _set_color_base(valor):
	color_base = valor
	_pedir_reconstruccion()


func _set_color_ribete(valor):
	color_ribete = valor
	_pedir_reconstruccion()


func _set_color_numero(valor):
	color_numero = valor
	_pedir_reconstruccion()


func _set_sin_sombreado(valor):
	sin_sombreado = valor
	_pedir_reconstruccion()


func _set_alejar_de_pista(valor):
	alejar_de_pista = valor
	_pedir_reconstruccion()


func _set_invertir_lado(valor):
	invertir_lado = valor
	_pedir_reconstruccion()


func _set_camino_pista_path(valor):
	camino_pista_path = valor
	_pedir_reconstruccion()


func _set_mostrar_diagnostico(valor):
	mostrar_diagnostico = valor
