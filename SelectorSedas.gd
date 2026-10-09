extends CanvasLayer

# ============================================================
# SELECTOR DE SEDAS (UNIFORME DEL JUGADOR)
# ============================================================
# Pone el boton UNIFORME al lado de PAUSAR. Al tocarlo se abre un
# panel para elegir los colores y los dibujos de la chaquetilla del
# jinete del jugador (Enrutador_Caballo1).
# Lo elegido se guarda en user://sedas_bdg.cfg, asi no se pierde al
# cambiar de distancia ni al cerrar el juego.
# IMPORTANTE: este panel NUNCA toca la pausa. Abrirlo o cerrarlo no
# arranca la carrera.

# ---------- Boton UNIFORME (todo ajustable desde el Inspector) ----------
export var texto_boton_uniforme = "UNIFORME"
export var ancho_boton_uniforme = 105
export var alto_boton_uniforme = 30
# PAUSAR empieza a 220 del borde derecho; con 330 este boton queda
# justo a su izquierda.
export var distancia_borde_derecho = 330
export var distancia_borde_arriba = 8

# ---------- Panel ----------
export var ancho_panel_uniforme = 660
export var alto_panel_uniforme = 560
export var color_fondo_panel = Color("3a0a14")
export var color_dorado = Color("c4a159")
export var color_velo = Color(0, 0, 0, 0.5)
export var tamano_titulo_panel = 26
export var tamano_textos = 16
export var tamano_botones_dibujo = 14
export var ancho_boton_dibujo = 96
export var alto_boton_dibujo = 26
export var lado_muestra = 30
export var separacion_muestras = 6
export var lado_vista_previa = 170

# ---------- Colores que puede elegir el jugador (codigo hex) ----------
export var paleta = PoolStringArray([
	"6d1a2a", "d4af37", "ffffff", "c8102e", "e4002b", "ff6a13", "ff4f00",
	"ffd100", "ffa300", "009a44", "00a3e0", "0033a0", "5f259f", "9b26b6",
	"e10098", "00b5ad", "d50032", "1a1a1a", "0b1f4b", "3d0c11", "0a3d1f"])
# Uniforme de la primera vez (antes de que el jugador elija nada).
export var color_principal_inicial = Color("6d1a2a")
export var color_diseno_inicial = Color("d4af37")

# ---------- Jinete del jugador ----------
export var nombre_caballo_jugador = "Enrutador_Caballo1"

const RUTA_GUARDADO = "user://sedas_bdg.cfg"
# Mismo orden que en el jinete (Jockey_Tripo_250926.gd). No cambiar el orden.
const DIBUJOS_CHAQUETILLA = ["Liso", "Aros", "Franjas", "Banda cruzada", "Cuartos", "Mitades",
	"Rombos", "Lunares", "Estrellas", "Estrella grande", "Cheurones", "Cruz"]
const DIBUJOS_MANGAS = ["Lisas", "Aros", "Puños", "Hombros"]

# Copia del dibujo del jinete, pero en plano, para la vista previa.
const CODIGO_VISTA = """
shader_type canvas_item;
uniform vec4 color_1 : hint_color;
uniform vec4 color_2 : hint_color;
uniform int diseno = 0;
uniform float cantidad = 5.0;
uniform bool manga = false;

float estrella(vec2 p, float r) {
	float a = atan(p.x, p.y);
	float seg = 6.2831853 / 5.0;
	float an = abs(mod(a + seg * 0.5, seg) - seg * 0.5);
	return step(length(p), mix(r, r * 0.4, an / (seg * 0.5)));
}

void fragment() {
	float u = UV.x;
	float v = 1.0 - UV.y;
	float k = 0.0;
	if (manga) {
		if (diseno == 1) { k = step(0.5, fract(u * cantidad)); }
		else if (diseno == 2) { k = step(0.85, u); }
		else if (diseno == 3) { k = 1.0 - step(0.22, u); }
	} else {
		if (diseno == 1) { k = step(0.5, fract(v * cantidad * 0.75)); }
		else if (diseno == 2) { k = step(0.5, fract(u * cantidad * 0.6)); }
		else if (diseno == 3) { k = 1.0 - step(0.13, abs((u - 0.5) - (v - 0.7) * 0.8)); }
		else if (diseno == 4) { k = abs(step(0.5, u) - step(0.66, v)); }
		else if (diseno == 5) { k = step(0.5, u); }
		else if (diseno == 6) { float n = cantidad * 0.6; k = abs(step(0.5, fract((u + v) * n)) - step(0.5, fract((u - v) * n))); }
		else if (diseno == 7) { vec2 c = fract(vec2(u, v) * cantidad * 0.8) - 0.5; k = step(length(c), 0.22); }
		else if (diseno == 8) { vec2 c = fract(vec2(u, v) * cantidad * 0.6) - 0.5; k = estrella(c, 0.42); }
		else if (diseno == 9) { k = estrella(vec2(u - 0.5, v - 0.72), 0.3); }
		else if (diseno == 10) { k = step(0.5, fract(v * cantidad * 0.5 + abs(u - 0.5) * cantidad * 0.5)); }
		else if (diseno == 11) { k = max(1.0 - step(0.1, abs(u - 0.5)), 1.0 - step(0.09, abs(v - 0.75))); }
	}
	COLOR = vec4(mix(color_1.rgb, color_2.rgb, k), 1.0);
}
"""

var _color_principal = Color("6d1a2a")
var _color_diseno = Color("d4af37")
var _dibujo_chaquetilla = 0
var _dibujo_mangas = 0

var _boton_uniforme = null
var _velo = null
var _vista_chaquetilla = null
var _vista_mangas = null
var _vista_casco = null
var _muestras = {1: [], 2: []}
var _botones_chaquetilla = []
var _botones_mangas = []
var _sombreador = null
var _jinete = null
var _azar = RandomNumberGenerator.new()


func _ready():
	# Funciona aunque PantallaInicio tenga el juego en pausa.
	pause_mode = Node.PAUSE_MODE_PROCESS
	# Por encima de PAUSAR/REINICIAR (100), asi el panel los tapa.
	layer = 101
	_azar.randomize()
	_color_principal = color_principal_inicial
	_color_diseno = color_diseno_inicial
	_cargar()
	_sombreador = Shader.new()
	_sombreador.code = CODIGO_VISTA
	_crear_boton_uniforme()
	_crear_panel()
	_refrescar()
	call_deferred("_aplicar_al_jinete")


func _process(_delta):
	# Cuando arranca la carrera, el boton y el panel se esconden.
	if not get_tree().paused:
		_boton_uniforme.visible = false
		_velo.visible = false
		set_process(false)


# ------------------------------------------------------------
# Boton UNIFORME
# ------------------------------------------------------------
func _crear_boton_uniforme():
	var tam = get_viewport().get_visible_rect().size
	_boton_uniforme = Button.new()
	_boton_uniforme.text = texto_boton_uniforme
	_boton_uniforme.focus_mode = Control.FOCUS_NONE
	_boton_uniforme.rect_size = Vector2(ancho_boton_uniforme, alto_boton_uniforme)
	_boton_uniforme.rect_position = Vector2(tam.x - distancia_borde_derecho, distancia_borde_arriba)
	_boton_uniforme.connect("pressed", self, "_abrir")
	add_child(_boton_uniforme)


# ------------------------------------------------------------
# Panel
# ------------------------------------------------------------
func _crear_panel():
	_velo = ColorRect.new()
	_velo.color = color_velo
	_velo.anchor_right = 1
	_velo.anchor_bottom = 1
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_velo.visible = false
	add_child(_velo)

	var panel = Panel.new()
	panel.add_stylebox_override("panel", _estilo(color_fondo_panel, color_dorado, 2, 10))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.margin_left = -ancho_panel_uniforme / 2.0
	panel.margin_right = ancho_panel_uniforme / 2.0
	panel.margin_top = -alto_panel_uniforme / 2.0
	panel.margin_bottom = alto_panel_uniforme / 2.0
	_velo.add_child(panel)

	var margen = MarginContainer.new()
	margen.anchor_right = 1
	margen.anchor_bottom = 1
	margen.add_constant_override("margin_left", 22)
	margen.add_constant_override("margin_right", 22)
	margen.add_constant_override("margin_top", 12)
	margen.add_constant_override("margin_bottom", 14)
	panel.add_child(margen)

	var columna = VBoxContainer.new()
	columna.add_constant_override("separation", 10)
	margen.add_child(columna)

	var titulo = _texto(columna, "UNIFORME", tamano_titulo_panel)
	titulo.align = Label.ALIGN_CENTER

	var fila = HBoxContainer.new()
	fila.add_constant_override("separation", 26)
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(fila)

	# --- Izquierda: vista previa ---
	var izquierda = VBoxContainer.new()
	izquierda.add_constant_override("separation", 8)
	fila.add_child(izquierda)
	_vista_chaquetilla = _crear_vista(izquierda, Vector2(lado_vista_previa, lado_vista_previa), false)
	var texto_vista = _texto(izquierda, "VISTA PREVIA", tamano_botones_dibujo)
	texto_vista.align = Label.ALIGN_CENTER

	var fila_mangas = HBoxContainer.new()
	izquierda.add_child(fila_mangas)
	_texto(fila_mangas, "Mangas", tamano_botones_dibujo).rect_min_size.x = 64
	_vista_mangas = _crear_vista(fila_mangas, Vector2(lado_vista_previa - 70, 18), true)

	var fila_casco = HBoxContainer.new()
	izquierda.add_child(fila_casco)
	_texto(fila_casco, "Casco", tamano_botones_dibujo).rect_min_size.x = 64
	_vista_casco = Panel.new()
	_vista_casco.rect_min_size = Vector2(22, 22)
	_vista_casco.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila_casco.add_child(_vista_casco)

	# --- Derecha: colores y dibujos ---
	var derecha = VBoxContainer.new()
	derecha.add_constant_override("separation", 6)
	fila.add_child(derecha)

	_texto(derecha, "COLOR PRINCIPAL", tamano_textos)
	_crear_muestras(derecha, 1)
	_texto(derecha, "COLOR DEL DISEÑO", tamano_textos)
	_crear_muestras(derecha, 2)

	_texto(derecha, "CHAQUETILLA", tamano_textos)
	var rejilla = GridContainer.new()
	rejilla.columns = 4
	rejilla.add_constant_override("hseparation", 6)
	rejilla.add_constant_override("vseparation", 4)
	derecha.add_child(rejilla)
	for i in DIBUJOS_CHAQUETILLA.size():
		var b = _boton_dibujo(rejilla, DIBUJOS_CHAQUETILLA[i])
		b.connect("pressed", self, "_elegir_chaquetilla", [i])
		_botones_chaquetilla.append(b)

	_texto(derecha, "MANGAS", tamano_textos)
	var fila_botones_mangas = HBoxContainer.new()
	fila_botones_mangas.add_constant_override("separation", 6)
	derecha.add_child(fila_botones_mangas)
	for i in DIBUJOS_MANGAS.size():
		var b = _boton_dibujo(fila_botones_mangas, DIBUJOS_MANGAS[i])
		b.connect("pressed", self, "_elegir_mangas", [i])
		_botones_mangas.append(b)

	# --- Abajo: AL AZAR y LISTO ---
	var abajo = HBoxContainer.new()
	abajo.alignment = BoxContainer.ALIGN_END
	abajo.add_constant_override("separation", 12)
	columna.add_child(abajo)

	var boton_azar = _boton_final(abajo, "AL AZAR", false)
	boton_azar.connect("pressed", self, "_al_azar")
	var boton_listo = _boton_final(abajo, "LISTO", true)
	boton_listo.connect("pressed", self, "_cerrar")


func _crear_vista(padre, tam, es_manga):
	var marco = PanelContainer.new()
	var borde = StyleBoxFlat.new()
	borde.draw_center = false
	borde.border_color = color_dorado
	borde.set_border_width_all(2)
	borde.content_margin_left = 2
	borde.content_margin_right = 2
	borde.content_margin_top = 2
	borde.content_margin_bottom = 2
	marco.add_stylebox_override("panel", borde)
	marco.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	marco.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	padre.add_child(marco)

	var vista = ColorRect.new()
	vista.rect_min_size = tam
	vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material_vista = ShaderMaterial.new()
	material_vista.shader = _sombreador
	material_vista.set_shader_param("manga", es_manga)
	vista.material = material_vista
	marco.add_child(vista)
	return vista


func _crear_muestras(padre, cual):
	var rejilla = GridContainer.new()
	rejilla.columns = 11
	rejilla.add_constant_override("hseparation", separacion_muestras)
	rejilla.add_constant_override("vseparation", separacion_muestras)
	padre.add_child(rejilla)
	for codigo in paleta:
		var b = Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.rect_min_size = Vector2(lado_muestra, lado_muestra)
		b.connect("pressed", self, "_elegir_color", [cual, codigo])
		rejilla.add_child(b)
		_muestras[cual].append([b, Color(codigo)])


func _boton_dibujo(padre, texto):
	var b = Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.rect_min_size = Vector2(ancho_boton_dibujo, alto_boton_dibujo)
	padre.add_child(b)
	_letra(b, tamano_botones_dibujo)
	return b


func _boton_final(padre, texto, relleno):
	var b = Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.rect_min_size = Vector2(110, 34)
	padre.add_child(b)
	_letra(b, tamano_textos + 1)
	if relleno:
		_pintar_boton(b, color_dorado, color_fondo_panel, 6)
	else:
		_pintar_boton(b, color_fondo_panel, color_dorado, 6)
	return b


func _texto(padre, texto, tamano):
	var l = Label.new()
	l.text = texto
	l.add_color_override("font_color", color_dorado)
	padre.add_child(l)
	_letra(l, tamano)
	return l


# ------------------------------------------------------------
# Abrir, cerrar y elegir (nada de esto toca la pausa)
# ------------------------------------------------------------
func _abrir():
	_refrescar()
	_velo.visible = true


func _cerrar():
	_velo.visible = false


func _elegir_color(cual, codigo):
	if cual == 1:
		_color_principal = Color(codigo)
	else:
		_color_diseno = Color(codigo)
	_hubo_cambio()


func _elegir_chaquetilla(i):
	_dibujo_chaquetilla = i
	_hubo_cambio()


func _elegir_mangas(i):
	_dibujo_mangas = i
	_hubo_cambio()


func _al_azar():
	var n = paleta.size()
	if n >= 2:
		var a = _azar.randi() % n
		var b = _azar.randi() % (n - 1)
		if b >= a:
			b += 1
		_color_principal = Color(paleta[a])
		_color_diseno = Color(paleta[b])
	_dibujo_chaquetilla = _azar.randi() % DIBUJOS_CHAQUETILLA.size()
	_dibujo_mangas = _azar.randi() % DIBUJOS_MANGAS.size()
	_hubo_cambio()


func _hubo_cambio():
	_refrescar()
	_guardar()
	_aplicar_al_jinete()


# ------------------------------------------------------------
# Pintar el panel segun lo elegido
# ------------------------------------------------------------
func _refrescar():
	for cual in [1, 2]:
		var elegido = _color_principal if cual == 1 else _color_diseno
		for par in _muestras[cual]:
			var marcado = par[1].to_html(false) == elegido.to_html(false)
			var borde = Color("ffffff") if marcado else Color("000000")
			var e = _estilo(par[1], borde, 3 if marcado else 1, 0)
			for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
				par[0].add_stylebox_override(estado, e)
	for i in _botones_chaquetilla.size():
		_marcar(_botones_chaquetilla[i], i == _dibujo_chaquetilla)
	for i in _botones_mangas.size():
		_marcar(_botones_mangas[i], i == _dibujo_mangas)
	var cantidad = _cantidad_del_jinete()
	_poner_vista(_vista_chaquetilla, _color_principal, _color_diseno, _dibujo_chaquetilla, cantidad)
	# Igual que el jinete: mangas del color del diseno, dibujo del principal.
	_poner_vista(_vista_mangas, _color_diseno, _color_principal, _dibujo_mangas, cantidad)
	_vista_casco.add_stylebox_override("panel", _estilo(_color_diseno, color_dorado, 1, 11))


func _poner_vista(vista, c1, c2, dibujo, cantidad):
	vista.material.set_shader_param("color_1", c1)
	vista.material.set_shader_param("color_2", c2)
	vista.material.set_shader_param("diseno", dibujo)
	vista.material.set_shader_param("cantidad", cantidad)


func _marcar(b, marcado):
	if marcado:
		_pintar_boton(b, color_dorado, color_fondo_panel, 6)
	else:
		_pintar_boton(b, color_fondo_panel, color_dorado, 6)


# ------------------------------------------------------------
# Ponerle el uniforme al jinete del jugador
# ------------------------------------------------------------
func _aplicar_al_jinete():
	var j = _buscar_jinete()
	if j == null:
		return
	j.color_1 = _color_principal
	j.color_2 = _color_diseno
	j.diseno_cuerpo = _dibujo_chaquetilla
	j.diseno_mangas = _dibujo_mangas
	j.mangas_color_2 = true
	j.color_casco = _color_diseno
	# Si el jinete ya esta vestido, se repinta ya mismo. Si todavia no,
	# se vestira con estos colores cuando arranque la carrera.
	if j.has_method("_pintar"):
		j._pintar()


func _buscar_jinete():
	if _jinete != null and is_instance_valid(_jinete):
		return _jinete
	var escena = get_tree().current_scene
	if escena == null:
		return null
	var caballo = escena.find_node(nombre_caballo_jugador, true, false)
	if caballo == null:
		return null
	_jinete = _buscar_con_sedas(caballo)
	return _jinete


func _buscar_con_sedas(nodo):
	for c in nodo.get_children():
		if "diseno_cuerpo" in c:
			return c
		var r = _buscar_con_sedas(c)
		if r != null:
			return r
	return null


func _cantidad_del_jinete():
	var j = _buscar_jinete()
	if j != null and "cantidad_diseno" in j:
		return float(j.cantidad_diseno)
	return 5.0


# ------------------------------------------------------------
# Guardar y cargar lo elegido
# ------------------------------------------------------------
func _guardar():
	var cfg = ConfigFile.new()
	cfg.set_value("jugador", "color_principal", _color_principal.to_html(false))
	cfg.set_value("jugador", "color_diseno", _color_diseno.to_html(false))
	cfg.set_value("jugador", "chaquetilla", _dibujo_chaquetilla)
	cfg.set_value("jugador", "mangas", _dibujo_mangas)
	cfg.save(RUTA_GUARDADO)


func _cargar():
	var cfg = ConfigFile.new()
	if cfg.load(RUTA_GUARDADO) != OK:
		return
	_color_principal = Color(cfg.get_value("jugador", "color_principal", _color_principal.to_html(false)))
	_color_diseno = Color(cfg.get_value("jugador", "color_diseno", _color_diseno.to_html(false)))
	_dibujo_chaquetilla = int(clamp(cfg.get_value("jugador", "chaquetilla", 0), 0, DIBUJOS_CHAQUETILLA.size() - 1))
	_dibujo_mangas = int(clamp(cfg.get_value("jugador", "mangas", 0), 0, DIBUJOS_MANGAS.size() - 1))


# ------------------------------------------------------------
# Ayudas de estilo
# ------------------------------------------------------------
func _estilo(fondo, borde, grosor, redondeo):
	var e = StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(grosor)
	e.set_corner_radius_all(redondeo)
	return e


func _pintar_boton(b, fondo, letra, redondeo):
	var e = _estilo(fondo, color_dorado, 1, redondeo)
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_stylebox_override(estado, e)
	for clave in ["font_color", "font_color_hover", "font_color_pressed"]:
		b.add_color_override(clave, letra)


# Agranda la letra sin tocar la fuente de todo el juego (igual que
# en SelectorDistancias).
func _letra(control, tamano):
	var base = control.get_font("font")
	if base == null or not (base is DynamicFont):
		return
	var copia = base.duplicate()
	copia.size = tamano
	control.add_font_override("font", copia)
