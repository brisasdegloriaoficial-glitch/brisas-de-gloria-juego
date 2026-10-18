extends CanvasLayer

# ============================================================
# CONTROLES TACTILES PARA ANDROID / CELULARES
# ============================================================
# Una sola cruz, abajo a la derecha, para jugar con un pulgar:
#   arriba = ARREO, abajo = FRENAR,
#   izquierda / derecha = CARRIL, centro = LATIGO.
# Y abajo a la izquierda, un solo boton: CAMBIO DE CAMARA.
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
# En la pausa los mandos se esconden, para que no tapen la ruedita
# de ajustes ni los botones REANUDAR y REINICIAR. Al reanudar vuelven.
export var ocultar_en_pausa = true
export var nombre_pantalla_inicio = "PantallaInicio"
export var margen_borde = 16
export var separacion = 10
export var ancho_boton = 72
export var alto_boton = 72
export var tamano_boton_latigo = 88     # el del centro, mas grande que las flechas

# --- Boton de camara (solo, abajo a la izquierda) ---
export var mostrar_boton_camara = true
export var texto_boton_camara = "CAMBIO DE CÁMARA"
export var ancho_boton_camara = 110     # si acortas el texto, puedes achicarlo

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
export var grosor_contorno_flecha = 0      # subelo a 2 si la quieres mas marcada
export var radio_circulo_latigo = 13      # el punto que va en el boton del latigo
export var color_contorno_flecha = Color(0, 0, 0, 0.45)

# --- Etiqueta (el nombre del boton) ---
export var mostrar_etiquetas = true
export var escala_texto_etiqueta = 0.8
export var grosor_contorno_etiqueta = 1
export var color_etiqueta = Color(1, 1, 1, 0.78)
export var color_contorno_etiqueta = Color(0, 0, 0, 0.85)


var _botones = []
var _acciones = []
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
	var c = Vector2(tamano_boton_latigo, tamano_boton_latigo)

	# ---------- UNA SOLA CRUZ, A LA DERECHA ----------
	# Centro de la cruz, medido desde la esquina de abajo a la derecha.
	var cx = margen_borde + t.x + separacion + c.x * 0.5
	var cy = margen_borde + t.y + separacion + c.y * 0.5
	var paso_x = c.x * 0.5 + separacion + t.x * 0.5
	var paso_y = c.y * 0.5 + separacion + t.y * 0.5

	_agregar_boton("arriba", "ARREO", t, Vector2(cx, cy + paso_y), "arreo")
	_agregar_boton("abajo", "FRENAR", t, Vector2(cx, cy - paso_y), "frenar")
	_agregar_boton("izquierda", "CARRIL", t, Vector2(cx + paso_x, cy), "girar_izquierda")
	_agregar_boton("derecha", "CARRIL", t, Vector2(cx - paso_x, cy), "girar_derecha")
	_agregar_boton("centro", "LÁTIGO", c, Vector2(cx, cy), "latigazo_derecho")

	# ---------- BOTON SOLO, A LA IZQUIERDA ----------
	if mostrar_boton_camara:
		var tc = Vector2(ancho_boton_camara, alto_boton)
		_agregar_boton("camara", texto_boton_camara, tc,
			Vector2(margen_borde + tc.x * 0.5, margen_borde + tc.y * 0.5), "cambiar_camara", "izquierda")


func _agregar_boton(direccion, etiqueta, tamano, centro, accion, lado = "derecha"):
	var boton = _construir_base(tamano)
	_dibujar_flecha(boton, direccion, tamano)
	if mostrar_etiquetas:
		_agregar_etiqueta(boton, etiqueta)
	_posicionar(boton, centro, tamano, lado)
	boton.connect("button_down", self, "_on_boton_bajado", [accion])
	boton.connect("button_up", self, "_on_boton_soltado", [accion])
	if not accion in _acciones:
		_acciones.append(accion)
	if ocultar_hasta_la_partida:
		boton.visible = false
	_botones.append(boton)


# ------------------------------------------------------------
# FLECHA: triangulo dibujado, chico y translucido.
# ------------------------------------------------------------
func _dibujar_flecha(boton, direccion, tamano):
	if direccion == "camara":
		_dibujar_camara(boton, tamano)
		return
	var centro = Vector2(tamano.x * 0.5, tamano.y * altura_flecha_en_boton)
	var puntos
	if direccion == "centro":
		puntos = _puntos_circulo(centro, radio_circulo_latigo)
	else:
		puntos = _puntos_triangulo(direccion, centro)

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


# Filmadora: cuerpo, lente al lado y dos rollos arriba.
# Su tamano sale de Ancho Flecha y Alto Flecha (Inspector).
func _dibujar_camara(boton, tamano):
	var c = Vector2(tamano.x * 0.5, tamano.y * altura_flecha_en_boton)
	var w = ancho_flecha * 0.87       # ancho del cuerpo
	var h = alto_flecha * 0.7         # alto del cuerpo
	var t = ancho_flecha * 0.4        # largo del lente
	var r = alto_flecha * 0.25        # radio de los rollos
	var bx = c.x - t * 0.5            # corre el cuerpo para que todo quede centrado
	var by = c.y + r * 0.5            # baja el cuerpo para dejarle sitio a los rollos
	var cuerpo = PoolVector2Array([
		Vector2(bx - w * 0.5, by - h * 0.5), Vector2(bx + w * 0.5, by - h * 0.5),
		Vector2(bx + w * 0.5, by + h * 0.5), Vector2(bx - w * 0.5, by + h * 0.5)])
	var lente = PoolVector2Array([
		Vector2(bx + w * 0.5 - 1, by - h * 0.12), Vector2(bx + w * 0.5 + t, by - h * 0.5),
		Vector2(bx + w * 0.5 + t, by + h * 0.5), Vector2(bx + w * 0.5 - 1, by + h * 0.12)])
	var rollo_1 = Vector2(bx - w * 0.22, by - h * 0.5 - r + 1)
	var rollo_2 = Vector2(bx + w * 0.26, by - h * 0.5 - r + 1)
	var capas = []
	if grosor_contorno_flecha > 0:
		var g = grosor_contorno_flecha
		capas.append([_expandir(cuerpo, Vector2(bx, by), g), color_contorno_flecha])
		capas.append([_expandir(lente, Vector2(bx + w * 0.5 + t * 0.5, by), g), color_contorno_flecha])
		capas.append([_puntos_circulo(rollo_1, r + g), color_contorno_flecha])
		capas.append([_puntos_circulo(rollo_2, r + g), color_contorno_flecha])
	capas.append([cuerpo, color_flecha])
	capas.append([lente, color_flecha])
	for rollo in [rollo_1, rollo_2]:
		capas.append([_puntos_circulo(rollo, r), color_flecha])
		capas.append([_puntos_circulo(rollo, r * 0.35), Color(0, 0, 0, 0.6)])
	for capa in capas:
		var pieza = Polygon2D.new()
		pieza.polygon = capa[0]
		pieza.color = capa[1]
		boton.add_child(pieza)


func _puntos_circulo(c, radio):
	var p = PoolVector2Array()
	for k in range(24):
		var a = TAU * k / 24.0
		p.append(c + Vector2(cos(a), sin(a)) * radio)
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


func _posicionar(boton, centro, tamano, lado = "derecha"):
	# centro.x = distancia desde el borde derecho (o el izquierdo)
	# centro.y = distancia desde el borde de abajo
	var ancla = 1 if lado == "derecha" else 0
	boton.anchor_left = ancla
	boton.anchor_right = ancla
	boton.anchor_top = 1
	boton.anchor_bottom = 1
	if lado == "derecha":
		boton.margin_left = -centro.x - tamano.x * 0.5
		boton.margin_right = -centro.x + tamano.x * 0.5
	else:
		boton.margin_left = centro.x - tamano.x * 0.5
		boton.margin_right = centro.x + tamano.x * 0.5
	boton.margin_top = -centro.y - tamano.y * 0.5
	boton.margin_bottom = -centro.y + tamano.y * 0.5


func _on_boton_bajado(accion):
	Input.action_press(accion)


func _on_boton_soltado(accion):
	Input.action_release(accion)


# ------------------------------------------------------------
# Mostrar los mandos recien cuando arranca la carrera,
# y esconderlos mientras el juego esta en pausa.
# ------------------------------------------------------------
# La pantalla de inicio se borra sola al apretar PARTIDA. Mientras
# siga estando, los mandos quedan escondidos.
func _process(_delta):
	if _botones.empty():
		return

	var mostrar = true
	if ocultar_hasta_la_partida and _pantalla_de_inicio() != null:
		mostrar = false
	if ocultar_en_pausa and get_tree().paused:
		mostrar = false
	if mostrar == _visibles:
		return

	_visibles = mostrar
	for boton in _botones:
		if is_instance_valid(boton):
			boton.visible = mostrar
	# Al esconderlos, se suelta cualquier boton que haya quedado apretado.
	if not mostrar:
		for accion in _acciones:
			Input.action_release(accion)


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
