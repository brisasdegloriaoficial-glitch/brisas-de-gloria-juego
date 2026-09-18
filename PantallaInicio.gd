extends CanvasLayer

# ============================================================
# PANTALLA DE INICIO (PRE-CARRERA)
# ============================================================
# Titulo, boton PARTIDA y cuenta regresiva 3-2-1.
#
# FUENTE:
# Deja el archivo Oswald.ttf en la carpeta raiz del proyecto
# (donde esta project.godot). El script lo carga solo y el
# texto se ve nitido.
#
# Si el archivo NO esta, usa la fuente interna estirada, pero
# ahora con tope: nunca la estira mas de "Estiron Maximo" y
# nunca deja que el texto se salga de la pantalla.
#
# En el panel "Salida" de Godot te avisa cual de las dos uso.
# ============================================================

export var archivo_fuente = "res://Oswald.ttf"
export var estiron_maximo = 2.0          # tope del respaldo, para que no se vea borroso
export var margen_lateral = 0.88         # cuanto del ancho puede ocupar el texto (0.88 = 88%)

# --- Fondo oscuro sobre la pista ---
export var color_fondo = Color(0, 0, 0, 0.72)

# --- Contorno y sombra de las letras ---
export var grosor_contorno = 4
export var color_contorno = Color(0, 0, 0, 1)
export var mostrar_sombra = true
export var corrimiento_sombra = Vector2(4, 5)
export var color_sombra = Color(0, 0, 0, 0.55)

# --- Titulo ---
export var mostrar_titulo = true
export var texto_titulo = "BRISAS DE GLORIA"
export var tamano_titulo = 76
export var color_titulo = Color(1.0, 0.85, 0.33)
export var altura_titulo = 0.24          # 0 = arriba del todo, 1 = abajo del todo
export var corrimiento_titulo_x = 0      # + a la derecha, - a la izquierda

# --- Subtitulo ---
export var mostrar_subtitulo = true
export var texto_subtitulo = "EL GALOPE FINAL"
export var tamano_subtitulo = 32
export var color_subtitulo = Color(1, 1, 1, 0.85)
export var altura_subtitulo = 0.36

# --- Boton PARTIDA ---
export var texto_boton = "PARTIDA"
export var ancho_boton = 360
export var alto_boton = 110
export var altura_boton = 0.63
export var tamano_texto_boton = 46
export var color_texto_boton = Color(1.0, 0.85, 0.33)
export var color_boton = Color(0.06, 0.06, 0.08, 0.96)
export var color_boton_presionado = Color(0.24, 0.20, 0.10, 0.98)
export var color_borde_boton = Color(1.0, 0.85, 0.33, 0.95)
export var grosor_borde_boton = 4
export var redondeo_boton = 20

# --- Logo de la moneda BDG ---
export var mostrar_logo = true
export var archivo_logo = "res://Caballos/Logo_Moneda_BDG_transparente.png"
export var tamano_logo = 200                      # ancho y alto en pixeles
export var posicion_logo = Vector2(0.88, 0.80)    # 0 = izquierda/arriba, 1 = derecha/abajo
export var opacidad_logo = 1.0                    # 1 = lleno, 0.5 = medio transparente

# --- Cuenta regresiva ---
# APAGADA a proposito: el 3-2-1 lo hace el aparato de partida.
# Tener los dos era contar dos veces seguidas. Si algun dia la
# queres de vuelta, prende "Hacer Cuenta Aca".
export var hacer_cuenta_aca = false
export var tamano_cuenta = 150
export var color_cuenta = Color(1.0, 0.85, 0.33)
export var segundos_por_numero = 1.0

var fuente_base = null
var boton_partida
var label_cuenta
var contando = false
var numero_actual = 3
var tiempo_paso = 0.0


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	get_tree().paused = true
	_cargar_fuente()
	_crear_fondo()
	if mostrar_titulo:
		_crear_texto_suelto(texto_titulo, color_titulo, tamano_titulo, altura_titulo, corrimiento_titulo_x)
	if mostrar_subtitulo:
		_crear_texto_suelto(texto_subtitulo, color_subtitulo, tamano_subtitulo, altura_subtitulo)
	_crear_boton()
	if mostrar_logo:
		_crear_logo()


func _cargar_fuente():
	if archivo_fuente == "" or not ResourceLoader.exists(archivo_fuente):
		print("PantallaInicio: NO encontre la fuente en ", archivo_fuente, " - uso la interna estirada.")
		return
	var datos = load(archivo_fuente)
	if datos is DynamicFontData:
		fuente_base = datos
		print("PantallaInicio: fuente cargada BIEN desde ", archivo_fuente)
	else:
		print("PantallaInicio: ", archivo_fuente, " no es una fuente valida - uso la interna estirada.")


func _ancho_pantalla():
	return get_viewport().size.x


func _crear_fondo():
	var fondo = ColorRect.new()
	fondo.color = color_fondo
	fondo.anchor_left = 0
	fondo.anchor_top = 0
	fondo.anchor_right = 1
	fondo.anchor_bottom = 1
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)


func _crear_texto_suelto(texto, color, tamano, altura, corrimiento_x = 0):
	var disponible = _ancho_pantalla() * margen_lateral

	if mostrar_sombra:
		var sombra = _armar_label(texto, color_sombra, tamano, altura, corrimiento_sombra + Vector2(corrimiento_x, 0))
		add_child(sombra)
		_aplicar_fuente(sombra, tamano, false, disponible)

	var lbl = _armar_label(texto, color, tamano, altura, Vector2(corrimiento_x, 0))
	add_child(lbl)
	_aplicar_fuente(lbl, tamano, true, disponible)
	return lbl


func _armar_label(texto, color, tamano, altura, corrimiento):
	var lbl = Label.new()
	lbl.text = texto
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_color_override("font_color", color)
	lbl.anchor_left = 0
	lbl.anchor_right = 1
	lbl.anchor_top = altura
	lbl.anchor_bottom = altura
	lbl.margin_top = -tamano + corrimiento.y
	lbl.margin_bottom = tamano + corrimiento.y
	lbl.margin_left = corrimiento.x
	lbl.margin_right = corrimiento.x
	return lbl


func _crear_logo():
	if archivo_logo == "" or not ResourceLoader.exists(archivo_logo):
		print("PantallaInicio: NO encontre el logo en ", archivo_logo)
		return
	var img = TextureRect.new()
	img.texture = load(archivo_logo)
	img.expand = true
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.modulate = Color(1, 1, 1, opacidad_logo)
	img.anchor_left = posicion_logo.x
	img.anchor_right = posicion_logo.x
	img.anchor_top = posicion_logo.y
	img.anchor_bottom = posicion_logo.y
	img.margin_left = -tamano_logo / 2.0
	img.margin_right = tamano_logo / 2.0
	img.margin_top = -tamano_logo / 2.0
	img.margin_bottom = tamano_logo / 2.0
	add_child(img)
	print("PantallaInicio: logo cargado BIEN desde ", archivo_logo)


func _crear_boton():
	boton_partida = Button.new()
	boton_partida.text = ""
	boton_partida.focus_mode = Control.FOCUS_NONE
	boton_partida.rect_min_size = Vector2(ancho_boton, alto_boton)

	boton_partida.add_stylebox_override("normal", _crear_estilo(color_boton))
	boton_partida.add_stylebox_override("hover", _crear_estilo(color_boton))
	boton_partida.add_stylebox_override("pressed", _crear_estilo(color_boton_presionado))

	boton_partida.anchor_left = 0.5
	boton_partida.anchor_right = 0.5
	boton_partida.anchor_top = altura_boton
	boton_partida.anchor_bottom = altura_boton
	boton_partida.margin_left = -ancho_boton * 0.5
	boton_partida.margin_right = ancho_boton * 0.5
	boton_partida.margin_top = -alto_boton * 0.5
	boton_partida.margin_bottom = alto_boton * 0.5

	boton_partida.connect("pressed", self, "_iniciar_cuenta")
	add_child(boton_partida)

	var lbl = Label.new()
	lbl.text = texto_boton
	lbl.align = Label.ALIGN_CENTER
	lbl.valign = Label.VALIGN_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_color_override("font_color", color_texto_boton)
	lbl.anchor_left = 0
	lbl.anchor_right = 1
	lbl.anchor_top = 0
	lbl.anchor_bottom = 1
	boton_partida.add_child(lbl)
	_aplicar_fuente(lbl, tamano_texto_boton, true, ancho_boton * 0.85)


func _crear_estilo(color):
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.border_color = color_borde_boton
	estilo.set_border_width_all(grosor_borde_boton)
	estilo.corner_radius_top_left = redondeo_boton
	estilo.corner_radius_top_right = redondeo_boton
	estilo.corner_radius_bottom_left = redondeo_boton
	estilo.corner_radius_bottom_right = redondeo_boton
	return estilo


func _iniciar_cuenta():
	boton_partida.queue_free()

	# Sin cuenta aca: se larga directo y manda el aparato de partida.
	if not hacer_cuenta_aca:
		get_tree().paused = false
		queue_free()
		return

	contando = true
	numero_actual = 3
	tiempo_paso = 0.0

	label_cuenta = Label.new()
	label_cuenta.text = str(numero_actual)
	label_cuenta.align = Label.ALIGN_CENTER
	label_cuenta.valign = Label.VALIGN_CENTER
	label_cuenta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_cuenta.add_color_override("font_color", color_cuenta)
	label_cuenta.anchor_left = 0
	label_cuenta.anchor_right = 1
	label_cuenta.anchor_top = 0
	label_cuenta.anchor_bottom = 1
	add_child(label_cuenta)
	_aplicar_fuente(label_cuenta, tamano_cuenta, true, _ancho_pantalla() * 0.5)


func _process(delta):
	if not contando:
		return
	tiempo_paso += delta
	if tiempo_paso >= segundos_por_numero:
		tiempo_paso = 0.0
		numero_actual -= 1
		if numero_actual <= 0:
			get_tree().paused = false
			queue_free()
		else:
			label_cuenta.text = str(numero_actual)


# ------------------------------------------------------------
# APLICAR FUENTE
# Con Oswald.ttf: tamano real y contorno, achicando si no entra.
# Sin el archivo: estira la interna, con tope, y tambien
# achicando si no entra.
# ------------------------------------------------------------
func _aplicar_fuente(control, tamano, con_contorno, ancho_disponible):
	if fuente_base != null:
		var f = DynamicFont.new()
		f.font_data = fuente_base
		f.size = max(8, tamano)
		if con_contorno and grosor_contorno > 0:
			f.outline_size = grosor_contorno
			f.outline_color = color_contorno

		# Si el texto no entra a lo ancho, se va achicando.
		while f.size > 10 and f.get_string_size(control.text).x > ancho_disponible:
			f.size -= 2

		control.add_font_override("font", f)
		return

	# --- Respaldo: fuente interna estirada, con tope ---
	var interna = control.get_font("font")
	if interna == null:
		return

	var alto_interno = interna.get_height()
	if alto_interno <= 0:
		return

	var escala = float(tamano) / float(alto_interno)
	escala = min(escala, estiron_maximo)

	var ancho_texto = interna.get_string_size(control.text).x
	if ancho_texto > 0:
		escala = min(escala, ancho_disponible / ancho_texto)

	if escala > 1.0:
		control.rect_scale = Vector2(escala, escala)
		call_deferred("_centrar_pivote", control)


func _centrar_pivote(control):
	if is_instance_valid(control):
		control.rect_pivot_offset = control.rect_size * 0.5
