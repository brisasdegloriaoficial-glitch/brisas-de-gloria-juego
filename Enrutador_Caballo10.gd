extends PathFollow

# PUNTERO: sale a la punta desde el arranque, aguanta adelante casi
# toda la carrera, y se cansa en el tramo final - lo van pasando.
#
# CORREGIDO (motivo: iba siempre pegado al Caballo9). Antes este era
# un SEGUNDO rematador, casi igual al 9: los dos guardaban energia,
# los dos aceleraban al final, los dos arrancaban en los carriles de
# mas afuera. Con el mismo plan de carrera terminaban siempre
# corriendo juntos, como un solo caballo doble.
# Ahora tienen planes opuestos: el 9 espera atras y remata, el 10 se
# va adelante y se apaga. Nunca mas se van a pegar, porque uno va
# para adelante justo cuando el otro se queda.
#
# El truco del cansancio: velocidad_final es MENOR que
# velocidad_inicial. El codigo de mas abajo va llevando la velocidad
# de una a la otra durante el ultimo tramo - como aca va de 29 a 20,
# en vez de acelerar, se apaga de a poco. No hizo falta codigo nuevo.
export var velocidad_inicial = 29.0
export var velocidad_final = 20.0
# CORREGIDO - antes esto era FRACCION DE LA DISTANCIA TOTAL (65%),
# y en carreras largas eso significaba arrancar el remate miles de
# metros antes de tiempo. Ahora es una distancia REAL fija: el
# remate arranca a distancia_ultimo_tramo metros de la meta, sin
# importar la distancia total de la carrera, como en una carrera de
# verdad.
# SUBIDO (de 400) - este numero ahora marca donde EMPIEZA A
# CANSARSE, no donde acelera. Con 400 se apagaba tan cerca de la
# meta que igual ganaba casi siempre. Con 900 el desgaste le empieza
# antes de la ultima curva, y le da tiempo al peloton (y al 9, que
# viene rematando) de alcanzarlo - que es la carrera que se quiere
# ver. (En _ready este numero tambien se mueve al azar, entre 720 y
# 1125, para que no se apague siempre en el mismo lugar.)
export var distancia_ultimo_tramo = 900.0
export var variacion_maxima = 2.0
export var separacion_lateral = 32.0 setget set_separacion_lateral

# CORREGIDO - con factor 0.6 y tope 14, apenas sacaba un poco de
# ventaja el sistema de agrupacion le pegaba un frenazo de hasta 14
# para devolverlo al grupo. O sea que un puntero no podia existir:
# el sistema no lo dejaba irse adelante nunca.
# Con 0.2 y tope 8 el tiron es mucho mas suave: se va como 35 metros
# adelante y ahi se estabiliza. Suficiente para verse como puntero
# de verdad, sin desaparecer de pantalla.
# Si lo ves irse demasiado lejos, subi correccion_maxima de a 1.
# Si lo ves sin poder despegarse del grupo, bajala.
export var factor_agrupacion = 0.2
export var correccion_maxima = 8.0

# NUEVO - la correccion de peloton (ver _velocidad_con_peloton mas abajo)
# se aplicaba de golpe, cuadro a cuadro, sin suavizado. Este numero
# controla que tan rapido esa correccion se acerca a su valor objetivo
# en vez de saltar directo (mismo estilo que velocidad_suavizado, mas
# abajo). Mas alto = reacciona mas rapido pero mas brusco. Mas bajo =
# mas suave pero tarda mas en corregir. Valor de arranque para probar.
export var correccion_suavizado = 3.0

# --- REGLA 3 - busqueda de la baranda (rediseno: real, con
# adelantamientos seguros - ver GestorNivel.obtener_h_offset_hacia_baranda) ---
export var velocidad_ajuste_lateral = 2.0

# NUEVO - antes, una vez terminada la espera y el kick, cada vez que
# tocaba cambiar de ritmo la velocidad saltaba de golpe al numero
# nuevo. Ahora ese numero nuevo queda guardado en velocidad_objetivo,
# y velocidad_actual se va acercando a el de a poco cada cuadro
# (mismo estilo que ya usa h_offset con velocidad_ajuste_lateral para
# la baranda) - se ve como un cambio de ritmo, no como un salto.
export var velocidad_suavizado = 1.5

var velocidad_actual = 23.0
var velocidad_objetivo = 23.0
var tiempo_hasta_cambio = 0.0
var _rotacion_calibrada = false
var _calibracion_rotacion = 0.0
var _correccion_actual = 0.0

func _ready():
	h_offset = separacion_lateral
	# CORRECCION: rotacion 3D completa de PathFollow puede
	# volverse inestable en curvas cerradas y hacer que el
	# caballo se incline/gire de golpe. La pista es plana, con
	# rotar en el eje vertical (Y) alcanza y es estable.
	rotation_mode = PathFollow.ROTATION_Y
	randomize()
	# "Forma del dia": variacion bien amplia al azar, distinta cada
	# carrera - para que se formen huecos reales entre caballos y no
	# sea siempre el mismo patron.
	var forma_del_dia = rand_range(0.78, 1.25)
	distancia_ultimo_tramo *= rand_range(0.8, 1.25)
	velocidad_inicial *= forma_del_dia
	velocidad_final *= forma_del_dia
	if GestorNivel:
		var extra = GestorNivel.obtener_extra_velocidad_rivales()
		velocidad_inicial += extra
		velocidad_final += extra
		GestorNivel.registrar_corredor(self)
	velocidad_actual = velocidad_inicial
	velocidad_objetivo = velocidad_inicial

func set_separacion_lateral(valor):
	separacion_lateral = valor
	h_offset = valor

func _process(delta):
	_actualizar_busqueda_baranda(delta)

	# NUEVO - ya no se mide en fraccion de la carrera, se mide en
	# metros reales que faltan para la meta, para que el remate
	# siempre arranque a la misma distancia real de la llegada, sin
	# importar si la carrera es de 800m o de 3000m.
	var recorrido = 0.0
	if GestorNivel:
		recorrido = GestorNivel.obtener_recorrido(self)
	var distancia_total = 0.0
	if ConfiguracionCarrera:
		distancia_total = ConfiguracionCarrera.distancia_metros
	var distancia_restante = distancia_total - recorrido

	if distancia_total <= 0.0 or distancia_restante > distancia_ultimo_tramo:
		velocidad_actual = velocidad_inicial
	elif distancia_restante > 0.0:
		var progreso = 1.0 - (distancia_restante / distancia_ultimo_tramo)
		velocidad_actual = lerp(velocidad_inicial, velocidad_final, progreso)
	else:
		tiempo_hasta_cambio -= delta
		if tiempo_hasta_cambio <= 0:
			velocidad_objetivo = velocidad_final + rand_range(-variacion_maxima, variacion_maxima)
			tiempo_hasta_cambio = rand_range(1.5, 3.5)
		velocidad_actual = lerp(velocidad_actual, velocidad_objetivo, clamp(velocidad_suavizado * delta, 0.0, 1.0))

	offset += _velocidad_con_peloton(delta) * delta

	_corregir_rumbo()

# CORREGIDO - mismo bug que se encontro en el caballo del jugador:
# el giro automatico de Godot (rotation_mode = ROTATION_Y) gira BIEN
# dentro de cada curva, pero el punto de PARTIDA de ese giro se corre
# un poco cada vez que el caballo pasa por la costura donde el ovalo
# se vuelve a unir consigo mismo. Se deja el sistema de Godot
# PRENDIDO (lo necesita h_offset para saber hacia donde es "el
# costado" de la pista), y se corrige el numero final cada cuadro,
# calculado mirando la pista real un poco mas adelante. Como se
# recalcula de cero cada vez, no tiene forma de irse corriendo vuelta
# tras vuelta.
func _corregir_rumbo():
	var camino = get_parent()
	if not camino or not ("curve" in camino) or not camino.curve:
		return
	var longitud_total = camino.curve.get_baked_length()
	if longitud_total <= 0:
		return
	var offset_actual = fposmod(offset, longitud_total)
	var offset_siguiente = fposmod(offset_actual + 1.0, longitud_total)
	var p1 = camino.curve.interpolate_baked(offset_actual)
	var p2 = camino.curve.interpolate_baked(offset_siguiente)
	var direccion = (p2 - p1).normalized()
	if direccion.length_squared() <= 0.0001:
		return
	var rumbo = rad2deg(atan2(direccion.x, direccion.z))
	if not _rotacion_calibrada:
		_calibracion_rotacion = rotation_degrees.y - rumbo
		_rotacion_calibrada = true
	rotation_degrees.y = rumbo + _calibracion_rotacion

# Si va muy adelante afloja, si va muy atras aprieta.
# NUEVO - antes esta correccion se aplicaba de golpe, cuadro a cuadro,
# sin ningun suavizado (a diferencia del cambio de ritmo, que ya usa
# velocidad_suavizado). Ahora se calcula la correccion "objetivo" igual
# que antes, pero _correccion_actual se va acercando a ella de a poco
# cada cuadro, usando correccion_suavizado (ver export var mas arriba).
func _velocidad_con_peloton(delta) -> float:
	if not GestorNivel:
		return velocidad_actual
	var diferencia = GestorNivel.obtener_offset_promedio() - offset
	var factor = factor_agrupacion * GestorNivel.obtener_factor_relajacion()
	var correccion_objetivo = clamp(diferencia * factor, -correccion_maxima, correccion_maxima)
	_correccion_actual = lerp(_correccion_actual, correccion_objetivo, clamp(correccion_suavizado * delta, 0.0, 1.0))
	return max(0.0, velocidad_actual + _correccion_actual)

func _actualizar_busqueda_baranda(delta):
	if ConfiguracionCarrera and ConfiguracionCarrera.modo_recta:
		return

	var camino = get_parent()
	var en_recta = camino and camino.has_method("es_zona_recta") and camino.es_zona_recta(offset)
	if not en_recta:
		# NUEVO - antes, en curva, esta funcion no hacia nada y
		# h_offset quedaba congelado tal cual estaba al entrar. Si
		# dos caballos no habian terminado de separarse en la recta,
		# se quedaban pegados/montados toda la curva. Ahora, en
		# curva, NO se busca la baranda (eso descarrilo caballos en
		# un intento anterior) pero SI se los separa si quedaron
		# demasiado pegados.
		if GestorNivel:
			h_offset = GestorNivel.separar_si_esta_pegado(self, h_offset, velocidad_ajuste_lateral, delta)
		return

	var objetivo = separacion_lateral
	if GestorNivel:
		objetivo = GestorNivel.obtener_h_offset_hacia_baranda(self)
	h_offset = lerp(h_offset, objetivo, clamp(velocidad_ajuste_lateral * delta, 0.0, 1.0))
