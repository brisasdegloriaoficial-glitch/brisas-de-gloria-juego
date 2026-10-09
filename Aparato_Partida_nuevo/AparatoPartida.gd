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

# ============================================================
# APARATO NUEVO (estilo hipodromo real): estructura verde, cartel
# con arco arriba, placas de colores y puertas dobles que se abren
# de golpe en la largada. Desmarcar "Aparato Nuevo" = el de antes.
# Todo va sin sombreado: el color que pongas es el que se ve.
# PESO: estructura, cartel, placas y puertas van en 5 dibujos en
# total (el aparato de antes eran unas 197 piezas).
# ============================================================
export var aparato_nuevo = true
export var alto_estructura = 12.0
export var alto_puertas = 7.6
export var altura_puertas_del_piso = 0.6
# Parte de arriba de cada puerta que es rejilla (el resto es panel).
export var proporcion_rejilla = 0.5
export var tamano_placa = 2.4
export var altura_placas = 10.3
# Parte del ancho total del aparato que ocupa el cartel de arriba.
export var ancho_cartel = 0.82
export var mostrar_cartel = true
export var mostrar_ruedas = true
export var radio_ruedas = 1.6
export var angulo_apertura = 95.0
export var segundos_apertura = 0.35
export var color_estructura_nueva = Color("0b7a4b")
export var color_tabiques = Color("086339")
export var color_faja = Color("096b41")
export var color_panel_puerta = Color("0e8f58")
export var color_rejilla = Color("eef1f5")
export var color_ruedas = Color("141414")
export var color_fondo_cartel = Color("0b7a4b")
export var color_letras_cartel = Color("ffffff")
# Colores oficiales de las mantillas, del 1 al 15 (fondo y numero).
export(Array, Color) var colores_placas = [Color("e53935"), Color("ffffff"), Color("1e63d6"), Color("ffd400"), Color("2eae4a"), Color("111111"), Color("ff7a00"), Color("ff5fa2"), Color("29c5f6"), Color("8e24aa"), Color("c8c8c8"), Color("a4d65e"), Color("7b4a2e"), Color("8a1538"), Color("d8c08c")]
export(Array, Color) var colores_numeros = [Color("ffffff"), Color("111111"), Color("ffffff"), Color("111111"), Color("ffffff"), Color("ffd400"), Color("111111"), Color("111111"), Color("d32f2f"), Color("ffffff"), Color("d32f2f"), Color("111111"), Color("ffffff"), Color("ffd400"), Color("111111")]
export var ruta_cartel_forma = "res://Aparato_Cartel_Forma.png"
export var ruta_cartel_texto = "res://Aparato_Cartel_Texto.png"
export var ruta_numeros = "res://Aparato_Numeros.png"
export var ruta_puerta = "res://Aparato_Puerta.png"

var _mm_puertas = null
var _puertas_frente = []
var _t_apertura = -1.0
var _firma_nueva = ""

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
		# En el editor: si cambias algo del aparato nuevo, se rearma.
		var f = _firma_aparato_nuevo()
		if f != _firma_nueva:
			_firma_nueva = f
			_pedir_reconstruccion()
		return

	if _t_apertura >= 0.0:
		_t_apertura += delta
		var avance_puertas = clamp(_t_apertura / max(segundos_apertura, 0.01), 0.0, 1.0)
		_poner_puertas(1.0 - pow(1.0 - avance_puertas, 3))
		if avance_puertas >= 1.0:
			_t_apertura = -1.0

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
	if aparato_nuevo:
		_construir_aparato_nuevo()
		return
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
	# Se abren las puertas de adelante.
	_t_apertura = 0.0

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


# ============================================================
# APARATO NUEVO - CONSTRUCCION
# ============================================================
func _firma_aparato_nuevo():
	return str([aparato_nuevo, alto_estructura, alto_puertas, altura_puertas_del_piso, proporcion_rejilla,
		tamano_placa, altura_placas, ancho_cartel, mostrar_cartel, mostrar_ruedas, radio_ruedas,
		color_estructura_nueva, color_tabiques, color_faja, color_panel_puerta, color_rejilla, color_ruedas,
		color_fondo_cartel, color_letras_cartel, colores_placas, colores_numeros,
		ruta_cartel_forma, ruta_cartel_texto, ruta_numeros, ruta_puerta])


func _construir_aparato_nuevo():
	var n = int(max(cantidad_casillas, 1))
	var A = ancho_casilla
	var L = largo_casilla
	var W = n * A
	var x0 = -W / 2.0 + corrimiento_lateral
	var xm = x0 + W / 2.0
	var zc = corrimiento_adelante
	var zf = zc - L / 2.0
	var zb = zc + L / 2.0
	var y0 = altura_sobre_el_piso
	var H = alto_estructura
	var T = 0.4

	var raiz = Spatial.new()
	raiz.name = "Gate_Estructura"
	add_child(raiz)

	# --- 1) Estructura: todo en UNA pieza, cada parte con su color ---
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var alto_tabique = alto_puertas * 0.75
	for i in range(n + 1):
		var x = x0 + i * A
		_caja_c(st, Vector3(x, y0 + H / 2.0, zf), Vector3(T, H, T), color_estructura_nueva)
		_caja_c(st, Vector3(x, y0 + H / 2.0, zb), Vector3(T, H, T), color_estructura_nueva)
		_caja_c(st, Vector3(x, y0 + H - 0.2, zc), Vector3(T, T, L), color_estructura_nueva)
		_caja_c(st, Vector3(x, y0 + altura_puertas_del_piso + alto_tabique / 2.0, zc), Vector3(0.45, alto_tabique, L - 0.4), color_tabiques)
	for z in [zf, zb]:
		_caja_c(st, Vector3(xm, y0 + H, z), Vector3(W + T, T * 1.4, T * 1.4), color_estructura_nueva)
		_caja_c(st, Vector3(xm, y0 + altura_puertas_del_piso + alto_puertas + 0.4, z), Vector3(W + T, T, T), color_estructura_nueva)
		_caja_c(st, Vector3(xm, y0 + 0.45, z), Vector3(W + T, T, T), color_estructura_nueva)
	_caja_c(st, Vector3(xm, y0 + altura_placas, zf), Vector3(W + T, tamano_placa + 0.4, 0.25), color_faja)
	_caja_c(st, Vector3(xm, y0 + altura_placas, zb), Vector3(W + T, tamano_placa + 0.4, 0.25), color_faja)
	if mostrar_ruedas:
		for x in [x0 - 1.2, x0 + W + 1.2]:
			for z in [zf + 1.0, zb - 1.0]:
				_rueda(st, Vector3(x, y0 + radio_ruedas, z), radio_ruedas, 0.9, color_ruedas)
			_caja_c(st, Vector3((x + (x0 if x < x0 else x0 + W)) / 2.0, y0 + radio_ruedas, zc), Vector3(abs(x - (x0 if x < x0 else x0 + W)) + T, 0.5, L - 1.0), color_estructura_nueva)
	_agregar_malla(raiz, "Estructura", st, _mat_colores(null, false))

	# --- 2) Placas con numero (fondo + numero en una sola pieza) ---
	var tex_num = _cargar_tex(ruta_numeros)
	if tex_num:
		var sp = SurfaceTool.new()
		sp.begin(Mesh.PRIMITIVE_TRIANGLES)
		for cara in [[zf - 0.15, -1.0], [zb + 0.15, 1.0]]:
			for i in range(n):
				var num = (n - i) if numerar_al_reves else (i + 1)
				var fondo = _color_de(colores_placas, num, Color(1, 1, 1))
				var letra = _color_de(colores_numeros, num, Color(0, 0, 0))
				var cx = x0 + (i + 0.5) * A
				var cy = y0 + altura_placas
				_quad(sp, Vector3(cx, cy, cara[0]), tamano_placa, tamano_placa, cara[1], _celda(15), fondo)
				_quad(sp, Vector3(cx, cy, cara[0] + 0.03 * cara[1]), tamano_placa * 0.9, tamano_placa * 0.9, cara[1], _celda((num - 1) % 15), letra)
		_agregar_malla(raiz, "Placas", sp, _mat_colores(tex_num, true))

	# --- 3) Cartel de arriba (forma que se tine + letras encima) ---
	if mostrar_cartel:
		var BW = W * clamp(ancho_cartel, 0.1, 1.0)
		var BH = BW * 300.0 / 2048.0
		var cy2 = y0 + H + 0.3 + BH / 2.0
		var tex_forma = _cargar_tex(ruta_cartel_forma)
		var tex_texto = _cargar_tex(ruta_cartel_texto)
		if tex_forma:
			var sf = SurfaceTool.new()
			sf.begin(Mesh.PRIMITIVE_TRIANGLES)
			_quad(sf, Vector3(xm, cy2, zf - 0.05), BW, BH, -1.0, Rect2(0, 0, 1, 1), color_fondo_cartel)
			_quad(sf, Vector3(xm, cy2, zf + 0.05), BW, BH, 1.0, Rect2(0, 0, 1, 1), color_fondo_cartel)
			_agregar_malla(raiz, "Cartel", sf, _mat_colores(tex_forma, true))
		if tex_texto:
			var sl = SurfaceTool.new()
			sl.begin(Mesh.PRIMITIVE_TRIANGLES)
			_quad(sl, Vector3(xm, cy2, zf - 0.1), BW, BH, -1.0, Rect2(0, 0, 1, 1), color_letras_cartel)
			_quad(sl, Vector3(xm, cy2, zf + 0.1), BW, BH, 1.0, Rect2(0, 0, 1, 1), color_letras_cartel)
			_agregar_malla(raiz, "CartelLetras", sl, _mat_colores(tex_texto, true))

	# --- 4) Puertas: todas en un solo dibujo que se mueve ---
	var tex_p = _cargar_tex(ruta_puerta)
	_mm_puertas = null
	_puertas_frente.clear()
	if tex_p:
		var w = A / 2.0 - 0.3
		var corte = alto_puertas * (1.0 - clamp(proporcion_rejilla, 0.0, 1.0))
		var sd = SurfaceTool.new()
		sd.begin(Mesh.PRIMITIVE_TRIANGLES)
		# La puerta va de la bisagra (x = 0) hacia +x, de pie en el piso.
		_quad_puerta(sd, w, 0.0, corte, Rect2(0, 0.5, 1, 0.5), color_panel_puerta)
		_quad_puerta(sd, w, corte, alto_puertas, Rect2(0, 0, 1, 0.5), color_rejilla)
		var malla_puerta = sd.commit()
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = malla_puerta
		mm.instance_count = n * 4
		var k = 0
		var yb = y0 + altura_puertas_del_piso
		for i in range(n):
			var xi = x0 + i * A + 0.25
			var xd = x0 + (i + 1) * A - 0.25
			for z in [zf, zb]:
				var t_izq = Transform(Basis(), Vector3(xi, yb, z))
				var t_der = Transform(Basis().scaled(Vector3(-1, 1, 1)), Vector3(xd, yb, z))
				mm.set_instance_transform(k, t_izq)
				mm.set_instance_transform(k + 1, t_der)
				if z == zf:
					_puertas_frente.append([k, Vector3(xi, yb, z), false])
					_puertas_frente.append([k + 1, Vector3(xd, yb, z), true])
				k += 2
		var mmi = MultiMeshInstance.new()
		mmi.name = "Puertas"
		mmi.multimesh = mm
		mmi.material_override = _mat_colores(tex_p, true)
		raiz.add_child(mmi)
		_mm_puertas = mm
	_t_apertura = -1.0

	if mostrar_diagnostico:
		print("[BDG-Gate] aparato NUEVO construido: ", n, " casillas | ancho total=", W)


# 0 = cerradas, 1 = abiertas del todo.
func _poner_puertas(avance):
	if _mm_puertas == null:
		return
	var ang = deg2rad(angulo_apertura) * avance
	for p in _puertas_frente:
		var b = Basis(Vector3.UP, ang)
		if p[2]:
			b = Basis(Vector3.UP, -ang) * Basis().scaled(Vector3(-1, 1, 1))
		_mm_puertas.set_instance_transform(p[0], Transform(b, p[1]))


func _color_de(lista, num, por_defecto):
	if lista == null or lista.size() == 0:
		return por_defecto
	return lista[(num - 1) % lista.size()]


# Celda del atlas de numeros (4 x 4): 0..14 = numeros 1..15, 15 = blanco lleno.
func _celda(i):
	return Rect2((i % 4) * 0.25, int(i / 4) * 0.25, 0.25, 0.25)


func _cargar_tex(ruta):
	if ruta == "" or not ResourceLoader.exists(ruta):
		if mostrar_diagnostico:
			print("[BDG-Gate] falta la imagen: ", ruta)
		return null
	return load(ruta)


func _mat_colores(tex, con_recorte):
	var m = SpatialMaterial.new()
	m.vertex_color_use_as_albedo = true
	m.flags_unshaded = sin_sombreado
	m.params_cull_mode = SpatialMaterial.CULL_DISABLED
	if tex:
		m.albedo_texture = tex
	if con_recorte:
		m.params_use_alpha_scissor = true
		m.params_alpha_scissor_threshold = 0.5
	return m


func _agregar_malla(padre, nombre, st, mat):
	var mi = MeshInstance.new()
	mi.name = nombre
	st.generate_normals()
	mi.mesh = st.commit()
	mi.material_override = mat
	padre.add_child(mi)


func _caja_c(st, c, t, color):
	var h = t / 2.0
	var caras = [
		[Vector3(1, 0, 0), [Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z)]],
		[Vector3(-1, 0, 0), [Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z)]],
		[Vector3(0, 1, 0), [Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z)]],
		[Vector3(0, -1, 0), [Vector3(-h.x, -h.y, h.z), Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z)]],
		[Vector3(0, 0, 1), [Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z)]],
		[Vector3(0, 0, -1), [Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z)]],
	]
	for cara in caras:
		var v = cara[1]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.add_color(color)
			st.add_uv(Vector2(0, 0))
			st.add_vertex(c + v[idx])


func _rueda(st, c, r, ancho, color):
	var lados = 16
	for k in range(lados):
		var a0 = TAU * k / lados
		var a1 = TAU * (k + 1) / lados
		var p0 = Vector3(0, cos(a0) * r, sin(a0) * r)
		var p1 = Vector3(0, cos(a1) * r, sin(a1) * r)
		var dx = Vector3(ancho / 2.0, 0, 0)
		for tri in [[c + p0 + dx, c + p1 + dx, c + p1 - dx], [c + p0 + dx, c + p1 - dx, c + p0 - dx],
				[c + dx, c + p1 + dx, c + p0 + dx], [c - dx, c + p0 - dx, c + p1 - dx]]:
			for v in tri:
				st.add_color(color)
				st.add_uv(Vector2(0, 0))
				st.add_vertex(v)


# Cuadro de frente. lado = -1 mira hacia adelante (-Z), 1 hacia atras.
# La imagen se ve derecha (no espejada) desde el lado al que mira.
func _quad(st, c, ancho, alto, lado, uv, color):
	var hx = ancho / 2.0 * -lado
	var hy = alto / 2.0
	var u0 = uv.position.x
	var v0 = uv.position.y
	var u1 = uv.position.x + uv.size.x
	var v1 = uv.position.y + uv.size.y
	var p = [Vector3(-hx, hy, 0), Vector3(hx, hy, 0), Vector3(hx, -hy, 0), Vector3(-hx, -hy, 0)]
	var t = [Vector2(u1, v0), Vector2(u0, v0), Vector2(u0, v1), Vector2(u1, v1)]
	for idx in [0, 1, 2, 0, 2, 3]:
		st.add_color(color)
		st.add_uv(t[idx])
		st.add_vertex(c + p[idx])


func _quad_puerta(st, w, y_abajo, y_arriba, uv, color):
	var p = [Vector3(0, y_arriba, 0), Vector3(w, y_arriba, 0), Vector3(w, y_abajo, 0), Vector3(0, y_abajo, 0)]
	var t = [Vector2(uv.position.x, uv.position.y), Vector2(uv.position.x + uv.size.x, uv.position.y),
		Vector2(uv.position.x + uv.size.x, uv.position.y + uv.size.y), Vector2(uv.position.x, uv.position.y + uv.size.y)]
	for idx in [0, 1, 2, 0, 2, 3]:
		st.add_color(color)
		st.add_uv(t[idx])
		st.add_vertex(p[idx])
