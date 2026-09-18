tool
extends PathFollow

export var separacion_lateral = 5.0 setget set_separacion_lateral
export var velocidad_avance = 20.0
export var avanzar = true

# NUEVO - el jugador ahora tambien persigue al peloton, con el mismo
# mecanismo que ya usan los 9 rivales (ver _velocidad_con_peloton mas
# abajo). Sin arrear ni usar el latigo, esto evita que te quedes
# clavado lejisimo del grupo - te vas acercando de a poco al promedio,
# como en la vida real. Mas suave que en los rivales (factor y tope
# mas bajos) para que arrear siga siendo lo que de verdad te hace
# ganar terreno, no algo automatico.
export var factor_agrupacion = 0.3
export var correccion_maxima = 8.0
export var correccion_suavizado = 3.0

var _rotacion_calibrada = false
var _calibracion_rotacion = 0.0
var _correccion_actual = 0.0

func _ready():
	h_offset = separacion_lateral
	# Se deja PRENDIDO siempre (a diferencia del intento anterior) -
	# lo necesita h_offset para saber hacia donde es "el costado" de
	# la pista, que es lo que mueven las flechas izquierda/derecha.
	# Apagarlo desconectaba las flechas sin querer.
	rotation_mode = PathFollow.ROTATION_Y
	if not Engine.editor_hint and GestorNivel:
		GestorNivel.reiniciar_carrera()
		GestorNivel.registrar_corredor(self)

func set_separacion_lateral(valor):
	separacion_lateral = valor
	h_offset = valor

func _process(delta):
	if Engine.editor_hint:
		return
	if avanzar:
		offset += _velocidad_con_peloton(delta) * delta

	# CORREGIDO - confirmado con datos reales: el giro automatico de
	# Godot (rotation_mode = ROTATION_Y) gira BIEN dentro de cada
	# curva, pero el punto de PARTIDA de ese giro se corre un poco
	# cada vez que el caballo pasa por la costura donde el ovalo se
	# vuelve a unir consigo mismo.
	#
	# Ahora, en vez de apagar el sistema de Godot (eso rompia las
	# flechas), se lo deja prendido para que h_offset siga
	# funcionando, y se CORRIGE el numero final de rotation_degrees.y
	# cada cuadro, calculado mirando la pista real un poco mas
	# adelante. Como se recalcula de cero cada vez, no tiene forma de
	# irse corriendo vuelta tras vuelta.
	var camino = get_parent()
	if camino and "curve" in camino and camino.curve:
		var longitud_total = camino.curve.get_baked_length()
		if longitud_total > 0:
			var offset_actual = fposmod(offset, longitud_total)
			var offset_siguiente = fposmod(offset_actual + 1.0, longitud_total)
			var p1 = camino.curve.interpolate_baked(offset_actual)
			var p2 = camino.curve.interpolate_baked(offset_siguiente)
			var direccion = (p2 - p1).normalized()
			if direccion.length_squared() > 0.0001:
				var rumbo = rad2deg(atan2(direccion.x, direccion.z))
				if not _rotacion_calibrada:
					# En el primer cuadro de la carrera, el numero que
					# calcula Godot todavia no arrastra ningun error -
					# se usa ESE numero como referencia para calibrar
					# esta formula.
					_calibracion_rotacion = rotation_degrees.y - rumbo
					_rotacion_calibrada = true
				rotation_degrees.y = rumbo + _calibracion_rotacion


# Mismo mecanismo que usan los rivales (ver Enrutador_CaballoN.gd):
# si vas muy atras del promedio del peloton, empuja un poco para
# adelante; si vas muy adelante, afloja un poco. Se suaviza cuadro a
# cuadro (correccion_suavizado) para que no se sienta de golpe.
# velocidad_avance en si NO se toca aca - arreo y latigo lo siguen
# multiplicando/dividiendo como siempre, esto solo se suma encima al
# momento de mover.
func _velocidad_con_peloton(delta) -> float:
	if not GestorNivel:
		return velocidad_avance
	var diferencia = GestorNivel.obtener_offset_promedio() - offset
	var factor = factor_agrupacion * GestorNivel.obtener_factor_relajacion()
	var correccion_objetivo = clamp(diferencia * factor, -correccion_maxima, correccion_maxima)
	_correccion_actual = lerp(_correccion_actual, correccion_objetivo, clamp(correccion_suavizado * delta, 0.0, 1.0))
	return max(0.0, velocidad_avance + _correccion_actual)
