tool
extends Spatial

# ============================================================
# APARATO DE PARTIDA (gate de largada) - VERSION PROVISIONAL
# ============================================================
# Fila de casillas numeradas donde esperan los caballos antes de
# largar. Hecho con cajas a proposito: es un REPLANTEO, para tener
# el tamaño y el lugar definidos. La version linda se hara despues
# en Tripo AI y se reemplaza sin tocar nada mas.
#
# ------------------------------------------------------------
# DONDE VA ESTE NODO
# ------------------------------------------------------------
# Se cuelga como HIJO de TrackPath/Aparato_Partida, que es la
# linea pintada de salida. Ese nodo ya se reubica solo en cada
# carrera segun la distancia elegida, asi que el aparato lo sigue
# sin que ningun codigo lo mueva.
#
# El script SOLO construye. Nunca toca la posicion ni la rotacion
# del nodo: eso lo movés vos a mano en el editor, como las
# tribunas.
#
# ------------------------------------------------------------
# COMO CUADRARLO
# ------------------------------------------------------------
# El nodo padre esta corrido 80 unidades hacia un costado de la
# pista, asi que el aparato va a aparecer descentrado la primera
# vez. Se corrige con "Corrimiento Lateral" en el Inspector.
# Proba -61.5; si se va para el otro lado, proba 61.5.
#
# Si las casillas quedan apuntando de costado en vez de mirar
# hacia adelante, girá el nodo 90 grados en Y a mano.
#
# Las piezas se crean sin "owner" a proposito: NO se guardan en el
# archivo de la escena, se regeneran cada vez.
# ============================================================

# --- Cuantas casillas y de que tamaño ---
export var cantidad_casillas = 10 setget _set_cantidad_casillas
export var ancho_casilla = 3.0 setget _set_ancho_casilla
export var largo_casilla = 6.0 setget _set_largo_casilla
export var alto_casilla = 4.0 setget _set_alto_casilla

# --- Grosor de la estructura ---
export var grosor_divisor = 0.25 setget _set_grosor_divisor
export var grosor_puerta = 0.18 setget _set_grosor_puerta
export var alto_techo = 0.35 setget _set_alto_techo

# --- Puertas ---
export var puertas_traseras = true setget _set_puertas_traseras
export var puertas_delanteras = true setget _set_puertas_delanteras
# Que proporcion del alto ocupa la puerta (1.0 = hasta el techo).
export var proporcion_alto_puerta = 0.75 setget _set_proporcion_alto_puerta

# --- Numeros arriba de cada casilla ---
export var mostrar_numeros = true setget _set_mostrar_numeros
# Numeros en LAS DOS CARAS del cartel, cada cara orientada como
# corresponde. Asi se leen bien mires desde donde mires, y no hay
# que adivinar hacia que lado quedo rotado el aparato.
# El cartel es opaco, asi que tapa los de la cara de atras.
export var numeros_en_ambas_caras = true setget _set_numeros_en_ambas_caras

# Estos dos solo se usan si apagas "ambas caras".
export var voltear_numeros = false setget _set_voltear_numeros
export var numeros_del_otro_lado = false setget _set_numeros_del_otro_lado
# Cambia desde que punta se empieza a contar, SIN espejar el dibujo
# del numero. Destildado: 1 a la izquierda, 10 a la derecha.
# Tildado: 10 a la izquierda, 1 a la derecha.
export var numerar_al_reves = false setget _set_numerar_al_reves
export var alto_numero = 1.0 setget _set_alto_numero
export var grosor_trazo = 0.12 setget _set_grosor_trazo
export var separacion_digitos = 0.9 setget _set_separacion_digitos
export var alto_cartel = 0.6 setget _set_alto_cartel

# --- Colores ---
export var color_estructura = Color(0.93, 0.93, 0.93) setget _set_color_estructura
export var color_puerta = Color(0.48, 0.08, 0.17) setget _set_color_puerta
export var color_techo = Color(0.85, 0.85, 0.85) setget _set_color_techo
export var color_numero = Color(0.1, 0.1, 0.1) setget _set_color_numero
export var color_cartel = Color(0.95, 0.95, 0.95) setget _set_color_cartel

export var sin_sombreado = true setget _set_sin_sombreado

# --- Ajuste a mano ---
# Corre todo el aparato de costado sin mover el nodo. Sirve para
# centrarlo en la pista cuando el padre viene con h_offset.
export var corrimiento_lateral = 0.0 setget _set_corrimiento_lateral
export var corrimiento_adelante = 0.0 setget _set_corrimiento_adelante
export var altura_sobre_el_piso = 0.0 setget _set_altura_sobre_el_piso

# --- Desaparecer despues de largar ---
# El aparato se apaga solo cuando el caballo puntero ya se alejo
# de la largada. Funciona igual en 800m que en 3000m, porque mide
# metros reales de avance, no tiempo ni porcentaje.
export var ocultar_despues_de_largar = true setget _set_ocultar_despues_de_largar
export var distancia_para_ocultar = 30.0 setget _set_distancia_para_ocultar

# --- Conteo de largada ---
# Al empezar la carrera, los caballos quedan retenidos dentro del
# aparato mientras corre la cuenta regresiva. Se los retiene
# apagandoles el avance (set_process false), asi no hay que tocar
# ni GestorNivel ni los scripts de cada caballo.
export var hacer_conteo_de_largada = true
export var segundos_de_conteo = 3
export var texto_de_largada = "¡A CORRER!"
export var duracion_texto_largada = 1.2
export var tamano_conteo = 170
export var grosor_contorno_conteo = 6
export var color_contorno_conteo = Color(0, 0, 0, 1)
export var escala_conteo = 6.0
export var color_conteo = Color(1.0, 0.9, 0.35)

export var mostrar_diagnostico = true setget _set_mostrar_diagnostico

var _reconstruccion_pedida = false
var _ya_se_oculto = false

var _retenidos = []
var _conteo_restante = 0.0
var _largaron = false
var _tiempo_texto_largada = 0.0
var _centro_espejo = 0.0
var _capa_conteo = null
var _label_conteo = null


# ------------------------------------------------------------
# ARRANQUE
# ------------------------------------------------------------
func _ready():
	call_deferred("_reconstruir")
	if not Engine.editor_hint:
		_crear_cartel_conteo()
		call_deferred("_retener_caballos")


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
	_construir_aparato()
	# Al reconstruir (tambien al reiniciar la carrera) vuelve a verse.
	visible = true
	_ya_se_oculto = false


# ------------------------------------------------------------
# DESAPARECER DESPUES DE LA LARGADA
# ------------------------------------------------------------
func _process(delta):
	if Engine.editor_hint:
		return

	if hacer_conteo_de_largada and not _largaron:
		_actualizar_conteo(delta)
		return

	if _tiempo_texto_largada > 0.0:
		_tiempo_texto_largada -= delta
		if _tiempo_texto_largada <= 0.0 and _label_conteo:
			_label_conteo.visible = false

	if not ocultar_despues_de_largar or _ya_se_oculto:
		return
	if not GestorNivel:
		return

	# El padre es Aparato_Partida (la linea de salida) y el abuelo
	# es TrackPath. De ahi salen el punto de largada y el largo de
	# la vuelta, sin depender de ningun otro script.
	var linea = get_parent()
	if linea == null or not ("offset" in linea):
		return
	var camino = linea.get_parent()
	if camino == null or not ("curve" in camino) or camino.curve == null:
		return

	var largo = camino.curve.get_baked_length()
	if largo <= 0.0:
		return

	var avance = fposmod(GestorNivel.obtener_offset_lider() - linea.offset, largo)
	if avance >= distancia_para_ocultar and avance < largo * 0.5:
		visible = false
		_ya_se_oculto = true
		if mostrar_diagnostico:
			print("[BDG-Gate] largaron, aparato oculto a los ", avance, "m")


func _borrar_lo_construido():
	for hijo in get_children():
		if hijo.name.begins_with("Gate_"):
			remove_child(hijo)
			hijo.queue_free()


# ------------------------------------------------------------
# CONSTRUCCION
# ------------------------------------------------------------
func _construir_aparato():
	var cuantas = int(max(cantidad_casillas, 1))
	var ancho_total = cuantas * ancho_casilla

	# Se centra en el origen del nodo, mas el corrimiento a mano.
	var x_borde = -ancho_total / 2.0 + corrimiento_lateral
	var z_centro = corrimiento_adelante
	var y_piso = altura_sobre_el_piso

	var raiz = Spatial.new()
	raiz.name = "Gate_Estructura"
	add_child(raiz)

	var alto_puerta = alto_casilla * clamp(proporcion_alto_puerta, 0.1, 1.0)

	# --- Divisores verticales: uno mas que la cantidad de casillas ---
	for i in range(cuantas + 1):
		var x = x_borde + i * ancho_casilla
		_crear_caja(raiz, "Divisor_%d" % i,
			Vector3(grosor_divisor, alto_casilla, largo_casilla),
			Vector3(x, y_piso + alto_casilla / 2.0, z_centro),
			color_estructura)

	# --- Puertas de cada casilla ---
	for i in range(cuantas):
		var x_centro = x_borde + i * ancho_casilla + ancho_casilla / 2.0

		if puertas_traseras:
			_crear_caja(raiz, "PuertaTrasera_%d" % i,
				Vector3(ancho_casilla - grosor_divisor, alto_puerta, grosor_puerta),
				Vector3(x_centro, y_piso + alto_puerta / 2.0, z_centro + largo_casilla / 2.0),
				color_puerta)

		if puertas_delanteras:
			_crear_caja(raiz, "PuertaDelantera_%d" % i,
				Vector3(ancho_casilla - grosor_divisor, alto_puerta, grosor_puerta),
				Vector3(x_centro, y_piso + alto_puerta / 2.0, z_centro - largo_casilla / 2.0),
				color_puerta)

	# --- Techo corrido a lo largo de todo el aparato ---
	_crear_caja(raiz, "Techo",
		Vector3(ancho_total + grosor_divisor, alto_techo, largo_casilla),
		Vector3(x_borde + ancho_total / 2.0, y_piso + alto_casilla + alto_techo / 2.0, z_centro),
		color_techo)

	if mostrar_numeros:
		_crear_numeros(raiz, cuantas, x_borde, z_centro, y_piso)

	if mostrar_diagnostico:
		print("[BDG-Gate] aparato de partida construido: ", cuantas, " casillas | ancho total=", ancho_total)


func _crear_numeros(raiz, cuantas, x_borde, z_centro, y_piso):
	var y_cartel = y_piso + alto_casilla + alto_techo + alto_cartel / 2.0
	var z_cartel = z_centro - largo_casilla / 2.0

	# Los carteles de fondo son cajas normales.
	for i in range(cuantas):
		var x_centro = x_borde + i * ancho_casilla + ancho_casilla / 2.0
		_crear_caja(raiz, "Cartel_%d" % i,
			Vector3(ancho_casilla * 0.8, alto_cartel, grosor_puerta),
			Vector3(x_centro, y_cartel, z_cartel),
			color_cartel)

	# Todos los digitos de todas las casillas, en UNA sola malla.
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hubo_algo = false
	# Centro del aparato, para poder espejar los numeros.
	_centro_espejo = x_borde + (cuantas * ancho_casilla) / 2.0

	var salto = grosor_puerta / 2.0 + grosor_trazo / 2.0

	# Cada entrada es [altura en z, si va espejado]
	var caras = []
	if numeros_en_ambas_caras:
		# BUG ARREGLADO: antes, con las dos caras activadas, ni
		# "voltear_numeros" ni "numeros_del_otro_lado" se leian, asi
		# que tildarlas no hacia nada. Ahora "Voltear Numeros" elige
		# cual de las dos caras es la que se lee derecha. Ojo: el
		# espejo tambien invierte el ORDEN a lo ancho (el 1 se va al
		# lugar del 10), por eso se ven los dos problemas juntos.
		caras.append([z_cartel - salto, voltear_numeros])
		caras.append([z_cartel + salto, not voltear_numeros])
	else:
		var z_unico = z_cartel - salto
		if numeros_del_otro_lado:
			z_unico = z_cartel + salto
		caras.append([z_unico, voltear_numeros])

	var y_digitos = y_cartel - alto_numero / 2.0

	for cara in caras:
		var z_digitos = cara[0]
		var espejo = cara[1]
		for i in range(cuantas):
			var x_casilla = x_borde + i * ancho_casilla + ancho_casilla / 2.0
			var texto = str(i + 1)
			if numerar_al_reves:
				texto = str(cuantas - i)
			var ancho_txt = texto.length() * separacion_digitos
			var x_arranque = x_casilla - ancho_txt / 2.0 + separacion_digitos / 2.0
			for d in range(texto.length()):
				var x_digito = x_arranque + d * separacion_digitos
				if _agregar_digito(st, texto[d], x_digito, y_digitos, z_digitos, espejo):
					hubo_algo = true

	if not hubo_algo:
		return

	var mi = MeshInstance.new()
	mi.name = "Numeros"
	mi.mesh = st.commit()
	var mat = SpatialMaterial.new()
	mat.albedo_color = color_numero
	mat.flags_unshaded = sin_sombreado
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	mi.material_override = mat
	raiz.add_child(mi)


# ------------------------------------------------------------
# DIGITOS
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


func _agregar_digito(st, digito, x_centro, y_base, z, espejo = false) -> bool:
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
			var x = x_centro + (columna - 1) * ancho_celda
			if espejo:
				x = 2.0 * _centro_espejo - x
			var y = y_base + (4 - fila) * alto_celda
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
# AYUDANTES
# ------------------------------------------------------------
func _hacer_material(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	material.flags_unshaded = sin_sombreado
	return material


func _crear_caja(padre, nombre, tamano, posicion, color):
	var caja = MeshInstance.new()
	var malla = CubeMesh.new()
	malla.size = tamano
	caja.mesh = malla
	caja.material_override = _hacer_material(color)
	caja.translation = posicion
	caja.name = nombre
	padre.add_child(caja)
	return caja


# ------------------------------------------------------------
# RETENCION Y CONTEO DE LARGADA
# ------------------------------------------------------------
# Los caballos son los nodos Enrutador_CaballoN que cuelgan de
# TrackPath. Apagarles el _process los deja clavados donde estan,
# sin pelear con ningun otro sistema, y volver a prenderlo los
# larga. No se les toca ni la posicion ni la velocidad.
func _retener_caballos():
	if not hacer_conteo_de_largada:
		return

	_retenidos.clear()
	var camino = _obtener_trackpath()
	if camino == null:
		if mostrar_diagnostico:
			print("[BDG-Gate] no encontre TrackPath, no puedo retener a los caballos.")
		_largaron = true
		return

	for hijo in camino.get_children():
		if hijo.name.begins_with("Enrutador_"):
			hijo.set_process(false)
			_retenidos.append(hijo)

	_conteo_restante = float(max(segundos_de_conteo, 1))
	_largaron = false

	if mostrar_diagnostico:
		print("[BDG-Gate] ", _retenidos.size(), " caballos retenidos. Conteo de ", _conteo_restante, " segundos.")


func _obtener_trackpath():
	var linea = get_parent()
	if linea == null:
		return null
	var camino = linea.get_parent()
	if camino != null and ("curve" in camino):
		return camino
	return null


func _actualizar_conteo(delta):
	_conteo_restante -= delta

	if _conteo_restante > 0.0 and _label_conteo:
		_label_conteo.text = str(int(ceil(_conteo_restante)))
		_label_conteo.visible = true
		return

	_largar()


func _largar():
	for caballo in _retenidos:
		if is_instance_valid(caballo):
			caballo.set_process(true)
	_retenidos.clear()
	_largaron = true
	_tiempo_texto_largada = duracion_texto_largada

	if _label_conteo:
		_label_conteo.text = texto_de_largada
		_label_conteo.visible = true

	if mostrar_diagnostico:
		print("[BDG-Gate] LARGARON.")


func _crear_cartel_conteo():
	_capa_conteo = CanvasLayer.new()
	_capa_conteo.layer = 11
	add_child(_capa_conteo)

	_label_conteo = Label.new()
	_label_conteo.align = Label.ALIGN_CENTER
	_label_conteo.valign = Label.VALIGN_CENTER
	_label_conteo.anchor_right = 1
	_label_conteo.anchor_bottom = 1
	_label_conteo.margin_left = 0
	_label_conteo.margin_top = 0
	_label_conteo.margin_right = 0
	_label_conteo.margin_bottom = 0
	_label_conteo.add_color_override("font_color", color_conteo)
	_capa_conteo.add_child(_label_conteo)

	_aplicar_fuente_conteo()
	_label_conteo.visible = false


func _aplicar_fuente_conteo():
	# Si el proyecto tiene una fuente de verdad, se usa el tamano
	# real (nitido). Si no, se estira como antes (respaldo).
	var base = _label_conteo.get_font("font")
	if base != null and base is DynamicFont and base.font_data != null:
		var f = DynamicFont.new()
		f.font_data = base.font_data
		f.size = max(10, tamano_conteo)
		if grosor_contorno_conteo > 0:
			f.outline_size = grosor_contorno_conteo
			f.outline_color = color_contorno_conteo
		_label_conteo.add_font_override("font", f)
		_label_conteo.rect_scale = Vector2(1, 1)
		if mostrar_diagnostico:
			print("[BDG-Gate] Conteo con fuente real, tamano ", f.size)
	else:
		var tam = get_viewport().size
		_label_conteo.rect_pivot_offset = tam / 2.0
		_label_conteo.rect_scale = Vector2(escala_conteo, escala_conteo)
		if mostrar_diagnostico:
			print("[BDG-Gate] Conteo sin fuente propia, estirado.")


# ------------------------------------------------------------
# SETTERS
# ------------------------------------------------------------
func _set_cantidad_casillas(valor):
	cantidad_casillas = valor
	_pedir_reconstruccion()


func _set_ancho_casilla(valor):
	ancho_casilla = valor
	_pedir_reconstruccion()


func _set_largo_casilla(valor):
	largo_casilla = valor
	_pedir_reconstruccion()


func _set_alto_casilla(valor):
	alto_casilla = valor
	_pedir_reconstruccion()


func _set_grosor_divisor(valor):
	grosor_divisor = valor
	_pedir_reconstruccion()


func _set_grosor_puerta(valor):
	grosor_puerta = valor
	_pedir_reconstruccion()


func _set_alto_techo(valor):
	alto_techo = valor
	_pedir_reconstruccion()


func _set_puertas_traseras(valor):
	puertas_traseras = valor
	_pedir_reconstruccion()


func _set_puertas_delanteras(valor):
	puertas_delanteras = valor
	_pedir_reconstruccion()


func _set_proporcion_alto_puerta(valor):
	proporcion_alto_puerta = valor
	_pedir_reconstruccion()


func _set_mostrar_numeros(valor):
	mostrar_numeros = valor
	_pedir_reconstruccion()


func _set_alto_numero(valor):
	alto_numero = valor
	_pedir_reconstruccion()


func _set_grosor_trazo(valor):
	grosor_trazo = valor
	_pedir_reconstruccion()


func _set_separacion_digitos(valor):
	separacion_digitos = valor
	_pedir_reconstruccion()


func _set_alto_cartel(valor):
	alto_cartel = valor
	_pedir_reconstruccion()


func _set_color_estructura(valor):
	color_estructura = valor
	_pedir_reconstruccion()


func _set_color_puerta(valor):
	color_puerta = valor
	_pedir_reconstruccion()


func _set_color_techo(valor):
	color_techo = valor
	_pedir_reconstruccion()


func _set_color_numero(valor):
	color_numero = valor
	_pedir_reconstruccion()


func _set_color_cartel(valor):
	color_cartel = valor
	_pedir_reconstruccion()


func _set_sin_sombreado(valor):
	sin_sombreado = valor
	_pedir_reconstruccion()


func _set_numeros_en_ambas_caras(valor):
	numeros_en_ambas_caras = valor
	_pedir_reconstruccion()


func _set_voltear_numeros(valor):
	voltear_numeros = valor
	_pedir_reconstruccion()


func _set_numeros_del_otro_lado(valor):
	numeros_del_otro_lado = valor
	_pedir_reconstruccion()


func _set_numerar_al_reves(valor):
	numerar_al_reves = valor
	_pedir_reconstruccion()


func _set_corrimiento_lateral(valor):
	corrimiento_lateral = valor
	_pedir_reconstruccion()


func _set_corrimiento_adelante(valor):
	corrimiento_adelante = valor
	_pedir_reconstruccion()


func _set_altura_sobre_el_piso(valor):
	altura_sobre_el_piso = valor
	_pedir_reconstruccion()


func _set_ocultar_despues_de_largar(valor):
	ocultar_despues_de_largar = valor


func _set_distancia_para_ocultar(valor):
	distancia_para_ocultar = valor


func _set_mostrar_diagnostico(valor):
	mostrar_diagnostico = valor
