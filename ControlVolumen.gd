extends CanvasLayer
# ControlVolumen (AutoLoad). En la portada y en la pausa aparece un ENGRANAJE
# abajo a la izquierda. Al tocarlo se abre la ventana emergente de
# CONFIGURACION (volumen y calidad), con el fondo oscurecido detras.
# Guarda lo elegido. Los AutoLoad no salen en el Inspector: todos los
# valores para ajustar estan aqui arriba, con su codigo hex.
#
# CALIDAD: otros scripts la leen con ControlVolumen.calidad
# (0 = BAJO, 1 = MEDIO, 2 = ALTO) o se conectan a la senal calidad_cambiada.

signal calidad_cambiada(nivel)

const BAJO = 0
const MEDIO = 1
const ALTO = 2

# ---- Colores (colores de la moneda) ----
const COLOR_VINO = Color("3a0a14")          # fondo de la ventana y botones
const COLOR_VINO_OSCURO = Color("1e0509")   # fondo de las barras de volumen
const COLOR_DORADO = Color("c4a159")        # bordes, letras y boton elegido
const COLOR_CERRAR = Color("ffffff")        # palabra CERRAR
const COLOR_VELO = Color(0, 0, 0, 0.5)      # oscurecido detras de la ventana

# ---- Tamanos ----
const ANCHO_PANEL = 260
const GROSOR_BORDE = 2
const REDONDEO_PANEL = 10
const REDONDEO_BOTONES = 6
const ALTO_BOTONES = 34
const TAMANO_ENGRANAJE = 44          # ancho y alto del boton redondo
const ENGRANAJE_IZQUIERDA = 14       # separacion al borde izquierdo
const ENGRANAJE_ABAJO = 14           # separacion al borde de abajo
const DIENTES_ENGRANAJE = 8

# ---- Otros ----
const CALIDAD_INICIAL = MEDIO        # la primera vez que se abre el juego

# ---- Detalles de los caballos (solo en BAJO) ----
# Mas lejos que esto de la camara, el caballo pierde brida, estribos y
# riendas (y estos dejan de calcularse cada cuadro). Al acercarse vuelven.
const DISTANCIA_DETALLES = 60.0
const CUADROS_BAJO = 30              # cuadros por segundo en BAJO
const REVISAR_DETALLES_CADA = 0.5    # segundos entre cada revision
const REBUSCAR_CABALLOS_CADA = 3.0   # segundos (el repartidor cambia caballos)
const RUTA_GUARDADO = "user://volumen_bdg.cfg"

var calidad = CALIDAD_INICIAL

var _velo = null
var _engranaje = null
var _barra_general = null
var _barra_musica = null
var _botones_calidad = []
var _bus_musica = -1
var _musica = null
var _t_buscar = 0.0
var _cargando = false
var _detalles = []
var _escena_detalles = null
var _t_detalles = 0.0
var _t_rebuscar = 0.0


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 50
	_bus_musica = AudioServer.get_bus_index("Musica")
	if _bus_musica == -1:
		AudioServer.add_bus()
		_bus_musica = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus_musica, "Musica")
		AudioServer.set_bus_send(_bus_musica, "Master")
	_construir()
	_cargar()


# ------------------------------------------------------------
# Construccion
# ------------------------------------------------------------
func _construir():
	# Velo oscuro que cubre toda la pantalla (bloquea los toques de atras).
	_velo = ColorRect.new()
	_velo.color = COLOR_VELO
	_velo.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_velo)

	var panel = PanelContainer.new()
	panel.add_stylebox_override("panel", _estilo(COLOR_VINO, COLOR_DORADO, GROSOR_BORDE, REDONDEO_PANEL, 14, 10))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.margin_left = -ANCHO_PANEL / 2
	panel.margin_right = ANCHO_PANEL / 2
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_velo.add_child(panel)

	var caja = VBoxContainer.new()
	caja.add_constant_override("separation", 8)
	panel.add_child(caja)

	_crear_titulo(caja, "VOLUMEN")
	_barra_general = _crear_barra(caja, "General")
	_barra_musica = _crear_barra(caja, "Música")

	_crear_titulo(caja, "CALIDAD")
	var fila = HBoxContainer.new()
	fila.add_constant_override("separation", 6)
	caja.add_child(fila)
	var nombres = ["BAJO", "MEDIO", "ALTO"]
	for i in range(3):
		var b = Button.new()
		b.text = nombres[i]
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.rect_min_size = Vector2(0, ALTO_BOTONES)
		b.connect("pressed", self, "_elegir_calidad", [i])
		fila.add_child(b)
		_botones_calidad.append(b)
	_pintar_botones_calidad()

	var cerrar = Button.new()
	cerrar.text = "CERRAR"
	cerrar.focus_mode = Control.FOCUS_NONE
	cerrar.rect_min_size = Vector2(0, ALTO_BOTONES)
	_pintar_boton(cerrar, COLOR_VINO, COLOR_CERRAR)
	cerrar.connect("pressed", self, "_alternar_ventana")
	caja.add_child(cerrar)

	_velo.visible = false

	# Engranaje redondo abajo a la izquierda.
	_engranaje = Button.new()
	_engranaje.focus_mode = Control.FOCUS_NONE
	var redondo = _estilo(COLOR_VINO, COLOR_DORADO, GROSOR_BORDE, TAMANO_ENGRANAJE / 2, 0, 0)
	for estado in ["normal", "hover", "pressed"]:
		_engranaje.add_stylebox_override(estado, redondo)
	_engranaje.anchor_left = 0
	_engranaje.anchor_right = 0
	_engranaje.anchor_top = 1
	_engranaje.anchor_bottom = 1
	_engranaje.margin_left = ENGRANAJE_IZQUIERDA
	_engranaje.margin_right = ENGRANAJE_IZQUIERDA + TAMANO_ENGRANAJE
	_engranaje.margin_top = -ENGRANAJE_ABAJO - TAMANO_ENGRANAJE
	_engranaje.margin_bottom = -ENGRANAJE_ABAJO
	_engranaje.connect("pressed", self, "_alternar_ventana")
	_engranaje.connect("draw", self, "_dibujar_engranaje")
	add_child(_engranaje)
	_engranaje.visible = false


func _estilo(fondo, borde, grosor, redondeo, margen_lados, margen_alto):
	var e = StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(grosor)
	e.set_corner_radius_all(redondeo)
	e.content_margin_left = margen_lados
	e.content_margin_right = margen_lados
	e.content_margin_top = margen_alto
	e.content_margin_bottom = margen_alto + 2
	return e


func _pintar_boton(boton, fondo, letra):
	var e = _estilo(fondo, COLOR_DORADO, 1, REDONDEO_BOTONES, 0, 0)
	for estado in ["normal", "hover", "pressed", "disabled"]:
		boton.add_stylebox_override(estado, e)
	for clave in ["font_color", "font_color_hover", "font_color_pressed"]:
		boton.add_color_override(clave, letra)


func _crear_titulo(caja, texto):
	var t = Label.new()
	t.text = texto
	t.align = Label.ALIGN_CENTER
	t.add_color_override("font_color", COLOR_DORADO)
	caja.add_child(t)


func _crear_barra(caja, texto):
	var etiqueta = Label.new()
	etiqueta.text = texto
	etiqueta.add_color_override("font_color", COLOR_DORADO)
	caja.add_child(etiqueta)
	var barra = HSlider.new()
	barra.min_value = 0
	barra.max_value = 100
	barra.step = 1
	barra.value = 100
	barra.rect_min_size = Vector2(ANCHO_PANEL - 28, 28)
	var pista = _estilo(COLOR_VINO_OSCURO, COLOR_VINO_OSCURO, 0, 3, 0, 3)
	var lleno = _estilo(COLOR_DORADO, COLOR_DORADO, 0, 3, 0, 3)
	barra.add_stylebox_override("slider", pista)
	barra.add_stylebox_override("grabber_area", lleno)
	barra.add_stylebox_override("grabber_area_highlight", lleno)
	barra.connect("value_changed", self, "_al_cambiar")
	caja.add_child(barra)
	return barra


# Dibuja el engranaje dorado dentro del boton redondo.
func _dibujar_engranaje():
	var c = _engranaje.rect_size / 2.0
	var r = TAMANO_ENGRANAJE * 0.24
	for i in range(DIENTES_ENGRANAJE):
		var ang = TAU * i / DIENTES_ENGRANAJE
		var dir = Vector2(cos(ang), sin(ang))
		var lado = Vector2(-dir.y, dir.x) * r * 0.32
		var base = c + dir * r * 0.8
		var punta = c + dir * r * 1.45
		_engranaje.draw_colored_polygon(PoolVector2Array([base - lado, punta - lado, punta + lado, base + lado]), COLOR_DORADO)
	_engranaje.draw_circle(c, r, COLOR_DORADO)
	_engranaje.draw_circle(c, r * 0.42, COLOR_VINO)


# ------------------------------------------------------------
# Calidad
# ------------------------------------------------------------
func _elegir_calidad(nivel):
	calidad = nivel
	_pintar_botones_calidad()
	_aplicar_resolucion()
	emit_signal("calidad_cambiada", calidad)
	if not _cargando:
		_guardar()


func _pintar_botones_calidad():
	for i in range(_botones_calidad.size()):
		if i == calidad:
			_pintar_boton(_botones_calidad[i], COLOR_DORADO, COLOR_VINO)
		else:
			_pintar_boton(_botones_calidad[i], COLOR_VINO, COLOR_DORADO)


# BAJO: el juego se dibuja al tamano base del proyecto (1024 x 600) y se
# estira a la pantalla. En un telefono eso es mucho menos trabajo para la
# tarjeta de video. Los botones quedan en el mismo lugar, un poco menos
# nitidos. MEDIO y ALTO: se dibuja a la resolucion real de la pantalla.
func _aplicar_resolucion():
	var base = Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))
	var modo = SceneTree.STRETCH_MODE_2D
	Engine.target_fps = 0                 # MEDIO y ALTO: sin tope (60 de la pantalla)
	if calidad == BAJO:
		modo = SceneTree.STRETCH_MODE_VIEWPORT
		Engine.target_fps = CUADROS_BAJO
	get_tree().set_screen_stretch(modo, SceneTree.STRETCH_ASPECT_EXPAND, base)


# ------------------------------------------------------------
# Volumen
# ------------------------------------------------------------
func _alternar_ventana():
	_velo.visible = not _velo.visible


func _al_cambiar(_valor):
	_aplicar()
	if not _cargando:
		_guardar()


func _aplicar():
	_poner_bus(0, _barra_general.value)
	_poner_bus(_bus_musica, _barra_musica.value)


func _poner_bus(bus, valor):
	AudioServer.set_bus_mute(bus, valor <= 0)
	AudioServer.set_bus_volume_db(bus, linear2db(max(valor, 1.0) / 100.0))


func _process(delta):
	var en_pausa = get_tree().paused
	_engranaje.visible = en_pausa
	if not en_pausa:
		_velo.visible = false

	# Buscar (cada segundo, si hace falta) la musica de carrera.
	if _musica == null or not is_instance_valid(_musica):
		_t_buscar -= delta
		if _t_buscar <= 0.0:
			_t_buscar = 1.0
			var escena = get_tree().current_scene
			if escena:
				_musica = escena.find_node("MusicaCarrera", true, false)

	# La musica de carrera va por su propio canal (se repite al reiniciar).
	if _musica and is_instance_valid(_musica) and _musica.bus != "Musica":
		_musica.bus = "Musica"

	_t_rebuscar -= delta
	_t_detalles -= delta
	if _t_detalles <= 0.0:
		_t_detalles = REVISAR_DETALLES_CADA
		_revisar_detalles()


# ------------------------------------------------------------
# Brida, estribos y riendas de los caballos lejanos (solo BAJO)
# ------------------------------------------------------------
func _revisar_detalles():
	var escena = get_tree().current_scene
	if escena == null:
		return
	if escena != _escena_detalles or _t_rebuscar <= 0.0:
		_escena_detalles = escena
		_t_rebuscar = REBUSCAR_CABALLOS_CADA
		_detalles = []
		_buscar_detalles(escena)
	var camara = get_viewport().get_camera()
	for d in _detalles:
		if not is_instance_valid(d):
			continue
		var mostrar = true
		if calidad == BAJO and camara:
			mostrar = d.global_transform.origin.distance_to(camara.global_transform.origin) <= DISTANCIA_DETALLES
		if d.visible != mostrar:
			d.visible = mostrar
			d.set_process(mostrar)


func _buscar_detalles(nodo):
	for hijo in nodo.get_children():
		if hijo is Spatial and (hijo.name.begins_with("Riendas") or hijo.name.begins_with("Estribos") or hijo.name.begins_with("Brida")):
			_detalles.append(hijo)
		else:
			_buscar_detalles(hijo)


# ------------------------------------------------------------
# Guardar y cargar
# ------------------------------------------------------------
func _guardar():
	var archivo = ConfigFile.new()
	archivo.set_value("volumen", "general", _barra_general.value)
	archivo.set_value("volumen", "musica", _barra_musica.value)
	archivo.set_value("calidad", "nivel", calidad)
	archivo.save(RUTA_GUARDADO)


func _cargar():
	_cargando = true
	var archivo = ConfigFile.new()
	if archivo.load(RUTA_GUARDADO) == OK:
		_barra_general.value = archivo.get_value("volumen", "general", 100)
		_barra_musica.value = archivo.get_value("volumen", "musica", 100)
		calidad = int(archivo.get_value("calidad", "nivel", CALIDAD_INICIAL))
	_aplicar()
	_pintar_botones_calidad()
	_aplicar_resolucion()
	_cargando = false
	call_deferred("emit_signal", "calidad_cambiada", calidad)
