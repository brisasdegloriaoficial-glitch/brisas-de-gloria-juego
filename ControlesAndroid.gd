extends CanvasLayer

# ============================================================
# CONTROLES TACTILES PARA ANDROID / CELULARES
# ============================================================
# Almohadilla muy translucida + flechita chica.
# La idea es estorbar lo menos posible la vision de la carrera.
#
# TODO se ajusta desde el Inspector (seleccionando este nodo).
# ============================================================

# --- Mostrar / tamanos ---
export var mostrar_siempre = false

# Los mandos no se dibujan mientras esta la pantalla de inicio, asi
# la lista de distancias tiene la pantalla entera para ella sola.
# Aparecen solos apenas arranca la carrera.
export var ocultar_hasta_la_partida = true
export var nombre_pantalla_inicio = "PantallaInicio"
export var margen_borde = 16
export var separacion = 10
export var ancho_boton = 72
export var alto_boton = 72

# --- Almohadilla (el cuadradito de fondo) ---
export var color_almohadilla = Color(0, 0, 0, 0.13)
export var color_almohadilla_presionada = Color(1, 1, 1, 0.20)
export var color_borde_almohadilla = Color(1, 1, 1, 0.10)
export var grosor_borde_almohadilla = 1
export var redondeo_esquinas = 14

# --- Flecha ---
export var ancho_flecha = 24
export var alto_flecha = 20
export var altura_flecha_en_boton = 0.42   # 0 = arriba del todo, 1 = abajo del todo
export var color_flecha = Color(0.937, 0.808, 0.353, 0.62)
export var grosor_contorno_flecha = 0      # subilo a 2 si la queres mas marcada
export var color_contorno_flecha = Color(0, 0, 0, 0.45)

# --- Etiqueta (el nombre del boton) ---
export var mostrar_etiquetas = true
export var escala_texto_etiqueta = 0.8
export var grosor_contorno_etiqueta = 1
export var color_etiqueta = Color(1, 1, 1, 0.78)
export var color_contorno_etiqueta = Color(0, 0, 0, 0.85)


var _botones = []
var _visibles = true


func _ready():
	# La pantalla de inicio deja el juego en pausa. Sin esto, este
	# script tambien se congela y nunca se entera de que la carrera
	# arranco.
	pause_mode = Node.PAUSE_MODE_PROCESS

	if not mostrar_siempre and not OS.has_touchscreen_ui_hint():
		return

	if ocultar_hasta_la_partida:
		_visibles = false

	var t = Vector2(ancho_boton, alto_boton)

	# ---------- GRUPO IZQUIERDO ----------
	var centro_x = margen_borde + t.x + separacion
	var fila_media_y = -(margen_borde + t.y + separacion)
	var fila_arriba_y = -(margen_borde + (t.y * 2) + (separacion * 2))

	# ARREO va arriba en la cruz izquierda y CAMBIO DE MANO se fue al
	# grupo derecho. Asi el pulgar izquierdo arrea y el derecho
	# castiga al mismo tiempo, que es el efecto turbo.
	_agregar_boton("arriba", "ARREO", t, "izquierda",
		Vector2(centro_x, fila_arriba_y), "arreo")
	_agregar_boton("abajo", "CAMARA", t, "izquierda",
		Vector2(centro_x, -margen_borde), "cambiar_camara")
	_agregar_boton("izquierda", "GIRAR IZQ", t, "izquierda",
		Vector2(margen_borde, fila_media_y), "girar_izquierda")
	_agregar_boton("derecha", "GIRAR DER", t, "izquierda",
		Vector2(centro_x + t.x + separacion, fila_media_y), "girar_derecha")

	# ---------- GRUPO DERECHO ----------
	_agregar_boton("arriba", "MANO", t, "derecha",
		Vector2(margen_borde + t.x + separacion, -(margen_borde + (t.y * 2) + separacion)), "cambiar_mano")
	_agregar_boton("abajo", "FRENAR", t, "derecha",
		Vector2(margen_borde + t.x + separacion, -margen_borde), "frenar")
	_agregar_boton("izquierda", "LAT. IZQ", t, "derecha",
		Vector2(margen_borde + (t.x * 2) + (separacion * 2), -(margen_borde + t.y + separacion)), "latigazo_izquierdo")
	_agregar_boton("derecha", "LAT. DER", t, "derecha",
		Vector2(margen_borde, -(margen_borde + t.y + separacion)), "latigazo_derecho")


func _agregar_boton(direccion, etiqueta, tamano, esquina, offset, accion):
	var boton = _construir_base(tamano)
	_dibujar_flecha(boton, direccion, tamano)
	if mostrar_etiquetas:
		_agregar_etiqueta(boton, etiqueta)
	_posicionar(boton, esquina, offset, tamano)
	boton.connect("button_down", self, "_on_boton_bajado", [accion])
	boton.connect("button_up", self, "_on_boton_soltado", [accion])
	if ocultar_hasta_la_partida:
		boton.visible = false
	_botones.append(boton)


# ------------------------------------------------------------
# FLECHA: triangulo dibujado, chico y translucido.
# ------------------------------------------------------------
func _dibujar_flecha(boton, direccion, tamano):
	var centro = Vector2(tamano.x * 0.5, tamano.y * altura_flecha_en_boton)
	var puntos = _puntos_triangulo(direccion, centro)

	if grosor_contorno_flecha > 0:
		var contorno = Polygon2D.new()
		contorno.polygon = _expandir(puntos, centro, grosor_contorno_flecha)
		contorno.color = color_contorno_flecha
		boton.add_child(contorno)

	var relleno = Polygon2D.new()
	relleno.polygon = puntos
	relleno.color = color_flecha
	boton.add_child(relleno)


func _puntos_triangulo(direccion, c):
	var mx = ancho_flecha * 0.5
	var my = alto_flecha * 0.5
	var p = PoolVector2Array()

	if direccion == "arriba":
		p.append(Vector2(c.x, c.y - my))
		p.append(Vector2(c.x + mx, c.y + my))
		p.append(Vector2(c.x - mx, c.y + my))
	elif direccion == "abajo":
		p.append(Vector2(c.x, c.y + my))
		p.append(Vector2(c.x - mx, c.y - my))
		p.append(Vector2(c.x + mx, c.y - my))
	elif direccion == "izquierda":
		p.append(Vector2(c.x - mx, c.y))
		p.append(Vector2(c.x + mx, c.y - my))
		p.append(Vector2(c.x + mx, c.y + my))
	else:
		p.append(Vector2(c.x + mx, c.y))
		p.append(Vector2(c.x - mx, c.y + my))
		p.append(Vector2(c.x - mx, c.y - my))

	return p


func _expandir(puntos, centro, cantidad):
	var salida = PoolVector2Array()
	for punto in puntos:
		var direccion = punto - centro
		if direccion.length() < 0.001:
			salida.append(punto)
		else:
			salida.append(centro + direccion + direccion.normalized() * cantidad)
	return salida


# ------------------------------------------------------------
# ETIQUETA: va DENTRO de la almohadilla, abajo de la flecha.
# Lleva 4 copias oscuras detras que hacen de contorno.
# ------------------------------------------------------------
func _agregar_etiqueta(boton, texto):
	var g = grosor_contorno_etiqueta
	if g > 0:
		_crear_label(boton, texto, color_contorno_etiqueta, Vector2(-g, -g))
		_crear_label(boton, texto, color_contorno_etiqueta, Vector2(g, -g))
		_crear_label(boton, texto, color_contorno_etiqueta, Vector2(-g, g))
		_crear_label(boton, texto, color_contorno_etiqueta, Vector2(g, g))

	_crear_label(boton, texto, color_etiqueta, Vector2(0, 0))


func _crear_label(boton, texto, color, corrimiento):
	var lbl = Label.new()
	lbl.text = texto
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_color_override("font_color", color)
	lbl.anchor_left = 0
	lbl.anchor_right = 1
	lbl.anchor_top = 0.66
	lbl.anchor_bottom = 1
	lbl.margin_left = corrimiento.x
	lbl.margin_right = corrimiento.x
	lbl.margin_top = corrimiento.y
	lbl.margin_bottom = corrimiento.y
	boton.add_child(lbl)
	_ajustar_fuente(lbl, escala_texto_etiqueta)
	return lbl


func _ajustar_fuente(label, escala):
	if escala == 1.0:
		return
	var fuente_actual = label.get_font("font")
	if fuente_actual and fuente_actual is DynamicFont:
		var fuente_nueva = DynamicFont.new()
		fuente_nueva.font_data = fuente_actual.font_data
		fuente_nueva.size = max(8, int(fuente_actual.size * escala))
		label.add_font_override("font", fuente_nueva)


func _construir_base(tamano):
	var boton = Button.new()
	boton.rect_min_size = tamano
	boton.focus_mode = Control.FOCUS_NONE
	boton.clip_text = true

	boton.add_stylebox_override("normal", _crear_estilo(color_almohadilla))
	boton.add_stylebox_override("hover", _crear_estilo(color_almohadilla))
	boton.add_stylebox_override("pressed", _crear_estilo(color_almohadilla_presionada))

	add_child(boton)
	return boton


func _crear_estilo(color):
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = color_borde_almohadilla
	estilo.set_border_width_all(grosor_borde_almohadilla)
	estilo.corner_radius_top_left = redondeo_esquinas
	estilo.corner_radius_top_right = redondeo_esquinas
	estilo.corner_radius_bottom_left = redondeo_esquinas
	estilo.corner_radius_bottom_right = redondeo_esquinas
	return estilo


func _posicionar(boton, esquina, offset, tamano):
	if esquina == "izquierda":
		boton.anchor_left = 0
		boton.anchor_right = 0
		boton.anchor_top = 1
		boton.anchor_bottom = 1
		boton.margin_left = offset.x
		boton.margin_right = offset.x + tamano.x
		boton.margin_top = offset.y - tamano.y
		boton.margin_bottom = offset.y
	else:
		boton.anchor_left = 1
		boton.anchor_right = 1
		boton.anchor_top = 1
		boton.anchor_bottom = 1
		boton.margin_left = -offset.x - tamano.x
		boton.margin_right = -offset.x
		boton.margin_top = offset.y - tamano.y
		boton.margin_bottom = offset.y


func _on_boton_bajado(accion):
	Input.action_press(accion)


func _on_boton_soltado(accion):
	Input.action_release(accion)


# ------------------------------------------------------------
# Mostrar los mandos recien cuando arranca la carrera
# ------------------------------------------------------------
# La pantalla de inicio se borra sola al apretar PARTIDA. Mientras
# siga estando, los mandos quedan escondidos.
func _process(_delta):
	if not ocultar_hasta_la_partida or _botones.empty():
		return

	var mostrar = _pantalla_de_inicio() == null
	if mostrar == _visibles:
		return

	_visibles = mostrar
	for boton in _botones:
		if is_instance_valid(boton):
			boton.visible = mostrar


func _pantalla_de_inicio():
	var padre = get_parent()
	var pantalla = null
	if padre:
		pantalla = padre.get_node_or_null(nombre_pantalla_inicio)
	if pantalla == null and get_tree().current_scene:
		pantalla = get_tree().current_scene.get_node_or_null(nombre_pantalla_inicio)
	if pantalla and pantalla.is_queued_for_deletion():
		return null
	return pantalla
