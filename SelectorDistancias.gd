extends CanvasLayer
# VERSION 16-oct: bloque de NIVEL despues de escoger la distancia (volver a jugar niveles ganados y borrar el avance)

# Este panel SOLO elige la distancia. La pausa, el boton "PARTIDA"
# y la cuenta regresiva ya los maneja PantallaInicio.gd por su
# cuenta - no hay que duplicar nada de eso aca.

# ============================================================
# TAMANO DE LA COLUMNA  (todo ajustable desde el Inspector)
# ============================================================
# Los mandos tactiles ya no se dibujan en la pantalla de inicio,
# asi que esta columna tiene la pantalla para ella sola.
# Si algun boton se sale de la pantalla en un telefono mas chico,
# baja alto_boton o separacion_entre_botones.
# (Con GRAMA y ARENA en la misma lista los botones quedaron mas
# bajitos, para que no choquen con el engranaje de abajo.)
export var ancho_boton = 190
export var alto_boton = 48
export var separacion_entre_botones = 6
export var margen = Vector2(16, 16)
export var tamano_texto = 26
export var tamano_texto_titulo = 24
# Titulos de cada grupo de la lista y su color (codigo hex).
export var texto_grama = "GRAMA"
export var texto_arena = "ARENA"
export var color_titulos = Color("c4a159")

# ============================================================
# NIVEL (NUEVO 16-oct) - volver a jugar los niveles ya ganados y
# borrar el avance. Cada distancia (y grama o arena) lleva su propio
# avance: lo que se escoge o se borra aqui es SOLO de la distancia
# elegida. Va debajo del boton PARTIDA.
# ============================================================
export var mostrar_nivel = true
# Donde va el bloque (0 = izquierda/arriba, 1 = derecha/abajo).
export var posicion_nivel = Vector2(0.5, 0.84)
export var tamano_texto_nivel = 30
export var tamano_texto_nivel_chico = 18
export var ancho_flecha_nivel = 60
export var alto_flecha_nivel = 50
export var ancho_texto_nivel = 170
export var ancho_boton_borrar = 210
export var color_texto_nivel = Color("ffd955")
export var color_fondo_nivel = Color("0f0f14")
export var color_borde_nivel = Color("ffd955")
export var color_borde_borrar = Color("c62828")
export var texto_borrar = "BORRAR AVANCE"
export var texto_confirmar_borrar = "¿SEGURO? TOCA OTRA VEZ"
# Segundos que espera despues del ultimo toque en las flechas antes de
# recargar la pista con el nivel escogido (asi no recarga en cada toque).
export var espera_cambio_nivel = 0.8

# El mismo archivo donde GestorNivel.gd guarda el avance.
const RUTA_PROGRESO = "user://progreso_bdg.cfg"
var _nivel_elegido = 1
var _nivel_alcanzado = 1
var _label_nivel = null
var _label_rango = null
var _boton_menos = null
var _boton_mas = null
var _boton_borrar = null
var _caja_nivel = null
var _confirmando_borrar = 0.0
var _espera_nivel = -1.0

var distancias = [
	{"etiqueta": "800m", "valor": 800.0, "arreo": 60, "estamina": 100},
	{"etiqueta": "1200m", "valor": 1600.0, "arreo": 40, "estamina": 120},
	{"etiqueta": "1600m", "valor": 2000.0, "arreo": 50, "estamina": 160},
	# Las tres siguientes NO usan formula de "vueltas" a ciegas: cada
	# valor es el punto de arranque de otra distancia YA VERIFICADO en
	# recta, mas una o mas vueltas completas (3334.799316 cada una).
	# Sumar una vuelta entera NO cambia el punto de arranque (cae en
	# el mismo offset), asi que ninguna de estas tres necesita
	# correccion de _ajustar_offset_a_recta - arrancan derecho, sin
	# que el juego las mueva.
	#
	# 2000m: arranca en el mismo punto que 1200m (offset ~400.5),
	# 2 vueltas desde ahi. 1600.0 + 3334.799316 = 4934.799316
	{"etiqueta": "2000m", "valor": 4934.799316, "arreo": 60, "estamina": 200},
	# 2400m: arranca en el mismo punto que 800m (offset ~56.0), que
	# tiene mas recta libre antes de la curva que el punto de 1200m.
	# 2 vueltas desde ahi. 1944.5 + 3334.799316 = 5279.299316
	{"etiqueta": "2400m", "valor": 5279.299316, "arreo": 70, "estamina": 150},
	# 3000m: arranca en el mismo punto que 1200m (offset ~400.5),
	# 3 vueltas desde ahi. 1600.0 + 2*3334.799316 = 8269.598632
	{"etiqueta": "3000m", "valor": 8269.598632, "arreo": 80, "estamina": 300},
]

# NUEVO - carreras de la pista de arena. El nombre es lo que ve el
# jugador; el valor es lo que de verdad se corre en la arena (cuya
# vuelta mide 1529). Por ahora la largada tiene que caer en la recta
# de atras, igual que en la grama, y desde ahi salen estas dos:
#   1100m -> media vuelta        (764.5)
#   1900m -> vuelta y media      (764.5 + 1529 = 2293.5)
var distancias_arena = [
	{"etiqueta": "1100m", "valor": 764.5, "arreo": 60, "estamina": 100},
	{"etiqueta": "1900m", "valor": 2293.5, "arreo": 50, "estamina": 200},
]
var botones = []

func _ready():
	# Para poder elegir distancia aunque PantallaInicio tenga el
	# juego en pausa esperando el click en "PARTIDA".
	pause_mode = Node.PAUSE_MODE_PROCESS

	var contenedor = VBoxContainer.new()
	contenedor.rect_position = margen
	contenedor.add_constant_override("separation", separacion_entre_botones)
	add_child(contenedor)

	_agregar_grupo(contenedor, texto_grama, distancias, false)
	_agregar_grupo(contenedor, texto_arena, distancias_arena, true)

	# NUEVO - bloque de NIVEL: sale solo despues de que el jugador escoge
	# su distancia (no sale en el modo de prueba de GestorNivel).
	if mostrar_nivel and ConfiguracionCarrera.distancia_elegida and GestorNivel and GestorNivel.nivel_de_prueba <= 0:
		_crear_bloque_nivel()


# Un titulo (GRAMA o ARENA) y sus botones debajo.
func _agregar_grupo(contenedor, texto, lista, es_arena):
	var titulo = Label.new()
	titulo.text = texto
	titulo.add_color_override("font_color", color_titulos)
	contenedor.add_child(titulo)
	_agrandar_texto(titulo, tamano_texto_titulo)

	for d in lista:
		var boton = Button.new()
		boton.text = d["etiqueta"]
		boton.rect_min_size = Vector2(ancho_boton, alto_boton)
		boton.connect("pressed", self, "_cambiar_distancia", [d["valor"], d["etiqueta"], d["arreo"], d["estamina"], es_arena])
		contenedor.add_child(boton)
		_agrandar_texto(boton, tamano_texto)
		botones.append(boton)


# Agranda la letra de un control sin tocar la fuente de todo el
# juego. Copia la fuente que ya tiene puesta y le cambia solo el
# tamano a esa copia, asi el resto de la interfaz queda igual.
func _agrandar_texto(control, tamano):
	var base = control.get_font("font")
	if base == null or not (base is DynamicFont):
		return
	var copia = base.duplicate()
	copia.size = tamano
	control.add_font_override("font", copia)

func _cambiar_distancia(nuevo_valor, etiqueta, nuevo_arreo, nueva_estamina, es_arena = false):
	for b in botones:
		b.disabled = true
	# NUEVO - grama o arena (TrackPath lo lee al arrancar la carrera).
	if "pista_arena" in ConfiguracionCarrera:
		ConfiguracionCarrera.pista_arena = es_arena
	ConfiguracionCarrera.distancia_metros = nuevo_valor
	# NUEVO - ya escogio distancia: al recargar le sale el bloque de NIVEL.
	ConfiguracionCarrera.distancia_elegida = true
	# REGLA 2 - 800m es el unico modo recta independiente por ahora
	# (solo en grama).
	ConfiguracionCarrera.modo_recta = (nuevo_valor == 800.0 and not es_arena)
	# REGLA 2b - el modo "vuelta completa" queda APAGADO. Las 6
	# distancias usan exactamente el mismo mecanismo.
	ConfiguracionCarrera.modo_vuelta_completa = false
	# NUEVO - limite de arreo para esta distancia. En 800m no se usa
	# (ese modo tiene su propio limite fijo, arreo_limite_ritmo=60),
	# pero no hace falta filtrarlo aca: da igual que quede guardado.
	ConfiguracionCarrera.arreo_limite = nuevo_arreo
	# NUEVO - stamina base para esta distancia (ver ConfiguracionCarrera.gd).
	ConfiguracionCarrera.estamina_base = nueva_estamina
	get_tree().call_deferred("reload_current_scene")

func _process(delta):
	# NUEVO - nivel escogido con las flechas: se aplica al dejar de tocar.
	if _espera_nivel > 0.0:
		_espera_nivel -= delta
		if _espera_nivel <= 0.0:
			_aplicar_nivel()
	if _confirmando_borrar > 0.0:
		_confirmando_borrar -= delta
		if _confirmando_borrar <= 0.0 and _boton_borrar:
			_boton_borrar.text = texto_borrar
			call_deferred("_ubicar_bloque_nivel")
	# En cuanto PantallaInicio termina la cuenta regresiva y quita
	# la pausa, la carrera arranco de verdad - ahi se esconde este
	# menu para que deje de tapar la nomenclatura (velocidad,
	# stamina, arreo, etc).
	if not get_tree().paused and visible:
		visible = false


# ============================================================
# NIVEL (NUEVO 16-oct)
# ============================================================
func _crear_bloque_nivel():
	_leer_avance()
	_caja_nivel = VBoxContainer.new()
	_caja_nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caja_nivel.add_constant_override("separation", 6)
	add_child(_caja_nivel)

	_label_rango = Label.new()
	_label_rango.align = Label.ALIGN_CENTER
	_label_rango.add_color_override("font_color", color_titulos)
	_label_rango.add_color_override("font_color_shadow", Color(0, 0, 0, 0.8))
	_caja_nivel.add_child(_label_rango)
	_agrandar_texto(_label_rango, tamano_texto_nivel_chico)

	var fila = HBoxContainer.new()
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.alignment = BoxContainer.ALIGN_CENTER
	fila.add_constant_override("separation", 8)
	_caja_nivel.add_child(fila)

	_boton_menos = _boton_nivel(fila, "<", Vector2(ancho_flecha_nivel, alto_flecha_nivel), color_borde_nivel, tamano_texto_nivel)
	_boton_menos.connect("pressed", self, "_mover_nivel", [-1])

	var marco = PanelContainer.new()
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.rect_min_size = Vector2(ancho_texto_nivel, alto_flecha_nivel)
	marco.add_stylebox_override("panel", _estilo_nivel(color_borde_nivel))
	fila.add_child(marco)
	_label_nivel = Label.new()
	_label_nivel.align = Label.ALIGN_CENTER
	_label_nivel.valign = Label.VALIGN_CENTER
	_label_nivel.add_color_override("font_color", color_texto_nivel)
	marco.add_child(_label_nivel)
	_agrandar_texto(_label_nivel, tamano_texto_nivel)

	_boton_mas = _boton_nivel(fila, ">", Vector2(ancho_flecha_nivel, alto_flecha_nivel), color_borde_nivel, tamano_texto_nivel)
	_boton_mas.connect("pressed", self, "_mover_nivel", [1])

	var hueco = Control.new()
	hueco.rect_min_size = Vector2(14, 1)
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(hueco)

	_boton_borrar = _boton_nivel(fila, texto_borrar, Vector2(ancho_boton_borrar, alto_flecha_nivel), color_borde_borrar, tamano_texto_nivel_chico)
	_boton_borrar.connect("pressed", self, "_al_borrar")

	_pintar_nivel()
	call_deferred("_ubicar_bloque_nivel")


func _ubicar_bloque_nivel():
	if _caja_nivel == null:
		return
	var tam = get_viewport().get_visible_rect().size
	var medida = _caja_nivel.get_combined_minimum_size()
	_caja_nivel.rect_size = medida
	_caja_nivel.rect_position = Vector2(tam.x * posicion_nivel.x - medida.x * 0.5, tam.y * posicion_nivel.y - medida.y * 0.5)


func _boton_nivel(padre, texto, medida, borde, tamano):
	var b = Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.rect_min_size = medida
	b.add_stylebox_override("normal", _estilo_nivel(borde))
	b.add_stylebox_override("hover", _estilo_nivel(borde))
	var apretado = _estilo_nivel(borde)
	apretado.bg_color = borde.darkened(0.6)
	b.add_stylebox_override("pressed", apretado)
	var apagado = _estilo_nivel(Color(borde.r, borde.g, borde.b, 0.3))
	b.add_stylebox_override("disabled", apagado)
	b.add_color_override("font_color", color_texto_nivel)
	b.add_color_override("font_color_hover", color_texto_nivel)
	b.add_color_override("font_color_pressed", color_texto_nivel)
	b.add_color_override("font_color_disabled", Color(color_texto_nivel.r, color_texto_nivel.g, color_texto_nivel.b, 0.3))
	padre.add_child(b)
	_agrandar_texto(b, tamano)
	return b


func _estilo_nivel(borde):
	var e = StyleBoxFlat.new()
	e.bg_color = color_fondo_nivel
	e.border_color = borde
	e.set_border_width_all(3)
	e.set_corner_radius_all(10)
	return e


# Nivel en que va (el que se va a correr) y hasta donde llego ganando.
func _leer_avance():
	_nivel_elegido = int(GestorNivel.nivel_actual)
	_nivel_alcanzado = _nivel_elegido
	var archivo = ConfigFile.new()
	if archivo.load(RUTA_PROGRESO) == OK:
		var clave = GestorNivel._clave_distancia()
		_nivel_alcanzado = int(max(_nivel_alcanzado, archivo.get_value(clave, "nivel_alcanzado", 1)))
	_nivel_alcanzado = int(clamp(_nivel_alcanzado, 1, GestorNivel.nivel_maximo))


func _pintar_nivel():
	_label_nivel.text = "NIVEL %d" % _nivel_elegido
	var nombre = _nombre_distancia()
	if _nivel_alcanzado <= 1:
		_label_rango.text = nombre + "  -  Gana para pasar al nivel 2"
	else:
		_label_rango.text = nombre + "  -  Puedes jugar del nivel 1 al %d" % _nivel_alcanzado
	_boton_menos.disabled = _nivel_elegido <= 1
	_boton_mas.disabled = _nivel_elegido >= _nivel_alcanzado
	call_deferred("_ubicar_bloque_nivel")


func _nombre_distancia():
	var arena = ConfiguracionCarrera.pista_arena if "pista_arena" in ConfiguracionCarrera else false
	var lista = distancias_arena if arena else distancias
	for d in lista:
		if abs(d["valor"] - float(ConfiguracionCarrera.distancia_metros)) < 0.5:
			return d["etiqueta"] + (" ARENA" if arena else " GRAMA")
	return ""


func _mover_nivel(paso):
	var n = int(clamp(_nivel_elegido + paso, 1, _nivel_alcanzado))
	if n == _nivel_elegido:
		return
	_nivel_elegido = n
	_pintar_nivel()
	_espera_nivel = espera_cambio_nivel


# Guarda el nivel escogido (sin perder hasta donde llego) y recarga la
# pista, para que los rivales y la estamina tomen ese nivel.
func _aplicar_nivel():
	var archivo = ConfigFile.new()
	archivo.load(RUTA_PROGRESO)
	var clave = GestorNivel._clave_distancia()
	archivo.set_value(clave, "nivel", _nivel_elegido)
	archivo.set_value(clave, "nivel_alcanzado", _nivel_alcanzado)
	archivo.save(RUTA_PROGRESO)
	_recargar()


# Primer toque: pide confirmar. Segundo toque (antes de 3 segundos): borra
# el avance de ESTA distancia y vuelve al nivel 1.
func _al_borrar():
	if _confirmando_borrar <= 0.0:
		_confirmando_borrar = 3.0
		_boton_borrar.text = texto_confirmar_borrar
		call_deferred("_ubicar_bloque_nivel")
		return
	_confirmando_borrar = 0.0
	GestorNivel.borrar_progreso_de_distancia()
	_recargar()


func _recargar():
	for b in botones:
		b.disabled = true
	for b in [_boton_menos, _boton_mas, _boton_borrar]:
		if b:
			b.disabled = true
	get_tree().call_deferred("reload_current_scene")
