extends Spatial

export(NodePath) var camara_partida_path
export(NodePath) var camara_aerea_path
export(NodePath) var camara_primera_persona_path
export(NodePath) var camara_llegada_path
export(NodePath) var jockey_path
export(NodePath) var enrutador_jugador_path

# Metros que le tienen que quedar al caballo QUE VA PRIMERO para
# que se active la camara de llegada. Ejemplo: 800 = se activa
# cuando el puntero entra en la recta final (aprox. al salir de la
# ultima curva). Subilo si se activa muy tarde, bajalo si se activa
# muy temprano - es distancia, no tiempo, asi que no depende de la
# velocidad de nadie.
export var distancia_activacion_llegada = 800.0

var camaras_carrera = []
var indice_actual = 0

# --- CAMBIO: antes habia una sola bandera (_carrera_terminada) que
# significaba "ya se activo la camara de llegada, no revisar nada
# mas". Ahora hay 3 fases separadas porque agregamos un paso nuevo:
# la camara de llegada se queda prendida, fija en la meta, viendo
# pasar a TODOS los caballos - y recien se apaga (fase "terminada")
# cuando el ULTIMO ya cruzo, no cuando cruza el jugador ni el lider.
# "carrera"   = carrera en curso, revisando si hay que activar la
#               camara de llegada.
# "llegada"   = camara de llegada activa y fija en la meta, viendo
#               pasar a los caballos que van llegando.
# "terminada" = ya paso el ultimo, camara de llegada apagada, no se
#               vuelve a tocar nada mas.
var _fase = "carrera"

var jockey: Node
var enrutador_jugador: Node


func _ready():
	if camara_partida_path:
		camaras_carrera.append(get_node(camara_partida_path))
	if camara_aerea_path:
		camaras_carrera.append(get_node(camara_aerea_path))
	if camara_primera_persona_path:
		camaras_carrera.append(get_node(camara_primera_persona_path))
	if jockey_path:
		jockey = get_node(jockey_path)
	if enrutador_jugador_path:
		enrutador_jugador = get_node(enrutador_jugador_path)

	if camaras_carrera.size() > 0:
		_activar_camara(camaras_carrera[0])


func _process(delta):
	if _fase == "terminada":
		return

	if _fase == "llegada":
		# Ya esta la camara de llegada prendida y fija en la meta,
		# viendo pasar a todos. Solo falta saber cuando apagarla.
		if GestorNivel and GestorNivel.todos_terminaron():
			_apagar_camara_llegada()
		return

	# --- fase "carrera" ---
	if jockey and jockey.carrera_terminada:
		_forzar_camara_llegada()
		return

	if _falta_poco_para_llegar():
		_forzar_camara_llegada()

	# Se revisa asi (en vez de _unhandled_input) porque los botones
	# tactiles de Android simulan la pulsacion con Input.action_press(),
	# y esas pulsaciones simuladas no generan un evento real que
	# _unhandled_input pueda recibir - pero si quedan disponibles para
	# Input.is_action_just_pressed(), que es lo que usa el resto de
	# los controles del juego (arreo, girar, latigazo, cambiar_mano).
	if Input.is_action_just_pressed("cambiar_camara"):
		_siguiente_camara()


func _falta_poco_para_llegar() -> bool:
	if not GestorNivel:
		return false
	# Por ESPACIO: cuanto le falta al que va primero (no al jugador)
	# para cruzar la meta. Nada de velocidad ni segundos.
	var restante = GestorNivel.obtener_distancia_lider_hasta_meta()
	if restante < 0.0:
		return false
	return restante <= distancia_activacion_llegada


func _forzar_camara_llegada():
	_fase = "llegada"
	_activar_camara(get_node_or_null(camara_llegada_path))


func _apagar_camara_llegada():
	# NUEVO - ya paso el ultimo caballo. Se apaga la camara de
	# llegada (vuelve a la camara aerea) y se deja todo quieto -
	# aca es donde mas adelante puede engancharse un video de
	# resultado en vez de simplemente cambiar de camara.
	_fase = "terminada"
	if camaras_carrera.size() > 1:
		_activar_camara(camaras_carrera[1])
	elif camaras_carrera.size() > 0:
		_activar_camara(camaras_carrera[0])


func _siguiente_camara():
	if camaras_carrera.size() == 0:
		return
	indice_actual = (indice_actual + 1) % camaras_carrera.size()
	_activar_camara(camaras_carrera[indice_actual])


func _activar_camara(camara):
	if camara:
		camara.current = true
