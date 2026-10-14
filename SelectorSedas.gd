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
# PROBADOR 3D: a la izquierda se ve tu propio caballo con tu jinete,
# girando, con la chaquetilla puesta. Cada color o dibujo que tocas se ve
# al instante. El probador existe solo mientras el panel esta abierto (al
# cerrarlo se borra), asi no pesa durante la carrera.

# ---------- Boton UNIFORME (todo ajustable desde el Inspector) ----------
export var texto_boton_uniforme = "UNIFORME"
export var ancho_boton_uniforme = 105
export var alto_boton_uniforme = 30
# PAUSAR empieza a 220 del borde derecho; con 330 este boton queda
# justo a su izquierda.
export var distancia_borde_derecho = 330
export var distancia_borde_arriba = 8

# ---------- Panel ----------
export var ancho_panel_uniforme = 800
export var alto_panel_uniforme = 560
export var color_fondo_panel = Color("3a0a14")
export var color_dorado = Color("c4a159")
export var color_velo = Color(0, 0, 0, 0.5)
export var tamano_titulo_panel = 26
export var tamano_textos = 16
export var tamano_botones_dibujo = 14
export var ancho_boton_dibujo = 96
export var alto_boton_dibujo = 26
export var lado_muestra = 26
export var separacion_muestras = 5
export var lado_vista_previa = 120

# ---------- Probador 3D (tu caballo y tu jinete girando) ----------
export var probador_3d = false
export var ancho_probador = 290
export var alto_probador = 260
export var giro_por_segundo = 20.0         # grados por segundo; 0 = quieto
export var distancia_camara = 1.7          # mas = camara mas lejos
export var altura_camara = 0.6             # mas = camara mas arriba
export var bajar_mira = 0.2                # mas = mira mas hacia el caballo (menos al jinete)
export var luz_probador = 0.55
export var color_fondo_probador = Color("1e0910")
export var color_piso_probador = Color("2c4a22")

# ---------- Colores que puede elegir el jugador (codigo hex) ----------
export var paleta = PoolStringArray([
	"6d1a2a", "d4af37", "ffffff", "c8102e", "e4002b", "ff6a13", "ff4f00",
	"ffd100", "ffa300", "009a44", "00a3e0", "0033a0", "5f259f", "9b26b6",
	"e10098", "00b5ad", "d50032", "1a1a1a", "0b1f4b", "3d0c11", "0a3d1f"])
# Uniforme de la primera vez (antes de que el jugador elija nada).
export var color_principal_inicial = Color("6d1a2a")
export var color_diseno_inicial = Color("d4af37")
export(int, "Liso", "Aros", "Franjas", "Banda cruzada", "Cuartos", "Mitades", "Rombos", "Lunares", "Estrellas", "Estrella grande", "Cheurones", "Cruz") var dibujo_chaquetilla_inicial = 9
export(int, "Lisas", "Aros", "Puños", "Hombros") var dibujo_mangas_inicial = 0
# Encendido: las mangas van del color principal (todo vino tinto).
export var mangas_del_color_principal = true
# Gorra del jinete del jugador la primera vez (despues la elige el jugador)
export var color_gorra_inicial = Color("6d1a2a")

# ---------- Raza del caballo del jugador ----------
# Al cambiar la raza y darle LISTO, la pista se vuelve a cargar con el caballo nuevo.
export var ofrecer_cuartomilla = false
export var ofrecer_ingles = false
export var nombre_repartidor = "RepartidorCaballos"

# ---------- Pelaje del caballo del jugador ----------
# Los pelajes salen de la lista del nodo Pelajes (mismo orden).
export var nombre_pelajes = "Pelajes"
export var columnas_pelaje = 6

# ---------- Jinete del jugador ----------
export var nombre_caballo_jugador = "Enrutador_Caballo1"

const RUTA_GUARDADO = "user://sedas_bdg_v2.cfg"
# Mismo orden que en el jinete (Jockey_Tripo_250926.gd). No cambiar el orden.
const DIBUJOS_CHAQUETILLA = ["Liso", "Aros", "Franjas", "Banda cruzada", "Cuartos", "Mitades",
	"Rombos", "Lunares", "Estrellas", "Estrella grande", "Cheurones", "Cruz"]
const DIBUJOS_MANGAS = ["Lisas", "Aros", "Puños", "Hombros"]
const RAZAS = [["americano", "Americano"], ["arabe", "Árabe"], ["cuartomilla", "Cuarto de Milla"], ["ingles", "Inglés"]]

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
var _color_gorra = Color("6d1a2a")
var _raza = "americano"
var _raza_en_pista = "americano"
var _botones_raza = []
var _pelaje = -1
var _muestras_pelaje = []
var _texto_pelaje = null
var _razas_ofrecidas = []
var _dibujo_chaquetilla = 0
var _dibujo_mangas = 0

var _boton_uniforme = null
var _velo = null
var _vista_chaquetilla = null
var _vista_mangas = null
var _vista_casco = null
var _muestras = {1: [], 2: [], 3: []}
var _botones_chaquetilla = []
var _botones_mangas = []
var _sombreador = null
var _jinete = null
var _azar = RandomNumberGenerator.new()
var _contenedor_probador = null
var _visor = null
var _probador = null
var _probador_jinete = null
var _camara_probador = null
var _centro_probador = Vector3.ZERO
var _radio_probador = 10.0
var _angulo_probador = 0.0
var _arrastrando = false
var _turno_probador = 0


func _ready():
	# Funciona aunque PantallaInicio tenga el juego en pausa.
	pause_mode = Node.PAUSE_MODE_PROCESS
	# Por encima de PAUSAR/REINICIAR (100), asi el panel los tapa.
	layer = 101
	_azar.randomize()
	_color_principal = color_principal_inicial
	_color_diseno = color_diseno_inicial
	_dibujo_chaquetilla = dibujo_chaquetilla_inicial
	_color_gorra = color_gorra_inicial
	_dibujo_mangas = dibujo_mangas_inicial
	_cargar()
	_raza_en_pista = _raza
	_preparar_pelaje()
	_sombreador = Shader.new()
	_sombreador.code = CODIGO_VISTA
	_crear_boton_uniforme()
	_crear_panel()
	_refrescar()
	call_deferred("_aplicar_al_jinete")
	# Otra vez cuando el repartidor ya puso el caballo de la raza escogida
	get_tree().create_timer(0.6).connect("timeout", self, "_aplicar_al_jinete")


func _process(delta):
	# Cuando arranca la carrera, el boton y el panel se esconden.
	if not get_tree().paused:
		_boton_uniforme.visible = false
		_velo.visible = false
		_borrar_probador()
		set_process(false)
		return
	_girar_probador(delta)


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
	if probador_3d:
		_crear_contenedor_probador(izquierda)
		var texto_probador = _texto(izquierda, "ARRASTRA PARA GIRAR", tamano_botones_dibujo)
		texto_probador.align = Label.ALIGN_CENTER
	else:
		_vista_chaquetilla = _crear_vista(izquierda, Vector2(lado_vista_previa, lado_vista_previa), false)
		var texto_vista = _texto(izquierda, "VISTA PREVIA", tamano_botones_dibujo)
		texto_vista.align = Label.ALIGN_CENTER

		var fila_mangas = HBoxContainer.new()
		izquierda.add_child(fila_mangas)
		_texto(fila_mangas, "Mangas", tamano_botones_dibujo).rect_min_size.x = 64
		_vista_mangas = _crear_vista(fila_mangas, Vector2(lado_vista_previa - 70, 18), true)
	_texto(izquierda, "GORRA", tamano_textos)
	_crear_muestras(izquierda, 3, 7)
	_texto_pelaje = _texto(izquierda, "PELAJE", tamano_textos)
	var rejilla_pelaje = GridContainer.new()
	rejilla_pelaje.columns = columnas_pelaje
	rejilla_pelaje.add_constant_override("hseparation", separacion_muestras)
	rejilla_pelaje.add_constant_override("vseparation", separacion_muestras)
	izquierda.add_child(rejilla_pelaje)
	var colores_pelaje = _lista_pelajes("COLORES")
	for i in colores_pelaje.size():
		var b = Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.rect_min_size = Vector2(lado_muestra, lado_muestra)
		b.hint_tooltip = _lista_pelajes("NOMBRES")[i] if i < _lista_pelajes("NOMBRES").size() else ""
		b.connect("pressed", self, "_elegir_pelaje", [i])
		rejilla_pelaje.add_child(b)
		_muestras_pelaje.append([b, Color(colores_pelaje[i])])

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

	_texto(derecha, "RAZA DEL CABALLO", tamano_textos)
	var fila_razas = HBoxContainer.new()
	fila_razas.add_constant_override("separation", 6)
	derecha.add_child(fila_razas)
	for r in RAZAS:
		if r[0] == "cuartomilla" and not ofrecer_cuartomilla:
			continue
		if r[0] == "ingles" and not ofrecer_ingles:
			continue
		var b = _boton_dibujo(fila_razas, r[1])
		b.connect("pressed", self, "_elegir_raza", [r[0]])
		_botones_raza.append(b)
		_razas_ofrecidas.append(r[0])

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


func _crear_muestras(padre, cual, columnas = 11):
	var rejilla = GridContainer.new()
	rejilla.columns = columnas
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
	if probador_3d:
		_crear_probador()


func _cerrar():
	_velo.visible = false
	_borrar_probador()
	# Si cambio la raza, la pista se vuelve a cargar con el caballo nuevo.
	if _raza != _raza_en_pista:
		get_tree().reload_current_scene()


func _elegir_color(cual, codigo):
	if cual == 1:
		_color_principal = Color(codigo)
	elif cual == 2:
		_color_diseno = Color(codigo)
	else:
		_color_gorra = Color(codigo)
	_hubo_cambio()


func _elegir_chaquetilla(i):
	_dibujo_chaquetilla = i
	_hubo_cambio()


func _elegir_mangas(i):
	_dibujo_mangas = i
	_hubo_cambio()


func _elegir_raza(raza):
	if raza == _raza:
		return
	_raza = raza
	_refrescar()
	_guardar()
	if probador_3d and _velo.visible:
		_crear_probador()


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
	_color_gorra = _color_principal if _azar.randf() < 0.5 else _color_diseno
	_hubo_cambio()


func _hubo_cambio():
	_refrescar()
	_guardar()
	_aplicar_al_jinete()
	_vestir_probador()


# ------------------------------------------------------------
# Pintar el panel segun lo elegido
# ------------------------------------------------------------
func _refrescar():
	for cual in [1, 2, 3]:
		var elegido = _color_principal
		if cual == 2:
			elegido = _color_diseno
		elif cual == 3:
			elegido = _color_gorra
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
	for i in _botones_raza.size():
		_marcar(_botones_raza[i], _razas_ofrecidas[i] == _raza)
	for i in _muestras_pelaje.size():
		var marcado_p = (i == _pelaje)
		var borde_p = Color("ffffff") if marcado_p else Color("000000")
		var e_p = _estilo(_muestras_pelaje[i][1], borde_p, 3 if marcado_p else 1, 0)
		for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
			_muestras_pelaje[i][0].add_stylebox_override(estado, e_p)
	if _texto_pelaje != null:
		var nombres_p = _lista_pelajes("NOMBRES")
		if _pelaje >= 0 and _pelaje < nombres_p.size():
			_texto_pelaje.text = "PELAJE: " + str(nombres_p[_pelaje]).to_upper()
	var cantidad = _cantidad_del_jinete()
	if _vista_chaquetilla != null:
		_poner_vista(_vista_chaquetilla, _color_principal, _color_diseno, _dibujo_chaquetilla, cantidad)
	if _vista_mangas != null:
		if mangas_del_color_principal:
			_poner_vista(_vista_mangas, _color_principal, _color_diseno, _dibujo_mangas, cantidad)
		else:
			_poner_vista(_vista_mangas, _color_diseno, _color_principal, _dibujo_mangas, cantidad)


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
	j.mangas_color_2 = not mangas_del_color_principal
	j.color_casco = _color_gorra
	# Si el jinete ya esta vestido, se repinta ya mismo. Si todavia no,
	# se vestira con estos colores cuando arranque la carrera.
	if j.has_method("_pintar"):
		j._pintar()


func _buscar_jinete():
	var real = _caballo_real()
	if real != null:
		return _buscar_con_sedas(real)
	return null


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
	cfg.set_value("jugador", "gorra", _color_gorra.to_html(false))
	cfg.set_value("jugador", "raza", _raza)
	cfg.set_value("jugador", "pelaje", _pelaje)
	cfg.save(RUTA_GUARDADO)


func _cargar():
	var cfg = ConfigFile.new()
	if cfg.load(RUTA_GUARDADO) != OK:
		return
	_color_principal = Color(cfg.get_value("jugador", "color_principal", _color_principal.to_html(false)))
	_color_diseno = Color(cfg.get_value("jugador", "color_diseno", _color_diseno.to_html(false)))
	_dibujo_chaquetilla = int(clamp(cfg.get_value("jugador", "chaquetilla", _dibujo_chaquetilla), 0, DIBUJOS_CHAQUETILLA.size() - 1))
	_dibujo_mangas = int(clamp(cfg.get_value("jugador", "mangas", _dibujo_mangas), 0, DIBUJOS_MANGAS.size() - 1))
	_color_gorra = Color(cfg.get_value("jugador", "gorra", _color_gorra.to_html(false)))
	_raza = str(cfg.get_value("jugador", "raza", "americano"))
	_pelaje = int(cfg.get_value("jugador", "pelaje", -1))


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


# ------------------------------------------------------------
# Probador 3D: tu caballo con tu jinete, girando dentro del panel
# ------------------------------------------------------------
func _crear_contenedor_probador(padre):
	var marco = PanelContainer.new()
	var borde = StyleBoxFlat.new()
	borde.bg_color = color_fondo_probador
	borde.border_color = color_dorado
	borde.set_border_width_all(2)
	borde.content_margin_left = 2
	borde.content_margin_right = 2
	borde.content_margin_top = 2
	borde.content_margin_bottom = 2
	marco.add_stylebox_override("panel", borde)
	marco.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	padre.add_child(marco)
	_contenedor_probador = ViewportContainer.new()
	_contenedor_probador.stretch = true
	_contenedor_probador.rect_min_size = Vector2(ancho_probador, alto_probador)
	_contenedor_probador.mouse_filter = Control.MOUSE_FILTER_STOP
	_contenedor_probador.connect("gui_input", self, "_tocar_probador")
	marco.add_child(_contenedor_probador)


func _crear_probador():
	_borrar_probador()
	if _contenedor_probador == null:
		return
	var real = _caballo_real()
	var escena_raza = _escena_de_raza(_raza)
	if escena_raza == null and real != null and real.filename != "":
		escena_raza = load(real.filename)
	if escena_raza == null:
		return
	_visor = Viewport.new()
	_visor.size = Vector2(ancho_probador, alto_probador)
	_visor.own_world = true
	_visor.msaa = Viewport.MSAA_DISABLED
	_visor.shadow_atlas_size = 0
	_visor.render_target_update_mode = Viewport.UPDATE_ALWAYS
	_contenedor_probador.add_child(_visor)

	var mundo = Spatial.new()
	_visor.add_child(mundo)
	var ambiente = Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = color_fondo_probador
	ambiente.ambient_light_color = Color("e6dccb")
	ambiente.ambient_light_energy = 0.3
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we = WorldEnvironment.new()
	we.environment = ambiente
	mundo.add_child(we)
	var luz = DirectionalLight.new()
	luz.rotation_degrees = Vector3(-45, 35, 0)
	luz.light_energy = luz_probador
	mundo.add_child(luz)
	var luz2 = DirectionalLight.new()
	luz2.rotation_degrees = Vector3(-30, -145, 0)
	luz2.light_energy = luz_probador * 0.35
	mundo.add_child(luz2)

	_probador = escena_raza.instance()
	mundo.add_child(_probador)
	_probador_jinete = _buscar_con_sedas(_probador)
	if _probador_jinete != null:
		_probador_jinete.colores_al_azar = false
		_probador_jinete.latigo_automatico = false
		if "tamano_al_azar" in _probador_jinete:
			_probador_jinete.tamano_al_azar = false
	# El pelaje se copia solo si es la misma raza que esta en la pista.
	if real != null and real.filename == escena_raza.resource_path:
		_copiar_pelaje(real, _probador)

	_camara_probador = Camera.new()
	_camara_probador.fov = 35
	_camara_probador.far = 500
	mundo.add_child(_camara_probador)
	_camara_probador.current = true
	# Se encuadra cuando el jinete ya esta armado (unos cuadros despues).
	_turno_probador += 1
	call_deferred("_encuadrar_probador", mundo, 0, _turno_probador)


func _encuadrar_probador(mundo, intentos, turno):
	# Si mientras tanto se cambio de raza o se cerro el panel, este
	# probador ya no existe: no se hace nada.
	if turno != _turno_probador or not is_instance_valid(mundo):
		return
	if _probador == null or not is_instance_valid(_probador):
		return
	if intentos < 6:
		yield(get_tree(), "idle_frame")
		_encuadrar_probador(mundo, intentos + 1, turno)
		return
	var ab = _medir(_probador_jinete if _probador_jinete != null else _probador, null)
	if ab == null:
		return
	var pie = _pie_del_caballo(_probador)
	_centro_probador = ab.position + ab.size * 0.5 - Vector3(0, ab.size.y * bajar_mira, 0)
	_radio_probador = ab.size.length()
	var piso = MeshInstance.new()
	var cil = CylinderMesh.new()
	cil.top_radius = ab.size.length() * 0.75
	cil.bottom_radius = cil.top_radius
	cil.height = 0.2
	cil.radial_segments = 32
	piso.mesh = cil
	var mp = SpatialMaterial.new()
	mp.albedo_color = color_piso_probador
	piso.material_override = mp
	piso.translation = pie - Vector3(0, 0.6, 0)
	mundo.add_child(piso)
	_vestir_probador()
	_angulo_probador = 200.0
	_girar_probador(0.0)


func _girar_probador(delta):
	if _camara_probador == null or not is_instance_valid(_camara_probador):
		return
	if not _arrastrando:
		_angulo_probador += giro_por_segundo * delta
	var a = deg2rad(_angulo_probador)
	var d = _radio_probador * distancia_camara
	var desde = _centro_probador + Vector3(cos(a) * d, _radio_probador * altura_camara, sin(a) * d)
	_camara_probador.global_transform = Transform(Basis(), desde)
	_camara_probador.look_at(_centro_probador, Vector3.UP)


func _tocar_probador(evento):
	if evento is InputEventMouseButton:
		_arrastrando = evento.pressed
	elif evento is InputEventScreenTouch:
		_arrastrando = evento.pressed
	elif evento is InputEventMouseMotion and _arrastrando:
		_angulo_probador += evento.relative.x * 0.6
	elif evento is InputEventScreenDrag:
		_angulo_probador += evento.relative.x * 0.6


func _vestir_probador():
	var j = _probador_jinete
	if j == null or not is_instance_valid(j):
		return
	j.color_1 = _color_principal
	j.color_2 = _color_diseno
	j.diseno_cuerpo = _dibujo_chaquetilla
	j.diseno_mangas = _dibujo_mangas
	j.mangas_color_2 = not mangas_del_color_principal
	j.color_casco = _color_gorra
	var real = _buscar_jinete()
	if real != null:
		for p in ["cantidad_diseno", "color_pantalon", "color_guantes", "color_botas", "tono_piel"]:
			if p in real:
				j.set(p, real.get(p))
	if j.has_method("_pintar"):
		j._pintar()


func _borrar_probador():
	_turno_probador += 1
	if _visor != null and is_instance_valid(_visor):
		_visor.queue_free()
	_visor = null
	_probador = null
	_probador_jinete = null
	_camara_probador = null


# El caballo del jugador tal como esta en la pista (para copiar su pelaje).
func _caballo_real():
	var escena = get_tree().current_scene
	if escena == null:
		return null
	var enr = escena.find_node(nombre_caballo_jugador, true, false)
	if enr == null:
		return null
	var primero = null
	for c in enr.get_children():
		if c is Spatial and c.filename != "" and _buscar_con_sedas(c) != null:
			if c.visible:
				return c
			if primero == null:
				primero = c
	return primero


# Copia el pelaje, la brida y las riendas del caballo de la pista al del
# probador (el jinete no: ese lo viste el probador).
func _copiar_pelaje(real, copia):
	for mi in _mallas_sin_jinete(real):
		var otra = copia.get_node_or_null(real.get_path_to(mi))
		if otra == null or not (otra is MeshInstance) or mi.mesh == null:
			continue
		otra.material_override = mi.material_override
		for i in mi.mesh.get_surface_count():
			if i < otra.get_surface_material_count():
				otra.set_surface_material(i, mi.get_surface_material(i))
	for n in _con_rienda(real):
		var otra = copia.get_node_or_null(real.get_path_to(n))
		if otra != null and "color_rienda" in otra:
			otra.color_rienda = n.color_rienda


func _mallas_sin_jinete(n):
	var r = []
	if "diseno_cuerpo" in n:
		return r
	if n is MeshInstance:
		r.append(n)
	for c in n.get_children():
		r += _mallas_sin_jinete(c)
	return r


func _con_rienda(n):
	var r = []
	if "color_rienda" in n:
		r.append(n)
	for c in n.get_children():
		r += _con_rienda(c)
	return r


func _medir(n, ab):
	if n is MeshInstance and n.visible and n.mesh != null:
		var a = n.get_transformed_aabb()
		ab = a if ab == null else ab.merge(a)
	for c in n.get_children():
		ab = _medir(c, ab)
	return ab


func _escena_de_raza(raza):
	var escena = get_tree().current_scene
	if escena == null:
		return null
	var rep = escena.find_node(nombre_repartidor, true, false)
	if rep != null and rep.has_method("escena_de_raza"):
		return rep.escena_de_raza(raza)
	return null


# Centro del caballo a la altura de los cascos (segun los huesos de su esqueleto)
func _pie_del_caballo(n):
	var cola = [n]
	while cola.size() > 0:
		var x = cola.pop_front()
		if x is Skeleton and x.get_bone_count() > 0:
			var suma = Vector3()
			var bajo = 1e20
			for i in x.get_bone_count():
				var p = x.global_transform.xform(x.get_bone_global_pose(i).origin)
				suma += p
				bajo = min(bajo, p.y)
			var c = suma / x.get_bone_count()
			return Vector3(c.x, bajo, c.z)
		for h in x.get_children():
			cola.append(h)
	return n.global_transform.origin


# ------------------------------------------------------------
# Pelaje del caballo del jugador (lo pinta el nodo Pelajes)
# ------------------------------------------------------------
func _nodo_pelajes():
	var escena = get_tree().current_scene
	if escena == null:
		return null
	return escena.find_node(nombre_pelajes, true, false)


# Lista de nombres o de colores de los pelajes, tal cual estan en Pelajes.gd
func _lista_pelajes(cual):
	var p = _nodo_pelajes()
	if p != null and p.get_script() != null:
		var m = p.get_script().get_script_constant_map()
		if m.has(cual):
			return m[cual]
	return []


# Al arrancar: si el jugador ya escogio un pelaje, se le pasa a Pelajes
# antes de que pinte los caballos. Si no, se usa el que tiene Pelajes.
func _preparar_pelaje():
	var p = _nodo_pelajes()
	if p == null or not ("pelaje_jugador" in p):
		return
	var total = _lista_pelajes("COLORES").size()
	if _pelaje >= 0 and _pelaje < total:
		p.pelaje_jugador = _pelaje
	else:
		_pelaje = p.pelaje_jugador


func _elegir_pelaje(i):
	_pelaje = i
	var p = _nodo_pelajes()
	if p != null and ("pelaje_jugador" in p):
		p.pelaje_jugador = i
		# Si los caballos ya estan pintados, se repinta el tuyo al instante.
		var colores_p = _lista_pelajes("COLORES")
		if p.get("_shader") != null and p.has_method("_pintar") and i < colores_p.size():
			var escena = get_tree().current_scene
			var enr = escena.find_node(nombre_caballo_jugador, true, false) if escena else null
			if enr != null:
				p._pintar(enr, Color(colores_p[i]))
	_refrescar()
	_guardar()
