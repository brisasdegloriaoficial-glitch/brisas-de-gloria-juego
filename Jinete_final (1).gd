extends Spatial

# =====================================================================
#  JINETE MONTADO - version con huesos
# ---------------------------------------------------------------------
#  El modelo Jinete.glb NO trae animacion de montado: su animacion
#  "ArmatureAction_Armature" tiene 123 canales pero todos con 2
#  fotogramas iguales, o sea CERO movimiento. Este script mueve los
#  huesos directamente desde Godot para que el jinete cabalgue.
#
#  TODOS los valores se ajustan desde el Inspector, a ojo.
#
#  IMPORTANTE - los valores de POSTURA BASE arrancan todos en 0 a
#  proposito, para que al pegar el script el jinete se vea igual que
#  antes y nada se rompa. Vos los vas moviendo de a poco hasta
#  sentarlo bien (manos en las riendas, pies en los estribos).
#
#  Si un valor mueve el hueso para un lado raro, probá el mismo
#  numero en otro de los tres casilleros (x, y, z) del Vector3.
# =====================================================================


# --- ENCENDIDO GENERAL ---
export var activar_montado = true

# Si un gesto (arreo, latigo, frenar, cambio de mano) se esta
# reproduciendo, este script suelta los brazos y la cadera para no
# pisar la animacion. Dejalo en true.
export var respetar_gestos = true


# --- RITMO DEL CABALGUE ---
# El galope del caballo dura 0,5 segundos, o sea 2 ciclos por segundo.
# Por eso frecuencia_base arranca en 2.0: para que el jinete suba y
# baje al mismo ritmo que las patas del caballo.
export var frecuencia_base = 2.0

# Cuanto se acelera el ritmo segun la velocidad del caballo.
# Arranca en 0 para que quede clavado al galope. Cuando sincronicemos
# el galope del caballo (paso 2), este numero va a servir.
export var frecuencia_por_velocidad = 0.0


# --- MOVIMIENTO DEL CICLO (lo que se mueve todo el tiempo) ---
export var amplitud_cadera_grados = 5.0
export var amplitud_torso_grados = 3.0
export var amplitud_cabeza_grados = 2.0
export var amplitud_brazos_grados = 6.0
export var amplitud_piernas_grados = 1.5

# Los brazos acompañan el cuello del caballo, van medio ciclo
# corridos respecto a la cadera. 0.5 = medio ciclo.
export var desfase_brazos = 0.5

# Eje sobre el que oscila cada grupo. Si el movimiento se ve de
# costado en vez de adelante-atras, cambiá estos por Vector3.UP,
# Vector3.BACK, Vector3.RIGHT, etc.
export var eje_cadera = Vector3.RIGHT
export var eje_torso = Vector3.RIGHT
export var eje_brazos = Vector3.RIGHT
export var eje_piernas = Vector3.RIGHT


# --- POSTURA BASE: TRONCO ---
export var postura_cadera = Vector3.ZERO
export var postura_cintura = Vector3.ZERO
export var postura_torso_bajo = Vector3.ZERO
export var postura_torso_alto = Vector3.ZERO
export var postura_cabeza = Vector3.ZERO

# --- POSTURA BASE: BRAZOS (manos a las riendas) ---
export var postura_brazo_izq = Vector3.ZERO
export var postura_antebrazo_izq = Vector3.ZERO
export var postura_mano_izq = Vector3.ZERO
export var postura_brazo_der = Vector3.ZERO
export var postura_antebrazo_der = Vector3.ZERO
export var postura_mano_der = Vector3.ZERO

# --- POSTURA BASE: PIERNAS (pies a los estribos) ---
export var postura_muslo_izq = Vector3.ZERO
export var postura_pantorrilla_izq = Vector3.ZERO
export var postura_pie_izq = Vector3.ZERO
export var postura_muslo_der = Vector3.ZERO
export var postura_pantorrilla_der = Vector3.ZERO
export var postura_pie_der = Vector3.ZERO


# --- BALANCEO VIEJO DEL NODO ENTERO ---
# Es el que ya tenias. Ahora el trabajo real lo hacen los huesos, asi
# que esto queda bajito solo para dar un poco de vida extra.
# Ponelo en 0 si te molesta.
export var amplitud_cabeceo_grados = 1.5
export var amplitud_balanceo_grados = 0.8
export var eje_cabeceo = Vector3.RIGHT
export var eje_balanceo = Vector3.BACK


# --- SENTARLO EN EL CENTRO DEL LOMO ---
# El jinete cuelga de un hueso de la columna del caballo, y ese hueso
# no esta exactamente en el centro. Con esto lo corres a mano.
# Los tres numeros van en las coordenadas del PROPIO jinete:
#   x = de costado (izquierda / derecha)
#   y = de altura  (arriba / abajo)
#   z = de adelante hacia atras
# Si un numero lo mueve para un lado que no esperabas, probá el mismo
# valor en otro de los tres casilleros. Movelo de a 0.1.
export var corrimiento_jinete = Vector3.ZERO


# --- LOS DIEZ JINETES COPIAN AL DEL JUGADOR ---
# Todo se toca en UN solo lugar: el nodo Jinete que cuelga del caballo
# de Enrutador_Caballo1. Los otros nueve se lo copian al arrancar.
export var copiar_del_jugador = true


# --- SUAVIDAD DE LOS GESTOS ---
# Cuando suena un gesto (arreo, latigo, frenar, cambio de mano), el
# mando de los brazos pasaba del script a la animacion de un cuadro
# al otro, de golpe, y volvia igual de golpe al terminar. Eso es lo
# que se veia tosco. Ahora las dos poses se mezclan.
#
# Alto = el traspaso es mas rapido y mas marcado.
# Bajo = mas suave, pero el gesto tarda mas en verse entero.
# 8 esta bien para el arreo. Si todavia te patea, bajalo a 5.
export var suavizado_gesto = 8.0

# Velocidad a la que corren los gestos. 1 = como estan hechos.
# 0.8 los hace mas lentos y calmos, 1.3 mas secos y rapidos.
export var velocidad_de_los_gestos = 1.0

# ============================================================
# ARREO HECHO POR EL SCRIPT
# ============================================================
# La animacion "Arreo" que vino de Blender mueve muy poco y dura
# medio segundo. Con esto el arreo lo dibuja el script: empuje
# rapido hacia adelante y vuelta lenta, que es como se ve de
# verdad. La animacion vieja sigue sonando por debajo (para no
# romper el conteo de arreos), pero no se ve.
#
# Si lo destildas, vuelve todo a como estaba antes.
export var arreo_propio = true
export var arreo_animacion = "Arreo"
export var arreo_duracion = 0.42          # cuanto dura el empuje entero, en segundos
export var arreo_amplitud_grados = 38.0   # cuanto empuja el brazo
export var arreo_eje = Vector3.RIGHT      # probar RIGHT / UP / BACK si empuja para el lado que no es
export var arreo_ataque = 0.32            # 0.2 = golpe seco, 0.5 = parejo
export var arreo_antebrazo = 0.6          # cuanto acompana el antebrazo (0 a 1)
export var arreo_torso_grados = 7.0       # cuanto se tira el cuerpo adelante


# --- QUIETO EN LA GATERA ---
# El caballo ya se congela solo cuando no avanza (Caballo_final.gd),
# pero el jinete seguia meneandose por su cuenta adentro del aparato.
# Con esto el jinete mira la misma velocidad que mira el caballo y se
# acomoda en su postura base mientras no se corre.
export var quieto_en_la_gatera = true

# Debajo de esta velocidad se considera que el caballo esta parado.
# Es el mismo numero que tiene el caballo en su propio Inspector.
export var velocidad_minima_para_correr = 1.0

# Que tan rapido se apaga y se prende el meneo. Alto = corta de
# golpe. Bajo = se va apagando de a poco. 6 queda natural: no
# congela en seco, se sienta.
export var suavizado_parada = 6.0


# --- DIAGNOSTICO ---
# Prendelo una vez para ver por consola si encontro el esqueleto y
# todos los huesos. Despues apagalo.
export var mostrar_diagnostico = false


var _transform_base = Transform()
var _fase = 0.0
var _punto_referencia = null
var _offset_anterior = 0.0
var _velocidad_actual = 0.0
var _vivacidad = 1.0
var _mezcla_gesto = 0.0
var _arreo_t = -1.0
var _pose_del_gesto = {}

var _esqueleto = null
var _animador = null
var _huesos = {}

# Nombres tal cual vienen adentro del Jinete.glb.
const NOMBRES_HUESOS = {
	"cadera": "Hip",
	"cintura": "Waist",
	"torso_bajo": "Spine01",
	"torso_alto": "Spine02",
	"cabeza": "Head",
	"brazo_izq": "L_Upperarm",
	"antebrazo_izq": "L_Forearm",
	"mano_izq": "L_Hand",
	"brazo_der": "R_Upperarm",
	"antebrazo_der": "R_Forearm",
	"mano_der": "R_Hand",
	"muslo_izq": "L_Thigh",
	"pantorrilla_izq": "L_Calf",
	"pie_izq": "L_Foot",
	"muslo_der": "R_Thigh",
	"pantorrilla_der": "R_Calf",
	"pie_der": "R_Foot"
}

# Huesos que tocan los gestos (arreo, latigo, frenar, cambio de mano).
# Mientras un gesto suena, este script no los toca.
const HUESOS_DE_GESTOS = [
	"cadera", "brazo_izq", "antebrazo_izq", "mano_izq",
	"brazo_der", "antebrazo_der", "mano_der"
]


func _ready():
	# Que este script corra DESPUES del AnimationPlayer, si no el
	# AnimationPlayer nos pisa las poses de los huesos.
	process_priority = 100

	_punto_referencia = _buscar_pathfollow(self)
	if _punto_referencia:
		_offset_anterior = _punto_referencia.offset

	_copiar_del_jugador()

	# La postura de arranque, ya con el corrimiento aplicado.
	# El corrimiento se suma sobre los ejes del propio jinete, para
	# que "de costado" sea de verdad su costado y no el del hueso.
	_transform_base = transform
	if corrimiento_jinete != Vector3.ZERO:
		var ejes = _transform_base.basis.orthonormalized()
		_transform_base.origin += (ejes.x * corrimiento_jinete.x
			+ ejes.y * corrimiento_jinete.y
			+ ejes.z * corrimiento_jinete.z)

	_esqueleto = get_node_or_null("Armature001/Skeleton")
	if _esqueleto == null:
		_esqueleto = _buscar_esqueleto(self)

	_animador = get_node_or_null("AnimationPlayer")

	# La animacion base del jinete esta VACIA (2 fotogramas iguales en
	# los 123 canales). Si la dejamos sonando, pisa cada cuadro las
	# poses que escribimos aca. La frenamos.
	if _animador:
		if _animador.is_playing() and _animador.current_animation == "ArmatureAction_Armature":
			_animador.stop(false)

	if _esqueleto:
		for clave in NOMBRES_HUESOS:
			var idx = _esqueleto.find_bone(NOMBRES_HUESOS[clave])
			if idx >= 0:
				_huesos[clave] = idx

	if mostrar_diagnostico:
		if _esqueleto == null:
			print("[BDG-Jinete] NO se encontro el esqueleto en ", name)
		else:
			print("[BDG-Jinete] esqueleto OK en ", name,
				" | huesos encontrados = ", _huesos.size(),
				" de ", NOMBRES_HUESOS.size())
			for clave in NOMBRES_HUESOS:
				if not _huesos.has(clave):
					print("   FALTA el hueso: ", NOMBRES_HUESOS[clave])


# Perillas que los nueve rivales le copian al jinete del jugador.
const PERILLAS_COPIADAS = [
	"corrimiento_jinete", "activar_montado", "respetar_gestos",
	"frecuencia_base", "frecuencia_por_velocidad",
	"amplitud_cadera_grados", "amplitud_torso_grados", "amplitud_cabeza_grados",
	"amplitud_brazos_grados", "amplitud_piernas_grados", "desfase_brazos",
	"eje_cadera", "eje_torso", "eje_brazos", "eje_piernas",
	"postura_cadera", "postura_cintura", "postura_torso_bajo",
	"postura_torso_alto", "postura_cabeza",
	"postura_brazo_izq", "postura_antebrazo_izq", "postura_mano_izq",
	"postura_brazo_der", "postura_antebrazo_der", "postura_mano_der",
	"postura_muslo_izq", "postura_pantorrilla_izq", "postura_pie_izq",
	"postura_muslo_der", "postura_pantorrilla_der", "postura_pie_der",
	"amplitud_cabeceo_grados", "amplitud_balanceo_grados",
	"eje_cabeceo", "eje_balanceo",
	"suavizado_gesto", "velocidad_de_los_gestos",
	"quieto_en_la_gatera", "velocidad_minima_para_correr", "suavizado_parada"
]


func _copiar_del_jugador():
	if not copiar_del_jugador:
		return
	if _punto_referencia == null or _punto_referencia.name == "Enrutador_Caballo1":
		return
	var pista = _punto_referencia.get_parent()
	if pista == null:
		return
	var maestro = pista.get_node_or_null(
		"Enrutador_Caballo1/Caballo/Armature/Skeleton/BoneAttachment/Jinete")
	if maestro == null or maestro == self:
		return
	for perilla in PERILLAS_COPIADAS:
		set(perilla, maestro.get(perilla))
	if mostrar_diagnostico:
		print("[BDG-Jinete] ", _punto_referencia.name, " copio las perillas del jinete del jugador")


func _buscar_pathfollow(nodo):
	var actual = nodo.get_parent()
	while actual:
		if actual is PathFollow:
			return actual
		actual = actual.get_parent()
	return null


func _buscar_esqueleto(nodo):
	for hijo in nodo.get_children():
		if hijo is Skeleton:
			return hijo
		var encontrado = _buscar_esqueleto(hijo)
		if encontrado:
			return encontrado
	return null


func _process(delta):
	# --- velocidad real del caballo ---
	if _punto_referencia:
		var avance = _punto_referencia.offset - _offset_anterior
		_offset_anterior = _punto_referencia.offset
		# Al cruzar el empalme del circuito el offset pega un salto
		# enorme. Ese cuadro se descarta, igual que en el caballo.
		if delta > 0 and abs(avance) < 100.0:
			_velocidad_actual = abs(avance) / delta

	# --- se para o se mueve ---
	# _vivacidad va de 0 (quieto en la gatera) a 1 (galopando).
	# Multiplica TODO el meneo, asi que en 0 el jinete queda sentado
	# en su postura base, sin temblar.
	var deseada = 1.0
	if quieto_en_la_gatera and _punto_referencia and _velocidad_actual < velocidad_minima_para_correr:
		deseada = 0.0
	_vivacidad = lerp(_vivacidad, deseada, clamp(suavizado_parada * delta, 0.0, 1.0))

	var frecuencia = frecuencia_base + _velocidad_actual * frecuencia_por_velocidad
	# Con el caballo parado el reloj tampoco avanza: asi cuando
	# largan, el jinete retoma el ciclo donde lo dejo.
	if _vivacidad > 0.01:
		_fase += frecuencia * delta * 2.0 * PI

	# --- balanceo suave del nodo entero (el que ya tenias) ---
	var cabeceo = deg2rad(amplitud_cabeceo_grados) * sin(_fase) * _vivacidad
	var balanceo = deg2rad(amplitud_balanceo_grados) * sin(_fase * 0.5) * _vivacidad
	var oscilacion = Basis().rotated(eje_cabeceo, cabeceo).rotated(eje_balanceo, balanceo)
	transform = _transform_base * Transform(oscilacion, Vector3.ZERO)

	# --- movimiento de huesos ---
	if not activar_montado or _esqueleto == null:
		return

	var hay_gesto = false
	if respetar_gestos and _animador and _animador.is_playing():
		hay_gesto = true

	if _animador and hay_gesto:
		_animador.playback_speed = velocidad_de_los_gestos

	# --- arreo propio: arranca el reloj cuando suena la animacion ---
	if arreo_propio and _animador and _animador.is_playing() \
			and _animador.current_animation == arreo_animacion:
		if _arreo_t < 0.0:
			_arreo_t = 0.0
		# Los brazos son mios durante el arreo, no de la animacion.
		hay_gesto = false

	var arreo = 0.0
	if _arreo_t >= 0.0:
		arreo = _curva_arreo(clamp(_arreo_t, 0.0, 1.0))
		_arreo_t += delta / max(0.05, arreo_duracion)
		if _arreo_t >= 1.0:
			_arreo_t = -1.0

	# 0 = los brazos son mios. 1 = los brazos son del gesto.
	# Nunca salta: va y viene de a poco entre esos dos.
	var deseada_gesto = 1.0 if hay_gesto else 0.0
	_mezcla_gesto = lerp(_mezcla_gesto, deseada_gesto, clamp(suavizado_gesto * delta, 0.0, 1.0))

	var s = sin(_fase) * _vivacidad
	var s_brazos = sin(_fase + desfase_brazos * 2.0 * PI) * _vivacidad
	var s_lento = sin(_fase * 0.5) * _vivacidad

	# Tronco
	_poner("cadera", postura_cadera, eje_cadera, amplitud_cadera_grados * s, hay_gesto)
	_poner("cintura", postura_cintura, eje_torso, amplitud_torso_grados * s * 0.6, hay_gesto)
	_poner("torso_bajo", postura_torso_bajo, eje_torso, amplitud_torso_grados * s, hay_gesto, arreo_eje, arreo_torso_grados * arreo)
	_poner("torso_alto", postura_torso_alto, eje_torso, amplitud_torso_grados * s * 0.5, hay_gesto, arreo_eje, arreo_torso_grados * arreo * 0.5)
	_poner("cabeza", postura_cabeza, eje_torso, amplitud_cabeza_grados * s_lento, hay_gesto)

	# Brazos
	_poner("brazo_izq", postura_brazo_izq, eje_brazos, amplitud_brazos_grados * s_brazos, hay_gesto, arreo_eje, arreo_amplitud_grados * arreo)
	_poner("antebrazo_izq", postura_antebrazo_izq, eje_brazos, amplitud_brazos_grados * s_brazos * 0.5, hay_gesto, arreo_eje, arreo_amplitud_grados * arreo * arreo_antebrazo)
	_poner("mano_izq", postura_mano_izq, eje_brazos, 0.0, hay_gesto)
	_poner("brazo_der", postura_brazo_der, eje_brazos, amplitud_brazos_grados * s_brazos, hay_gesto, arreo_eje, arreo_amplitud_grados * arreo)
	_poner("antebrazo_der", postura_antebrazo_der, eje_brazos, amplitud_brazos_grados * s_brazos * 0.5, hay_gesto, arreo_eje, arreo_amplitud_grados * arreo * arreo_antebrazo)
	_poner("mano_der", postura_mano_der, eje_brazos, 0.0, hay_gesto)

	# Piernas (los gestos no las tocan, siempre se mueven)
	_poner("muslo_izq", postura_muslo_izq, eje_piernas, amplitud_piernas_grados * s, hay_gesto)
	_poner("pantorrilla_izq", postura_pantorrilla_izq, eje_piernas, amplitud_piernas_grados * s * 0.5, hay_gesto)
	_poner("pie_izq", postura_pie_izq, eje_piernas, 0.0, hay_gesto)
	_poner("muslo_der", postura_muslo_der, eje_piernas, amplitud_piernas_grados * s, hay_gesto)
	_poner("pantorrilla_der", postura_pantorrilla_der, eje_piernas, amplitud_piernas_grados * s * 0.5, hay_gesto)
	_poner("pie_der", postura_pie_der, eje_piernas, 0.0, hay_gesto)


# Arma la pose final de un hueso: postura base + oscilacion del ciclo.
func _poner(clave, postura_grados, eje, grados_ciclo, hay_gesto, eje2 = Vector3.RIGHT, grados2 = 0.0):
	if not _huesos.has(clave):
		return

	var indice = _huesos[clave]
	var es_de_gesto = HUESOS_DE_GESTOS.has(clave)

	# Este script corre DESPUES del AnimationPlayer, asi que mientras
	# el gesto suena, lo que hay guardado en el hueso es justamente la
	# pose de la animacion. La copiamos para poder volver de a poco
	# cuando el gesto termine (ahi el AnimationPlayer ya no escribe
	# nada y no habria de donde sacarla).
	if es_de_gesto and hay_gesto:
		_pose_del_gesto[clave] = _esqueleto.get_bone_pose(indice)

	var base = Basis(Vector3(
		deg2rad(postura_grados.x),
		deg2rad(postura_grados.y),
		deg2rad(postura_grados.z)))

	if abs(grados_ciclo) > 0.0001:
		base = base.rotated(eje.normalized(), deg2rad(grados_ciclo))

	# Empuje del arreo propio (se suma encima de todo lo demas).
	if abs(grados2) > 0.0001:
		base = base.rotated(eje2.normalized(), deg2rad(grados2))

	var pose_propia = Transform(base, Vector3.ZERO)

	# Mezcla entre mi pose y la del gesto.
	if es_de_gesto and _mezcla_gesto > 0.001 and _pose_del_gesto.has(clave):
		_esqueleto.set_bone_pose(indice,
			pose_propia.interpolate_with(_pose_del_gesto[clave], _mezcla_gesto))
		return

	_esqueleto.set_bone_pose(indice, pose_propia)


# Empuje rapido y vuelta lenta. Devuelve 0 -> 1 -> 0.
func _curva_arreo(t):
	if t < arreo_ataque:
		return sin((t / max(0.001, arreo_ataque)) * PI * 0.5)
	var u = (t - arreo_ataque) / max(0.001, 1.0 - arreo_ataque)
	return cos(u * PI * 0.5)
