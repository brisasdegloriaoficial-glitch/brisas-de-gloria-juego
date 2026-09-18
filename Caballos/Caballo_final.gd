extends Spatial

# =====================================================================
#  CABALLO - tu animacion de Blender, con la pata izquierda pareja
# ---------------------------------------------------------------------
#  Este script NO reemplaza nada. Tu animacion corre tal cual la
#  hiciste. Lo unico que hace es AGRANDAR el recorrido de algunas
#  articulaciones, justo despues de que la animacion las acomoda.
#
#     1.0 = como la hiciste vos
#     2.3 = recorre 2,3 veces mas
#     0.0 = esa articulacion queda quieta
#
#  POR QUE 2.3 Y 2.6:
#  Medido hueso por hueso adentro del Caballo.glb, comparando la
#  pata delantera izquierda contra la derecha:
#
#        articulacion   izquierda   derecha   le falta
#        hombro             26          60     2,3 veces
#        codo               23          22     nada
#        rodilla            86          83     nada
#        pezuña             24          62     2,6 veces
#
#  O sea: el codo y la rodilla estan perfectos. Lo unico flojo es
#  el hombro y la pezuña, los dos extremos. Por eso esa pata no
#  estira ni apoya, y el caballo parece rengo.
#
#  OJO CON LOS NOMBRES: en el .glb los huesos se llaman
#  "tripo::0_Left_Limb_1", pero Godot no acepta los dos puntos y al
#  importar los cambia por dos guiones bajos. Aca van con guiones.
#  Igual hay busqueda de respaldo por si acaso.
#
#  Izquierda y derecha son las DEL CABALLO, como si fueras montado.
# =====================================================================


# --- ROTACIONES DEL MODELO (lo de siempre, sin cambios) ---
export var correccion_rotacion_y = 0.0
export var correccion_rotacion_x = 0.0
export var correccion_extra_vuelta_completa = 211.63


# --- INTERRUPTOR ---
# Apagalo y queda tu animacion sin ningun retoque.
export var emparejar_patas = true
export var copiar_del_jugador = true

# =====================================================================
#  DELANTERA IZQUIERDA - es la que hay que emparejar
# =====================================================================
export var del_izq_hombro = 2.3
export var del_izq_codo = 1.0
export var del_izq_rodilla = 1.0
export var del_izq_pezuna = 2.6

# CENTRO: corre la articulacion sin agrandar el movimiento.
# En grados. Positivo = hacia adelante, negativo = hacia atras.
# Es la perilla para adelantar la pata SIN levantarla.
export var del_izq_hombro_centro = 0.0
export var del_izq_codo_centro = 0.0
export var del_izq_rodilla_centro = 0.0
export var del_izq_pezuna_centro = 0.0

# MOMENTO: atrasa esa articulacion sola dentro del ciclo, de 0 a 1.
# 0.04 es un pelin. Es lo que da soltura: en un caballo real la
# rodilla no gira junto con el hombro, va un poco atras.
export var del_izq_hombro_momento = 0.0
export var del_izq_codo_momento = 0.0
export var del_izq_rodilla_momento = 0.0
export var del_izq_pezuna_momento = 0.0


# --- DELANTERA DERECHA - la sana, se deja como esta ---
export var del_der_hombro = 1.0
export var del_der_codo = 1.0
export var del_der_rodilla = 1.0
export var del_der_pezuna = 1.0

export var del_der_hombro_centro = 0.0
export var del_der_codo_centro = 0.0
export var del_der_rodilla_centro = 0.0
export var del_der_pezuna_centro = 0.0

export var del_der_hombro_momento = 0.0
export var del_der_codo_momento = 0.0
export var del_der_rodilla_momento = 0.0
export var del_der_pezuna_momento = 0.0


# --- TRASERA IZQUIERDA ---
# Tambien va mas floja que la derecha (89 grados contra 126), pero
# se nota mucho menos. La dejo en 1.0 para no tocar dos cosas a la
# vez. Si despues la queres emparejar, subi la cadera.
export var tras_izq_cadera = 1.0
export var tras_izq_muslo = 1.0
export var tras_izq_corva = 1.0
export var tras_izq_pezuna = 1.0

# --- TRASERA DERECHA ---
export var tras_der_cadera = 1.0
export var tras_der_muslo = 1.0
export var tras_der_corva = 1.0
export var tras_der_pezuna = 1.0


# =====================================================================
#  DESFASAR PATAS  (para que no caigan las dos juntas)
# =====================================================================
# Tu animacion trae el tiempo horneado adentro, asi que no se puede
# "atrasar" una pata con un multiplicador. Lo que hace el script es
# guardar tu galope en una tabla al arrancar y despues pedirle a esa
# pata la pose de OTRO instante del ciclo. Tu animacion no se toca.
#
# El numero es la parte del ciclo que se corre, de 0 a 1.
# 0.12 = un octavo de zancada mas tarde. 0 = sin corrimiento.
export var corrimiento_trasera_izquierda = 0.12
export var corrimiento_trasera_derecha = 0.0
export var corrimiento_delantera_izquierda = 0.0
export var corrimiento_delantera_derecha = 0.0


# =====================================================================
#  QUIETOS EN LA GATERA
# =====================================================================
# Mientras el caballo no avanza, la animacion se congela para que no
# galopen en el lugar adentro del aparato.
export var quieto_en_la_gatera = true
export var velocidad_minima_para_correr = 1.0

# En que momento del ciclo se congelan. Probá valores entre 0 y 0.5
# hasta encontrar el que mas se parezca a un caballo parado.
export var pose_de_espera = 0.0


# =====================================================================
#  QUE NO PAREZCA UN DESFILE
# =====================================================================
# Cada caballo arranca en un punto distinto del ciclo y con un ritmo
# apenas diferente, asi se van separando solos.
export var arranque_al_azar = true
export var variacion_de_ritmo = 0.08


# --- TOPE DE SEGURIDAD ---
# Por mas que subas los numeros, ninguna articulacion se va a
# torcer mas que esto. Evita que la pata se doble al reves.
export var tope_grados = 110.0


# --- RITMO SEGUN LA VELOCIDAD (opcional, viene APAGADO) ---
# Si lo prendes, tu animacion corre mas rapido cuando el caballo
# acelera y mas lento cuando afloja, en vez de ir siempre igual.
# Probalo aparte, DESPUES de que la pata este pareja.
export var sincronizar_ritmo = false
export var velocidad_referencia = 24.0
export var ritmo_minimo = 0.6
export var ritmo_maximo = 1.5
export var suavizado_ritmo = 4.0


# --- DIAGNOSTICO ---
# Viene prendido. Te dice por consola cuantos huesos encontro.
# Tienen que ser 16 de 16. Apagalo cuando confirmes.
export var mostrar_diagnostico = true


var _animador = null
var _esqueleto = null
var _punto_referencia = null
var _offset_anterior = 0.0
var _velocidad_actual = 0.0
var _ritmo_actual = 1.0
var _diagnostico_final_hecho = false
var _tabla = {}
var _largo_anim = 0.0
var _variacion = 1.0
var _parado = false
const MUESTRAS = 32

# Nombres tal como quedan DENTRO DE GODOT despues de importar.
# Cada pata va ordenada desde el cuerpo hacia el casco.
const PATAS = {
	"del_izq": ["bone_14", "tripo__0_Left_Limb_0", "tripo__0_Left_Limb_1", "tripo__0_Left_Limb_2"],
	"del_der": ["bone_10", "bone_11", "tripo__0_Right_Limb_0", "tripo__0_Right_Limb_1"],
	"tras_izq": ["bone_24", "tripo__1_Left_Limb_0", "tripo__1_Left_Limb_1", "tripo__1_Left_Limb_2"],
	"tras_der": ["bone_19", "tripo__1_Right_Limb_0", "tripo__1_Right_Limb_1", "tripo__1_Right_Limb_2"]
}

var _idx = {}
var _faltantes = []


func  _ready():
	_copiar_del_jugador()
	# Que este script corra DESPUES del AnimationPlayer. Si no, la
	# animacion nos pisa cada cuadro lo que escribimos.
	process_priority = 100

	rotation_degrees.y += correccion_rotacion_y
	rotation_degrees.x += correccion_rotacion_x

	if ConfiguracionCarrera and ConfiguracionCarrera.modo_vuelta_completa:
		rotation_degrees.y += correccion_extra_vuelta_completa

	# Tu animacion arranca y corre como siempre.
	_animador = get_node_or_null("AnimationPlayer")
	if _animador and _animador.has_animation("ArmatureAction_Armature"):
		_animador.get_animation("ArmatureAction_Armature").loop = true
		_animador.play("ArmatureAction_Armature")

	_punto_referencia = _buscar_pathfollow(self)
	if _punto_referencia:
		_offset_anterior = _punto_referencia.offset

	_esqueleto = get_node_or_null("Armature/Skeleton")
	if _esqueleto == null:
		_esqueleto = _buscar_esqueleto(self)

	var encontrados = 0
	if _esqueleto:
		for pata in PATAS:
			var lista = []
			for nombre in PATAS[pata]:
				var i = _buscar_hueso(nombre)
				lista.append(i)
				if i >= 0:
					encontrados += 1
				else:
					_faltantes.append(nombre)
			_idx[pata] = lista

	_armar_tabla()

	if _animador and arranque_al_azar:
		_variacion = 1.0 + rand_range(-variacion_de_ritmo, variacion_de_ritmo)
		if _largo_anim > 0.0:
			_animador.seek(randf() * _largo_anim, true)

	if mostrar_diagnostico and get_parent() and get_parent().name == "Enrutador_Caballo1":
		if _esqueleto == null:
			print("[BDG-Patas] NO se encontro el esqueleto en ", name)
		else:
			print("[BDG-Patas] ", name, " | huesos encontrados = ", encontrados, " de 16")
			if _faltantes.size() > 0:
				print("[BDG-Patas] FALTAN: ", _faltantes)
				print("[BDG-Patas] nombres reales: ", _listar_huesos())


func _process(delta):
	_medir_velocidad(delta)
	_controlar_gatera()
	_ajustar_ritmo(delta)
	if not _parado:
		_desfasar_patas()
	_emparejar()
	_diagnostico_una_vez()


# Congela la animacion mientras el caballo no avanza, para que no
# galopen en el lugar adentro del aparato de partida.
func _controlar_gatera():
	if not quieto_en_la_gatera or _animador == null:
		return
	if _velocidad_actual < velocidad_minima_para_correr:
		if not _parado:
			_parado = true
			_animador.seek(pose_de_espera, true)
			_animador.stop(false)
	else:
		if _parado:
			_parado = false
			_animador.play("ArmatureAction_Armature")


# Guarda tu animacion en una tabla, una sola vez al arrancar.
func _armar_tabla():
	if _animador == null or _esqueleto == null:
		return
	if not _animador.has_animation("ArmatureAction_Armature"):
		return
	_largo_anim = _animador.get_animation("ArmatureAction_Armature").length
	if _largo_anim <= 0.0:
		return
	var guardado = _animador.current_animation_position
	for pata in _idx:
		var filas = []
		for k in range(MUESTRAS):
			_animador.seek(_largo_anim * k / float(MUESTRAS), true)
			var fila = []
			for i in _idx[pata]:
				if i >= 0:
					fila.append(_esqueleto.get_bone_pose(i))
				else:
					fila.append(Transform())
			filas.append(fila)
		_tabla[pata] = filas
	_animador.seek(guardado, true)


# Le pide a una pata la pose de otro instante del ciclo.
func _desfasar_patas():
	_desfasar("tras_izq", corrimiento_trasera_izquierda)
	_desfasar("tras_der", corrimiento_trasera_derecha)
	_desfasar("del_izq", corrimiento_delantera_izquierda)
	_desfasar("del_der", corrimiento_delantera_derecha)


func _desfasar(pata, corrimiento):
	if abs(corrimiento) < 0.001:
		return
	if not _tabla.has(pata) or _largo_anim <= 0.0:
		return
	var ahora = _animador.current_animation_position / _largo_anim
	var donde = fmod(ahora + corrimiento + 2.0, 1.0) * MUESTRAS
	var a = int(donde) % MUESTRAS
	var b = (a + 1) % MUESTRAS
	var mezcla = donde - floor(donde)
	var filas = _tabla[pata]
	for j in range(_idx[pata].size()):
		var i = _idx[pata][j]
		if i < 0:
			continue
		_esqueleto.set_bone_pose(i, filas[a][j].interpolate_with(filas[b][j], mezcla))


func _medir_velocidad(delta):
	if _punto_referencia == null or delta <= 0:
		return
	var avance = _punto_referencia.offset - _offset_anterior
	_offset_anterior = _punto_referencia.offset
	# Al cruzar el empalme del circuito el offset pega un salto
	# enorme hacia atras. Ese cuadro se descarta.
	if abs(avance) < 100.0:
		_velocidad_actual = abs(avance) / delta


func _ajustar_ritmo(delta):
	if _animador == null or delta <= 0:
		return
	var deseado = 1.0
	if sincronizar_ritmo and velocidad_referencia > 0.0:
		deseado = clamp(_velocidad_actual / velocidad_referencia, ritmo_minimo, ritmo_maximo)
	_ritmo_actual = lerp(_ritmo_actual, deseado, clamp(suavizado_ritmo * delta, 0.0, 1.0))
	_animador.playback_speed = _ritmo_actual * _variacion


func _emparejar():
	if not emparejar_patas or _esqueleto == null:
		return

	_ajustar("del_izq", 0, del_izq_hombro, del_izq_hombro_centro, del_izq_hombro_momento)
	_ajustar("del_izq", 1, del_izq_codo, del_izq_codo_centro, del_izq_codo_momento)
	_ajustar("del_izq", 2, del_izq_rodilla, del_izq_rodilla_centro, del_izq_rodilla_momento)
	_ajustar("del_izq", 3, del_izq_pezuna, del_izq_pezuna_centro, del_izq_pezuna_momento)

	_ajustar("del_der", 0, del_der_hombro, del_der_hombro_centro, del_der_hombro_momento)
	_ajustar("del_der", 1, del_der_codo, del_der_codo_centro, del_der_codo_momento)
	_ajustar("del_der", 2, del_der_rodilla, del_der_rodilla_centro, del_der_rodilla_momento)
	_ajustar("del_der", 3, del_der_pezuna, del_der_pezuna_centro, del_der_pezuna_momento)

	_ajustar("tras_izq", 0, tras_izq_cadera, 0.0, 0.0)
	_ajustar("tras_izq", 1, tras_izq_muslo, 0.0, 0.0)
	_ajustar("tras_izq", 2, tras_izq_corva, 0.0, 0.0)
	_ajustar("tras_izq", 3, tras_izq_pezuna, 0.0, 0.0)

	_ajustar("tras_der", 0, tras_der_cadera, 0.0, 0.0)
	_ajustar("tras_der", 1, tras_der_muslo, 0.0, 0.0)
	_ajustar("tras_der", 2, tras_der_corva, 0.0, 0.0)
	_ajustar("tras_der", 3, tras_der_pezuna, 0.0, 0.0)


# Los tres controles sobre UNA articulacion:
#   recorrido = cuanto se abre el angulo   (1.0 = como lo hiciste vos)
#   centro    = donde queda parada, en grados
#   momento   = cuanto se atrasa dentro del ciclo, de 0 a 1
func _ajustar(pata, puesto, recorrido, centro, momento):
	if abs(recorrido - 1.0) < 0.001 and abs(centro) < 0.01 and abs(momento) < 0.001:
		return
	if not _idx.has(pata):
		return
	var i = _idx[pata][puesto]
	if i < 0:
		return

	# MOMENTO: si esta pedido, se lee la pose de otro instante.
	var pose = _esqueleto.get_bone_pose(i)
	if abs(momento) > 0.001:
		var prestada = _pose_corrida(pata, puesto, -momento)
		if prestada != null:
			pose = prestada

	var giro = pose.basis.get_rotation_quat()

	# RECORRIDO
	if abs(recorrido - 1.0) > 0.001:
		giro = Quat().slerp(giro, recorrido)

	# Tope de seguridad.
	var coseno = clamp(abs(giro.w), -1.0, 1.0)
	var grados = 2.0 * rad2deg(acos(coseno))
	if grados > tope_grados:
		giro = Quat().slerp(giro, tope_grados / grados)

	# CENTRO: se suma despues, para que no lo agrande el recorrido.
	if abs(centro) > 0.01:
		giro = giro * Quat(_eje_del_hueso(pata, puesto), deg2rad(centro))

	_esqueleto.set_bone_pose(i, Transform(Basis(giro.normalized()), pose.origin))


# Devuelve la pose que tenia esa articulacion en otro instante.
func _pose_corrida(pata, puesto, corrimiento):
	if not _tabla.has(pata) or _largo_anim <= 0.0 or _animador == null:
		return null
	var ahora = _animador.current_animation_position / _largo_anim
	var donde = fmod(ahora + corrimiento + 2.0, 1.0) * MUESTRAS
	var a = int(donde) % MUESTRAS
	var b = (a + 1) % MUESTRAS
	var filas = _tabla[pata]
	return filas[a][puesto].interpolate_with(filas[b][puesto], donde - floor(donde))


# Eje de giro de cada articulacion, medido adentro del Caballo.glb.
func _eje_del_hueso(pata, puesto):
	if puesto == 0:
		return Vector3.RIGHT
	if pata == "del_der" and puesto == 1:
		return Vector3.RIGHT
	return Vector3.BACK


# ---------------------------------------------------------------
#  UTILIDADES
# ---------------------------------------------------------------

func _buscar_hueso(nombre):
	var i = _esqueleto.find_bone(nombre)
	if i >= 0:
		return i
	for variante in [nombre.replace("__", "::"), nombre.replace("__", "_"),
			nombre.replace("::", "__"), nombre.replace("::", "_")]:
		i = _esqueleto.find_bone(variante)
		if i >= 0:
			return i
	var buscado = _simplificar(nombre)
	for k in range(_esqueleto.get_bone_count()):
		if _simplificar(_esqueleto.get_bone_name(k)) == buscado:
			return k
	return -1


func _simplificar(texto):
	var limpio = ""
	for c in texto.to_lower():
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			limpio += c
	return limpio


func _listar_huesos():
	var nombres = []
	for i in range(_esqueleto.get_bone_count()):
		nombres.append(_esqueleto.get_bone_name(i))
	return nombres


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


func _diagnostico_una_vez():
	if _diagnostico_final_hecho:
		return
	_diagnostico_final_hecho = true
	var papa = get_parent()
	if papa and papa.name == "Enrutador_Caballo1" and GestorNivel and GestorNivel.mostrar_diagnostico:
		var offset_papa = papa.offset if "offset" in papa else "?"
		var modo_papa = papa.rotation_mode if "rotation_mode" in papa else "?"
		var euler_rad = global_transform.basis.get_euler()
		var euler_grados = Vector3(rad2deg(euler_rad.x), rad2deg(euler_rad.y), rad2deg(euler_rad.z))
		print("[BDG-Caballo2] ", name, " colgado de ", papa.name,
			" | offset=", offset_papa,
			" | modo_rotacion_padre=", modo_papa,
			" | rotacion FINAL del padre (grados)=", papa.rotation_degrees,
			" | rotacion local del caballo (grados)=", rotation_degrees,
			" | rotacion MUNDIAL del caballo (grados)=", euler_grados)
# =====================================================================
#  LOS DIEZ CABALLOS COPIAN AL DEL JUGADOR
# =====================================================================
# Las perillas se tocan en UN solo lugar: el nodo Caballo que cuelga
# de Enrutador_Caballo1. Los otros nueve se las copian al arrancar.
# No se copian las correcciones de rotacion, que son propias de cada uno.
const PERILLAS_COPIADAS = [
	"emparejar_patas", "tope_grados",
	"del_izq_hombro", "del_izq_codo", "del_izq_rodilla", "del_izq_pezuna",
	"del_izq_hombro_centro", "del_izq_codo_centro", "del_izq_rodilla_centro", "del_izq_pezuna_centro",
	"del_izq_hombro_momento", "del_izq_codo_momento", "del_izq_rodilla_momento", "del_izq_pezuna_momento",
	"del_der_hombro", "del_der_codo", "del_der_rodilla", "del_der_pezuna",
	"del_der_hombro_centro", "del_der_codo_centro", "del_der_rodilla_centro", "del_der_pezuna_centro",
	"del_der_hombro_momento", "del_der_codo_momento", "del_der_rodilla_momento", "del_der_pezuna_momento",
	"tras_izq_cadera", "tras_izq_muslo", "tras_izq_corva", "tras_izq_pezuna",
	"tras_der_cadera", "tras_der_muslo", "tras_der_corva", "tras_der_pezuna",
	"corrimiento_trasera_izquierda", "corrimiento_trasera_derecha",
	"corrimiento_delantera_izquierda", "corrimiento_delantera_derecha",
	"quieto_en_la_gatera", "velocidad_minima_para_correr", "pose_de_espera"
]


func _copiar_del_jugador():
	if not copiar_del_jugador:
		return
	var papa = get_parent()
	if papa == null or papa.name == "Enrutador_Caballo1":
		return
	var pista = papa.get_parent()
	if pista == null:
		return
	var maestro = pista.get_node_or_null("Enrutador_Caballo1/Caballo")
	if maestro == null or maestro == self:
		return
	for perilla in PERILLAS_COPIADAS:
		set(perilla, maestro.get(perilla))
	if mostrar_diagnostico:
		print("[BDG-Patas] ", papa.name, " copio las perillas del caballo del jugador")
