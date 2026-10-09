extends CanvasLayer

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
	{"etiqueta": "2400m", "valor": 5279.299316, "arreo": 70, "estamina": 240},
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
	{"etiqueta": "1100m", "valor": 764.5, "arreo": 60, "estamina": 120},
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
	# En cuanto PantallaInicio termina la cuenta regresiva y quita
	# la pausa, la carrera arranco de verdad - ahi se esconde este
	# menu para que deje de tapar la nomenclatura (velocidad,
	# stamina, arreo, etc).
	if not get_tree().paused and visible:
		visible = false
