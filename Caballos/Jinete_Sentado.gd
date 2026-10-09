tool
extends Spatial
# Jinete_Jockey.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Va en la raíz del jinete (Jinete_Sentado.glb).
# Pone al jinete en postura de jockey, le da el movimiento de galope
# y el latigazo con la mano derecha. Todo se ajusta en el Inspector.
# Ángulos en grados.

export var activo := true

# ---------- POSTURA ----------
export var muslos_adelante := -75.0      # más negativo = rodillas más altas
export var abrir_piernas := 0.0          # sube para que rodeen al caballo
export var doblar_rodillas := 115.0      # más alto = pantorrilla más atrás
export var inclinar_cintura := -25.0     # negativo = hacia adelante
export var inclinar_pecho_bajo := -25.0
export var inclinar_pecho_alto := -20.0
export var levantar_cuello := 30.0       # positivo = mira más al frente
export var levantar_cabeza := 30.0
export var brazos_adelante := -95.0      # más negativo = manos más adelante
export var doblar_codos := -20.0
export var cerrar_manos := 60.0          # 0 = mano abierta

# ---------- GALOPE ----------
export var trancos_por_segundo := 2.2
export var rebote_rodillas := 6.0
export var rebote_cadera := 0.004
export var empuje_brazos := 12.0
export var vaiven_cuerpo := 3.0

# ---------- LATIGAZO (mano derecha) ----------
export var latigo_automatico := true
export var latigo_cada_segundos := 6.0
export var latigo_golpes := 2
export var latigo_duracion_golpe := 0.45
export var latigo_brazo_atras := 40.0    # cuánto va el brazo hacia atrás
export var latigo_brazo_afuera := -15.0  # separa el brazo del cuerpo
export var latigo_codo := -10.0

var _esq : Skeleton
var _h := {}
var _t := 0.0
var _t_latigo := 0.0
var _latigo_activo := false
var _latigo_tiempo := 0.0

const _DEDOS := ["Index", "Middle", "Ring", "Pinky"]


func _ready():
	_esq = _buscar_esqueleto(self)
	if _esq == null:
		push_warning("Jinete_Jockey: no encontré el esqueleto.")
		activo = false
		return
	for ap in _buscar_todos(self, "AnimationPlayer"):
		ap.stop()
	for i in _esq.get_bone_count():
		_esq.set_bone_pose(i, Transform())
	for n in ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head",
			"LeftUpLeg", "LeftLeg", "RightUpLeg", "RightLeg",
			"LeftArm", "LeftForeArm", "RightArm", "RightForeArm"]:
		_h[n] = _hueso(n)
	for lado in ["Left", "Right"]:
		for d in _DEDOS:
			for k in [1, 2, 3]:
				var nombre = lado + "Hand" + d + str(k)
				_h[nombre] = _hueso(nombre)


func latigazo():
	_latigo_activo = true
	_latigo_tiempo = 0.0


func _process(delta):
	if not activo:
		return
	_t += delta

	if latigo_automatico and not _latigo_activo:
		_t_latigo += delta
		if _t_latigo >= latigo_cada_segundos:
			_t_latigo = 0.0
			latigazo()

	var fase := sin(_t * trancos_por_segundo * TAU)

	# Latigazo: 0 = riendas, 1 = brazo atrás
	var golpe := 0.0
	if _latigo_activo:
		_latigo_tiempo += delta
		var total := latigo_duracion_golpe * latigo_golpes
		if _latigo_tiempo >= total:
			_latigo_activo = false
		else:
			var p := fmod(_latigo_tiempo, latigo_duracion_golpe) / latigo_duracion_golpe
			golpe = sin(p * PI)

	# Cadera
	_poner("Hips", Vector3.ZERO, Vector3(0, fase * rebote_cadera, 0))

	# Piernas
	var muslo := muslos_adelante - fase * rebote_rodillas * 0.5
	var rodilla := doblar_rodillas + fase * rebote_rodillas
	_poner("LeftUpLeg", Vector3(0, -abrir_piernas, muslo))
	_poner("RightUpLeg", Vector3(0, abrir_piernas, muslo))
	_poner("LeftLeg", Vector3(0, 0, rodilla))
	_poner("RightLeg", Vector3(0, 0, rodilla))

	# Cuerpo y cabeza
	_poner("Spine", Vector3(0, 0, inclinar_cintura + fase * vaiven_cuerpo))
	_poner("Spine1", Vector3(0, 0, inclinar_pecho_bajo))
	_poner("Spine2", Vector3(0, 0, inclinar_pecho_alto))
	_poner("Neck", Vector3(0, 0, levantar_cuello - fase * vaiven_cuerpo))
	_poner("Head", Vector3(0, 0, levantar_cabeza))

	# Brazos (empujan al ritmo del tranco)
	var brazo := brazos_adelante + fase * empuje_brazos
	var codo := doblar_codos - fase * empuje_brazos * 0.5
	_poner("LeftArm", Vector3(0, 0, brazo))
	_poner("LeftForeArm", Vector3(0, 0, codo))

	var brazo_der := Vector3(0, 0, brazo).linear_interpolate(
			Vector3(latigo_brazo_afuera, 0, latigo_brazo_atras), golpe)
	var codo_der := Vector3(0, 0, codo).linear_interpolate(
			Vector3(0, 0, latigo_codo), golpe)
	_poner("RightArm", brazo_der)
	_poner("RightForeArm", codo_der)

	# Manos cerradas (izquierda y derecha giran al revés)
	for d in _DEDOS:
		for k in [1, 2, 3]:
			_poner("LeftHand" + d + str(k), Vector3(-cerrar_manos, 0, 0))
			_poner("RightHand" + d + str(k), Vector3(cerrar_manos, 0, 0))


# ---------- utilidades ----------
func _poner(nombre, grados : Vector3, mover := Vector3.ZERO):
	var i = _h.get(nombre, -1)
	if i < 0:
		return
	var rad := Vector3(deg2rad(grados.x), deg2rad(grados.y), deg2rad(grados.z))
	_esq.set_bone_pose(i, Transform(Basis(rad), mover))


func _hueso(fin : String) -> int:
	for i in _esq.get_bone_count():
		var n : String = _esq.get_bone_name(i)
		if n == fin or n.ends_with(":" + fin) or n.ends_with("_" + fin):
			return i
	push_warning("Jinete_Jockey: no encontré el hueso " + fin)
	return -1


func _buscar_esqueleto(n):
	if n is Skeleton:
		return n
	for c in n.get_children():
		var r = _buscar_esqueleto(c)
		if r:
			return r
	return null


func _buscar_todos(n, clase : String) -> Array:
	var r := []
	if n.is_class(clase):
		r.append(n)
	for c in n.get_children():
		r += _buscar_todos(c, clase)
	return r
