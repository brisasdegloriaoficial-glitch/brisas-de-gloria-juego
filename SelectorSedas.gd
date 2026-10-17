extends CanvasLayer

# ============================================================
# SELECTOR DE SEDAS (UNIFORME DEL JUGADOR)
# ============================================================
# Pone el boton UNIFORME al lado de PAUSAR. Al tocarlo se abre un
# panel para elegir los colores y los dibujos de la chaquetilla del
# jinete del jugador (Enrutador_Caballo1).
# NUEVO: el panel muestra arriba el JINETE completo (gorra, chaquetilla y
# mangas) con todas sus opciones al lado, y abajo el CABALLO con su raza y
# su pelaje al lado. Todo con figuras dibujadas por el juego (no pesan).
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
export var ancho_boton_uniforme = 150
export var alto_boton_uniforme = 40
# PAUSAR empieza a 220 del borde derecho; con 380 este boton queda
# justo a su izquierda (si lo agrandas, sube tambien este numero).
export var distancia_borde_derecho = 380
export var distancia_borde_arriba = 6
# NUEVO - Boton bien llamativo: colores, figurita del uniforme y latido.
export var color_boton_uniforme = Color("ffd100")
export var color_letra_boton_uniforme = Color("6d1a2a")
# VALOR ASENTADO (16-oct): borde vino tinto, como la letra.
export var color_borde_boton_uniforme = Color("6d1a2a")
export var grosor_borde_boton_uniforme = 3
export var tamano_letra_boton_uniforme = 18
export var figura_en_boton_uniforme = true
# NUEVO 16-oct - La figurita del boton va en azul y negro, para que resalte
# sobre el amarillo. Desmarcar = lleva los colores de tu uniforme.
export var figura_boton_azul_negro = true
export var color_figura_boton_uniforme = Color("222988")    # chaquetilla y mangas
export var color_contorno_figura_boton = Color("1c1c1c")   # gorra y bordes
export var latido_boton_uniforme = true    # crece y se achica un poquito para llamar la atencion
export var fuerza_latido = 0.07            # cuanto crece (0.07 = 7 %)
export var velocidad_latido = 1.2          # latidos por segundo

# ---------- Panel ----------
export var ancho_panel_uniforme = 800
export var alto_panel_uniforme = 560
export var color_fondo_panel = Color("3a0a14")
export var color_dorado = Color("c4a159")
export var color_velo = Color(0, 0, 0, 0.5)
export var tamano_titulo_panel = 26
export var tamano_textos = 16
export var lado_muestra = 30
export var separacion_muestras = 5
# ---------- Figuras del panel (NUEVO) ----------
export var lado_figura_grande = 140        # figura grande del jinete y del caballo
export var ancho_icono = 70                # botones con figura: dibujos, mangas y razas
export var alto_icono = 64
export var ancho_icono_pelaje = 46         # botones de pelaje
export var alto_icono_pelaje = 60
export var alto_pestana = 38               # pestanas DIBUJO, COLORES, MANGAS, GORRA
export var tamano_letra_titulos = 13
export var tamano_letra_iconos = 12
export var tamano_letra_pelaje = 10
export var grosor_linea = 1.5              # borde dorado de las figuras

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
export var ofrecer_cuartomilla = true
export var ofrecer_ingles = true
export var nombre_repartidor = "RepartidorCaballos"

# ---------- Pelaje del caballo del jugador ----------
# Los pelajes salen de la lista del nodo Pelajes (mismo orden).
export var nombre_pelajes = "Pelajes"
export var columnas_pelaje = 11

# ---------- Jinete del jugador ----------
export var nombre_caballo_jugador = "Enrutador_Caballo1"

const RUTA_GUARDADO = "user://sedas_bdg_v2.cfg"
# Mismo orden que en el jinete (Jockey_Tripo_250926.gd). No cambiar el orden.
const DIBUJOS_CHAQUETILLA = ["Liso", "Aros", "Franjas", "Banda cruzada", "Cuartos", "Mitades",
	"Rombos", "Lunares", "Estrellas", "Estrella grande", "Cheurones", "Cruz"]
const DIBUJOS_MANGAS = ["Lisas", "Aros", "Puños", "Hombros"]
const RAZAS = [["americano", "Americano"], ["arabe", "Árabe"], ["cuartomilla", "Cuarto de Milla"], ["ingles", "Patilargo"]]

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

# Figuras que dibuja el propio juego (sin imagenes, no pesan).
# Chaquetilla de frente en un espacio de 100 x 100: cuerpo y mangas por separado.
const CUERPO = [Vector2(35, 12), Vector2(50, 19), Vector2(65, 12), Vector2(78, 19), Vector2(78, 92), Vector2(22, 92), Vector2(22, 19)]
const MANGA_I = [Vector2(22, 19), Vector2(12, 22), Vector2(2, 56), Vector2(14, 61), Vector2(22, 40)]
const MANGA_D = [Vector2(78, 19), Vector2(88, 22), Vector2(98, 56), Vector2(86, 61), Vector2(78, 40)]
# En la manga, el dibujo va del hombro (0) al puno (1).
const UV_MANGA = [Vector2(0, 0), Vector2(0.1, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
const CUELLO = [Vector2(42, 15), Vector2(50, 24), Vector2(58, 15)]
# Gorra de lado (casquete y visera).
const CASQUETE = [Vector2(14.0, 66.0), Vector2(14.3, 53.4), Vector2(16.6, 42.7), Vector2(20.6, 33.7), Vector2(26.0, 26.5), Vector2(32.5, 21.0), Vector2(39.9, 17.1), Vector2(47.8, 14.8), Vector2(56.0, 14.0), Vector2(64.4, 14.9), Vector2(71.7, 17.6), Vector2(77.8, 21.9), Vector2(82.8, 27.8), Vector2(86.4, 35.0), Vector2(88.9, 43.5), Vector2(90.1, 53.2), Vector2(90.0, 64.0)]
const VISERA = [Vector2(86.0, 60.0), Vector2(91.2, 60.5), Vector2(96.9, 61.8), Vector2(102.6, 63.9), Vector2(107.8, 66.7), Vector2(112.0, 70.0), Vector2(104.8, 71.7), Vector2(97.9, 72.2), Vector2(91.3, 71.6), Vector2(85.2, 70.1), Vector2(80.0, 68.0)]
# Caballo de lado, en un espacio de 24 x 24 (silueta de Pictogrammers,
# licencia libre Apache 2.0: se puede usar en un juego comercial).
const CABALLO = [Vector2(22.0, 6.0), Vector2(22.0, 9.5), Vector2(20.5, 10.0), Vector2(18.96, 7.54), Vector2(18.86, 7.45), Vector2(18.74, 7.42), Vector2(18.62, 7.46), Vector2(18.54, 7.54), Vector2(18.5, 7.67), Vector2(18.5, 11.25), Vector2(18.45, 11.83), Vector2(18.32, 12.37), Vector2(18.12, 12.88), Vector2(17.84, 13.35), Vector2(17.5, 13.78), Vector2(17.5, 21.0), Vector2(15.0, 21.0), Vector2(15.0, 15.0), Vector2(14.95, 15.0), Vector2(14.9, 15.0), Vector2(14.85, 15.0), Vector2(14.8, 15.0), Vector2(14.75, 15.0), Vector2(14.62, 15.0), Vector2(14.5, 14.99), Vector2(14.37, 14.97), Vector2(14.25, 14.96), Vector2(14.13, 14.94), Vector2(9.69, 14.2), Vector2(8.57, 16.21), Vector2(9.53, 21.0), Vector2(7.0, 21.0), Vector2(6.0, 16.25), Vector2(5.99, 16.07), Vector2(6.0, 15.89), Vector2(6.03, 15.72), Vector2(6.08, 15.55), Vector2(6.16, 15.39), Vector2(7.18, 13.58), Vector2(6.63, 13.19), Vector2(6.17, 12.71), Vector2(5.82, 12.14), Vector2(5.59, 11.5), Vector2(5.5, 10.81), Vector2(5.48, 10.91), Vector2(5.46, 11.03), Vector2(5.46, 11.16), Vector2(5.46, 11.32), Vector2(5.47, 11.5), Vector2(5.5, 11.79), Vector2(5.53, 12.12), Vector2(5.55, 12.49), Vector2(5.56, 12.89), Vector2(5.54, 13.31), Vector2(5.48, 13.74), Vector2(5.37, 14.17), Vector2(5.2, 14.57), Vector2(4.99, 14.94), Vector2(4.75, 15.26), Vector2(4.49, 15.54), Vector2(4.22, 15.78), Vector2(3.93, 16.0), Vector2(3.65, 16.18), Vector2(3.35, 16.35), Vector2(2.65, 15.65), Vector2(2.76, 15.37), Vector2(2.87, 15.11), Vector2(2.96, 14.85), Vector2(3.03, 14.61), Vector2(3.07, 14.37), Vector2(3.09, 14.16), Vector2(3.09, 13.96), Vector2(3.06, 13.77), Vector2(3.01, 13.6), Vector2(2.95, 13.43), Vector2(2.42, 12.3), Vector2(2.29, 11.97), Vector2(2.17, 11.58), Vector2(2.07, 11.16), Vector2(2.0, 10.69), Vector2(2.0, 10.18), Vector2(2.07, 9.64), Vector2(2.25, 9.08), Vector2(2.52, 8.53), Vector2(2.91, 8.03), Vector2(3.39, 7.61), Vector2(3.94, 7.31), Vector2(4.49, 7.11), Vector2(5.03, 7.02), Vector2(5.56, 7.02), Vector2(6.05, 7.08), Vector2(6.35, 7.16), Vector2(6.65, 7.26), Vector2(6.94, 7.4), Vector2(7.23, 7.57), Vector2(7.5, 7.76), Vector2(7.73, 7.67), Vector2(7.97, 7.6), Vector2(8.22, 7.54), Vector2(8.48, 7.51), Vector2(8.75, 7.5), Vector2(14.5, 7.5), Vector2(14.5, 7.0), Vector2(14.7, 5.74), Vector2(15.27, 4.64), Vector2(16.14, 3.77), Vector2(17.24, 3.2), Vector2(18.5, 3.0), Vector2(22.0, 3.0), Vector2(21.11, 4.34), Vector2(21.41, 4.58), Vector2(21.66, 4.88), Vector2(21.84, 5.22), Vector2(21.96, 5.6)]

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
var _pestana = 0
var _botones_pestana = []
var _paginas = []
var _figuras = []
var _caballos_fig = []
var _textura_blanca = null
var _t_latido = 0.0
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
	# NUEVO - el boton UNIFORME late para que nadie deje de verlo.
	if latido_boton_uniforme and _boton_uniforme.visible and not _velo.visible:
		_t_latido += delta
		var s = 1.0 + fuerza_latido * (0.5 + 0.5 * sin(_t_latido * velocidad_latido * TAU))
		_boton_uniforme.rect_scale = Vector2(s, s)
	else:
		_boton_uniforme.rect_scale = Vector2.ONE


# ------------------------------------------------------------
# Boton UNIFORME
# ------------------------------------------------------------
func _crear_boton_uniforme():
	var tam = get_viewport().get_visible_rect().size
	_boton_uniforme = Button.new()
	_boton_uniforme.focus_mode = Control.FOCUS_NONE
	_boton_uniforme.rect_size = Vector2(ancho_boton_uniforme, alto_boton_uniforme)
	_boton_uniforme.rect_position = Vector2(tam.x - distancia_borde_derecho, distancia_borde_arriba)
	_boton_uniforme.rect_pivot_offset = _boton_uniforme.rect_size / 2.0
	_boton_uniforme.connect("pressed", self, "_abrir")
	add_child(_boton_uniforme)
	# NUEVO - fondo llamativo, borde y sombrita.
	var e = _estilo(color_boton_uniforme, color_borde_boton_uniforme, grosor_borde_boton_uniforme, 8)
	e.shadow_color = Color(0, 0, 0, 0.45)
	e.shadow_size = 4
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		_boton_uniforme.add_stylebox_override(estado, e)
	var caja = HBoxContainer.new()
	caja.anchor_right = 1
	caja.anchor_bottom = 1
	caja.alignment = BoxContainer.ALIGN_CENTER
	caja.add_constant_override("separation", 6)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_uniforme.add_child(caja)
	# NUEVO - figurita del uniforme con tus colores.
	if figura_en_boton_uniforme:
		var lado = alto_boton_uniforme - 6
		var fig = _figura_jinete(Vector2(lado * 0.8, lado), true, "vista", 0)
		fig.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		caja.add_child(fig)
		if figura_boton_azul_negro:
			# Se saca de la lista para que no la pinten con tus colores.
			var datos = _figuras.pop_back()
			_pintar_figura(fig, color_figura_boton_uniforme, color_contorno_figura_boton)
			for g in datos["gorra"]:
				g.color = color_contorno_figura_boton
	var l = Label.new()
	l.text = texto_boton_uniforme
	l.valign = Label.VALIGN_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_color_override("font_color", color_letra_boton_uniforme)
	l.add_color_override("font_outline_modulate", Color(0, 0, 0, 0))
	caja.add_child(l)
	_letra(l, tamano_letra_boton_uniforme)


# ------------------------------------------------------------
# Panel: arriba el JINETE con todas sus opciones al lado (Dibujo,
# Colores, Mangas, Gorra); abajo el CABALLO con raza y pelaje al lado.
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
	margen.add_constant_override("margin_left", 16)
	margen.add_constant_override("margin_right", 16)
	margen.add_constant_override("margin_top", 8)
	margen.add_constant_override("margin_bottom", 12)
	panel.add_child(margen)

	var columna = VBoxContainer.new()
	columna.add_constant_override("separation", 8)
	margen.add_child(columna)

	# --- Arriba: titulo, AL AZAR y LISTO ---
	var arriba = HBoxContainer.new()
	arriba.add_constant_override("separation", 10)
	columna.add_child(arriba)
	var hueco = Control.new()
	hueco.rect_min_size = Vector2(230, 0)
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arriba.add_child(hueco)
	var titulo = _texto(arriba, "UNIFORME", tamano_titulo_panel)
	titulo.align = Label.ALIGN_CENTER
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var boton_azar = _boton_final(arriba, "AL AZAR", false)
	boton_azar.connect("pressed", self, "_al_azar")
	var boton_listo = _boton_final(arriba, "LISTO", true)
	boton_listo.connect("pressed", self, "_cerrar")

	# --- El jinete y sus opciones ---
	var opciones_j = _bloque(columna, "JINETE", true)
	var fila_pestanas = HBoxContainer.new()
	fila_pestanas.add_constant_override("separation", 6)
	opciones_j.add_child(fila_pestanas)
	var iconos_pestana = [
		_figura_jinete(Vector2(28, 26), false, "dibujo", 1),
		_figura_jinete(Vector2(28, 26), false, "plana", 0),
		_figura_jinete(Vector2(28, 26), false, "manga", 1),
		_figura_gorra(Vector2(32, 22))]
	var nombres_pestana = ["DIBUJO", "COLORES", "MANGAS", "GORRA"]
	for i in nombres_pestana.size():
		var b = _boton_pestana(fila_pestanas, iconos_pestana[i], nombres_pestana[i])
		b.connect("pressed", self, "_elegir_pestana", [i])

	var pagina_dibujo = GridContainer.new()
	pagina_dibujo.columns = 6
	pagina_dibujo.add_constant_override("hseparation", 6)
	pagina_dibujo.add_constant_override("vseparation", 6)
	opciones_j.add_child(pagina_dibujo)
	for i in DIBUJOS_CHAQUETILLA.size():
		var b = _boton_icono(pagina_dibujo, _figura_jinete(Vector2(alto_icono, alto_icono - 20), false, "dibujo", i),
			DIBUJOS_CHAQUETILLA[i], Vector2(ancho_icono, alto_icono), tamano_letra_iconos)
		b.connect("pressed", self, "_elegir_chaquetilla", [i])
		_botones_chaquetilla.append(b)

	var pagina_colores = VBoxContainer.new()
	pagina_colores.add_constant_override("separation", 4)
	opciones_j.add_child(pagina_colores)
	_texto(pagina_colores, "COLOR DE FONDO", tamano_letra_titulos)
	_crear_muestras(pagina_colores, 1)
	_texto(pagina_colores, "COLOR DEL DIBUJO", tamano_letra_titulos)
	_crear_muestras(pagina_colores, 2)

	var pagina_mangas = GridContainer.new()
	pagina_mangas.columns = 6
	pagina_mangas.add_constant_override("hseparation", 6)
	opciones_j.add_child(pagina_mangas)
	for i in DIBUJOS_MANGAS.size():
		var b = _boton_icono(pagina_mangas, _figura_jinete(Vector2(alto_icono, alto_icono - 20), false, "manga", i),
			DIBUJOS_MANGAS[i], Vector2(ancho_icono, alto_icono), tamano_letra_iconos)
		b.connect("pressed", self, "_elegir_mangas", [i])
		_botones_mangas.append(b)

	var pagina_gorra = VBoxContainer.new()
	pagina_gorra.add_constant_override("separation", 4)
	opciones_j.add_child(pagina_gorra)
	_texto(pagina_gorra, "COLOR DE LA GORRA", tamano_letra_titulos)
	_crear_muestras(pagina_gorra, 3)
	_paginas = [pagina_dibujo, pagina_colores, pagina_mangas, pagina_gorra]

	# --- El caballo y sus opciones ---
	var opciones_c = _bloque(columna, "CABALLO", false)
	_texto(opciones_c, "RAZA", tamano_letra_titulos)
	var fila_razas = GridContainer.new()
	fila_razas.columns = 4
	fila_razas.add_constant_override("hseparation", 6)
	opciones_c.add_child(fila_razas)
	for r in RAZAS:
		if r[0] == "cuartomilla" and not ofrecer_cuartomilla:
			continue
		if r[0] == "ingles" and not ofrecer_ingles:
			continue
		var b = _boton_icono(fila_razas, _figura_caballo(Vector2(alto_icono + 8, alto_icono - 18), "raza", 0, r[0]),
			r[1], Vector2(ancho_icono, alto_icono), tamano_letra_iconos)
		b.connect("pressed", self, "_elegir_raza", [r[0]])
		_botones_raza.append(b)
		_razas_ofrecidas.append(r[0])

	_texto_pelaje = _texto(opciones_c, "PELAJE", tamano_letra_titulos)
	var fila_pelajes = GridContainer.new()
	fila_pelajes.columns = columnas_pelaje
	fila_pelajes.add_constant_override("hseparation", 4)
	fila_pelajes.add_constant_override("vseparation", 4)
	opciones_c.add_child(fila_pelajes)
	var colores_pelaje = _lista_pelajes("COLORES")
	var nombres_pelaje = _lista_pelajes("NOMBRES")
	for i in colores_pelaje.size():
		var nombre = str(nombres_pelaje[i]).capitalize() if i < nombres_pelaje.size() else ""
		var b = _boton_icono(fila_pelajes, _figura_caballo(Vector2(ancho_icono_pelaje - 6, 30), "pelaje", i),
			nombre, Vector2(ancho_icono_pelaje, alto_icono_pelaje), tamano_letra_pelaje)
		b.connect("pressed", self, "_elegir_pelaje", [i])
		_muestras_pelaje.append([b, Color(colores_pelaje[i])])


# Recuadro con la figura grande a la izquierda y sus opciones a la derecha.
# Devuelve la columna de opciones.
func _bloque(padre, titulo, es_jinete):
	var marco = PanelContainer.new()
	var e = StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0)
	e.border_color = Color(color_dorado.r, color_dorado.g, color_dorado.b, 0.35)
	e.set_border_width_all(1)
	e.set_corner_radius_all(8)
	e.content_margin_left = 8
	e.content_margin_right = 8
	e.content_margin_top = 6
	e.content_margin_bottom = 6
	marco.add_stylebox_override("panel", e)
	# Los dos recuadros se reparten el alto: el panel no cambia de tamano al cambiar de pestana.
	marco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	marco.size_flags_stretch_ratio = 1.2 if es_jinete else 1.0
	padre.add_child(marco)

	var fila = HBoxContainer.new()
	fila.add_constant_override("separation", 12)
	marco.add_child(fila)

	var tarjeta = VBoxContainer.new()
	tarjeta.rect_min_size = Vector2(lado_figura_grande + 20, 0)
	tarjeta.alignment = BoxContainer.ALIGN_CENTER
	fila.add_child(tarjeta)
	var figura = null
	if es_jinete:
		if probador_3d:
			_crear_contenedor_probador(tarjeta)
			var texto_probador = _texto(tarjeta, "ARRASTRA PARA GIRAR", tamano_letra_iconos)
			texto_probador.align = Label.ALIGN_CENTER
		else:
			figura = _figura_jinete(Vector2(lado_figura_grande, lado_figura_grande), true, "vista", 0)
	else:
		figura = _figura_caballo(Vector2(lado_figura_grande, lado_figura_grande * 0.8), "grande", 0)
	if figura != null:
		figura.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tarjeta.add_child(figura)
	var nombre = _texto(tarjeta, titulo, tamano_textos + 2)
	nombre.align = Label.ALIGN_CENTER

	var raya = ColorRect.new()
	raya.color = Color(color_dorado.r, color_dorado.g, color_dorado.b, 0.35)
	raya.rect_min_size = Vector2(1, 0)
	raya.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(raya)

	var opciones = VBoxContainer.new()
	opciones.add_constant_override("separation", 6)
	opciones.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(opciones)
	return opciones


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


# Boton con una figura arriba y su nombre abajo.
func _boton_icono(padre, figura, texto, tam, tam_letra):
	var b = Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.rect_min_size = tam
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(b)
	var caja = VBoxContainer.new()
	caja.anchor_right = 1
	caja.anchor_bottom = 1
	caja.alignment = BoxContainer.ALIGN_CENTER
	caja.add_constant_override("separation", 0)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(caja)
	figura.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(figura)
	if texto != "":
		var l = Label.new()
		l.text = texto
		l.align = Label.ALIGN_CENTER
		l.autowrap = true
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_color_override("font_color", color_dorado)
		caja.add_child(l)
		_letra(l, tam_letra)
	_marcar_icono(b, false)
	return b


# Pestana: figura chica y nombre, uno al lado del otro.
func _boton_pestana(padre, figura, texto):
	var b = Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.rect_min_size = Vector2(0, alto_pestana)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(b)
	var caja = HBoxContainer.new()
	caja.anchor_right = 1
	caja.anchor_bottom = 1
	caja.alignment = BoxContainer.ALIGN_CENTER
	caja.add_constant_override("separation", 6)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(caja)
	figura.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	caja.add_child(figura)
	var l = Label.new()
	l.text = texto
	l.valign = Label.VALIGN_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(l)
	_letra(l, tamano_textos)
	_botones_pestana.append([b, l])
	return b


func _elegir_pestana(i):
	_pestana = i
	_refrescar()


# ------------------------------------------------------------
# Figuras dibujadas por el juego
# ------------------------------------------------------------
# Chaquetilla (con o sin gorra). tipo: "vista" (lo que llevas puesto),
# "dibujo" (muestra el dibujo i), "manga" (muestra las mangas i), "plana".
func _figura_jinete(tam, con_gorra, tipo, i):
	var caja = Control.new()
	caja.rect_min_size = tam
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dibujo = Node2D.new()
	caja.add_child(dibujo)
	var arriba = -36.0 if con_gorra else 4.0
	var alto = 132.0 if con_gorra else 94.0
	var esc = min(tam.x / 100.0, tam.y / alto)
	dibujo.scale = Vector2(esc, esc)
	dibujo.position = Vector2((tam.x - 100.0 * esc) / 2.0, (tam.y - alto * esc) / 2.0 - arriba * esc)
	var fig = {"tipo": tipo, "i": i, "cuerpo": null, "mangas": [], "gorra": []}
	for puntos in [MANGA_I, MANGA_D]:
		fig["mangas"].append(_pieza(dibujo, puntos, UV_MANGA, true, esc))
	var uv_cuerpo = []
	for p in CUERPO:
		uv_cuerpo.append(Vector2((p.x - 22.0) / 56.0, (p.y - 12.0) / 56.0))
	fig["cuerpo"] = _pieza(dibujo, CUERPO, uv_cuerpo, false, esc)
	_linea(dibujo, CUELLO, false, esc)
	if con_gorra:
		var g = Node2D.new()
		g.position = Vector2(27, -34)
		g.scale = Vector2(0.44, 0.44)
		dibujo.add_child(g)
		fig["gorra"] = _gorra_en(g, esc * 0.44)
	_figuras.append(fig)
	return caja


# Solo la gorra (para la pestana GORRA).
func _figura_gorra(tam):
	var caja = Control.new()
	caja.rect_min_size = tam
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g = Node2D.new()
	var esc = min(tam.x / 108.0, tam.y / 66.0)
	g.scale = Vector2(esc, esc)
	g.position = Vector2((tam.x - 108.0 * esc) / 2.0 - 8.0 * esc, (tam.y - 66.0 * esc) / 2.0 - 10.0 * esc)
	caja.add_child(g)
	_figuras.append({"tipo": "gorra", "i": 0, "cuerpo": null, "mangas": [], "gorra": _gorra_en(g, esc)})
	return caja


func _gorra_en(padre, esc):
	var partes = []
	for puntos in [CASQUETE, VISERA]:
		var p = Polygon2D.new()
		p.polygon = PoolVector2Array(puntos)
		p.antialiased = true
		padre.add_child(p)
		partes.append(p)
		_linea(padre, puntos, true, esc)
	return partes


# Caballo de lado. tipo: "grande" y "raza" llevan tu pelaje; "pelaje" lleva el pelaje i.
func _figura_caballo(tam, tipo, i, raza = ""):
	var caja = Control.new()
	caja.rect_min_size = tam
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dibujo = Node2D.new()
	caja.add_child(dibujo)
	# Cada raza con su porte: ancho y alto un poco distintos.
	var forma = Vector2(1, 1)
	if raza == "arabe":
		forma = Vector2(0.96, 0.95)
	elif raza == "cuartomilla":
		forma = Vector2(1.05, 0.9)
	elif raza == "ingles":
		forma = Vector2(0.97, 1.07)
	var esc = min(tam.x / 21.0, tam.y / 19.5)
	dibujo.scale = Vector2(esc * forma.x, esc * forma.y)
	dibujo.position = Vector2(tam.x / 2.0 - 12.0 * esc * forma.x, tam.y / 2.0 - 12.0 * esc * forma.y)
	var p = Polygon2D.new()
	p.polygon = PoolVector2Array(CABALLO)
	p.antialiased = true
	dibujo.add_child(p)
	_linea(dibujo, CABALLO, true, esc)
	_caballos_fig.append({"tipo": tipo, "i": i, "poly": p})
	return caja


# Una pieza de la chaquetilla, pintada con el mismo dibujo del jinete.
func _pieza(padre, puntos, uvs, es_manga, esc):
	var p = Polygon2D.new()
	p.polygon = PoolVector2Array(puntos)
	p.texture = _blanca()
	p.uv = PoolVector2Array(uvs)
	p.antialiased = true
	var m = ShaderMaterial.new()
	m.shader = _sombreador
	m.set_shader_param("manga", es_manga)
	p.material = m
	padre.add_child(p)
	_linea(padre, puntos, true, esc)
	return m


func _linea(padre, puntos, cerrada, esc):
	var arr = PoolVector2Array(puntos)
	if cerrada:
		arr.append(puntos[0])
	var l = Line2D.new()
	l.points = arr
	l.width = grosor_linea / max(esc, 0.01)
	l.default_color = color_dorado
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.antialiased = true
	padre.add_child(l)


# NUEVO 16-oct - Pinta una figurita: piezas de un color y bordes de otro.
func _pintar_figura(nodo, relleno, borde):
	for h in nodo.get_children():
		if h is Polygon2D:
			h.material = null
			h.color = relleno
		elif h is Line2D:
			h.default_color = borde
		_pintar_figura(h, relleno, borde)


# Textura blanca de 1 x 1: le permite al dibujo saber en que parte de la pieza esta.
func _blanca():
	if _textura_blanca == null:
		var img = Image.new()
		img.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1))
		_textura_blanca = ImageTexture.new()
		_textura_blanca.create_from_image(img, 0)
	return _textura_blanca


func _boton_final(padre, texto, relleno):
	var b = Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.rect_min_size = Vector2(110, 34)
	padre.add_child(b)
	_letra(b, tamano_textos + 1)
	if relleno:
		_pintar_boton(b, color_dorado, color_fondo_panel, 6)
		# NUEVO - sin el contorno negro de la letra: sobre el dorado, la
		# letra vino tinto se lee limpia.
		var f = b.get_font("font")
		if f is DynamicFont:
			f.outline_size = 0
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
		_marcar_icono(_botones_chaquetilla[i], i == _dibujo_chaquetilla)
	for i in _botones_mangas.size():
		_marcar_icono(_botones_mangas[i], i == _dibujo_mangas)
	for i in _botones_raza.size():
		_marcar_icono(_botones_raza[i], _razas_ofrecidas[i] == _raza)
	for i in _muestras_pelaje.size():
		_marcar_icono(_muestras_pelaje[i][0], i == _pelaje)
	if _texto_pelaje != null:
		var nombres_p = _lista_pelajes("NOMBRES")
		if _pelaje >= 0 and _pelaje < nombres_p.size():
			_texto_pelaje.text = "PELAJE: " + str(nombres_p[_pelaje]).to_upper()
	# Pestanas: solo se ve la pagina de la pestana escogida.
	for i in _paginas.size():
		_paginas[i].visible = (i == _pestana)
	for i in _botones_pestana.size():
		var b = _botones_pestana[i][0]
		var l = _botones_pestana[i][1]
		if i == _pestana:
			var e = _estilo(color_dorado, color_dorado, 2, 6)
			for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
				b.add_stylebox_override(estado, e)
			l.add_color_override("font_color", color_fondo_panel)
			l.add_color_override("font_outline_modulate", Color(0, 0, 0, 0))
		else:
			_marcar_icono(b, false)
			l.add_color_override("font_color", color_dorado)
			l.add_color_override("font_outline_modulate", Color(0, 0, 0, 1))
	_refrescar_figuras()


# Las figuras de la chaquetilla, la gorra y los caballos con lo elegido.
func _refrescar_figuras():
	var cantidad = _cantidad_del_jinete()
	var manga_1 = _color_principal if mangas_del_color_principal else _color_diseno
	var manga_2 = _color_diseno if mangas_del_color_principal else _color_principal
	for f in _figuras:
		var d_cuerpo = _dibujo_chaquetilla
		var d_mangas = _dibujo_mangas
		if f["tipo"] == "dibujo":
			d_cuerpo = f["i"]
			d_mangas = 0
		elif f["tipo"] == "manga":
			d_cuerpo = 0
			d_mangas = f["i"]
		elif f["tipo"] == "plana":
			d_cuerpo = 0
			d_mangas = 0
		if f["cuerpo"] != null:
			_poner_material(f["cuerpo"], _color_principal, _color_diseno, d_cuerpo, cantidad)
		for m in f["mangas"]:
			_poner_material(m, manga_1, manga_2, d_mangas, cantidad)
		for g in f["gorra"]:
			g.color = _color_gorra
	var colores_p = _lista_pelajes("COLORES")
	var tuyo = Color("ffffff")
	if _pelaje >= 0 and _pelaje < colores_p.size():
		tuyo = Color(colores_p[_pelaje])
	for c in _caballos_fig:
		if c["tipo"] == "pelaje" and c["i"] < colores_p.size():
			c["poly"].color = Color(colores_p[c["i"]])
		else:
			c["poly"].color = tuyo


func _poner_material(m, c1, c2, dibujo, cantidad):
	m.set_shader_param("color_1", c1)
	m.set_shader_param("color_2", c2)
	m.set_shader_param("diseno", dibujo)
	m.set_shader_param("cantidad", cantidad)


func _marcar(b, marcado):
	if marcado:
		_pintar_boton(b, color_dorado, color_fondo_panel, 6)
	else:
		_pintar_boton(b, color_fondo_panel, color_dorado, 6)


# Boton con figura: escogido = borde dorado grueso y fondo dorado suave.
func _marcar_icono(b, marcado):
	var e = StyleBoxFlat.new()
	if marcado:
		e.bg_color = Color(color_dorado.r, color_dorado.g, color_dorado.b, 0.18)
		e.border_color = color_dorado
		e.set_border_width_all(3)
	else:
		e.bg_color = Color(0, 0, 0, 0)
		e.border_color = Color(color_dorado.r, color_dorado.g, color_dorado.b, 0.45)
		e.set_border_width_all(1)
	e.set_corner_radius_all(6)
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_stylebox_override(estado, e)


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
