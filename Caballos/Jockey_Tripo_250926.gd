tool
extends Spatial
# Jockey_Tripo_250926.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Va en la raíz del jinete (Jinete_Sentado.glb).
# Pone al jinete en postura de jockey, le da el movimiento de galope
# y el latigazo con la mano derecha. Todo se ajusta en el Inspector.
# Ángulos en grados.
# VERSION: castigo en los ultimos 400 m (oct 2026)
#
# SIMETRÍA: el esqueleto de Tripo trae giros escondidos distintos en cada
# lado (columna, hombros, brazos). Con "simetria" activado, la columna se
# dobla solo hacia adelante y cada lado copia en espejo al otro:
# piernas copian la izquierda, brazos copian la derecha.

export var activo := true
export var simetria := true

# ---------- POSTURA ----------
export var muslos_adelante := -75.0      # más negativo = rodillas más altas
export var abrir_piernas := 0.0          # sube para que rodeen al caballo
export var abrir_pantorrillas := 0.0     # saca las botas hacia afuera
export var largo_piernas := 1.0          # menos de 1 = piernas más cortas (sin adelgazar)
export var doblar_rodillas := 115.0      # más alto = pantorrilla más atrás
export var inclinar_pies := 0.0          # + = punta arriba (talón abajo), - = punta abajo
export var girar_pies := -10.0           # 0 = como de pie; - = punta hacia adentro, + = afuera
export var tamano_pies := 0.8            # 1 = tamaño original; menos = pie/bota más chico
export var inclinar_cintura := -25.0     # negativo = hacia adelante
export var inclinar_pecho_bajo := -25.0
export var inclinar_pecho_alto := -20.0
export var levantar_cuello := 30.0       # positivo = mira más al frente
export var levantar_cabeza := 30.0
export var brazos_adelante := -95.0      # más negativo = manos más adelante
export var doblar_codos := -20.0
export var cerrar_manos := 60.0          # 0 = mano abierta
export var juntar_manos := 0.0           # + = junta las manos al centro, sobre el cuello del caballo

# ---------- GALOPE ----------
export var trancos_por_segundo := 2.2
export var rebote_rodillas := 6.0
export var rebote_cadera := 0.004
export var empuje_brazos := 12.0
export var vaiven_cuerpo := 3.0

# ---------- LATIGAZO (mano derecha) ----------
export var latigo_automatico := true
export var latigo_cada_segundos := 6.0
export var latigo_variacion := 0.5    # 0.5 = cada jinete fustiga al azar entre la mitad y vez y media de ese tiempo
export var castigar_solo_al_final := true     # los rivales castigan solo en los ultimos metros (antes, solo arrean)
export var metros_castigo := 400.0            # desde cuantos metros antes de la meta empiezan a castigar
export var latigo_cada_segundos_final := 1.6  # en el final castigan mucho mas seguido
export var latigo_golpes := 2
export var latigo_duracion_golpe := 0.45
# Cada golpe: 1) sube el brazo adelante y arriba, 2) lo baja en diagonal
# pasando por el medio (al lado de la cadera), 3) pega atras abajo, en el anca,
# 4) vuelve a las riendas. Los giros van en grados (X, Y, Z).
export var latigo_arriba_brazo := Vector3(0, -30, -180)  # mano adelante y arriba
export var latigo_arriba_codo := Vector3(0, 0, 0)
export var latigo_medio_brazo := Vector3(60, 60, -100)   # mano bajando por el costado
export var latigo_medio_codo := Vector3(0, 0, 0)
export var latigo_abajo_brazo := Vector3(30, 60, 0)      # mano atras y abajo, pegando en el anca
export var latigo_abajo_codo := Vector3(0, 0, 0)
export var latigo_subida := 0.35     # parte del golpe que tarda en subir (0 a 1)
export var latigo_bajada := 0.35     # parte del golpe que tarda en bajar
# Muñeca: se echa atras al subir y da el golpe seco al bajar.
export var latigo_muneca := 55.0           # en grados; negativo = al otro lado
export(int, "X", "Y", "Z") var latigo_muneca_eje := 2

var _esq : Skeleton
var _h := {}
var _t := 0.0
var _t_latigo := 0.0
var _proximo_latigo := 6.0
var _latigo_activo := false
var _latigo_tiempo := 0.0
var _muneca := 0.0
var _fase_latigo := 0.0

var _rest := []      # reposo de cada hueso
var _padre := []     # padre de cada hueso
var _b0 := []        # orientación de cada hueso en reposo (vista desde el esqueleto)
var _pz := {}        # giros puestos en este cuadro
var _po := {}        # movimientos puestos en este cuadro
var _gb := {}        # memoria de cálculo
var _espejo := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))

const _DEDOS := ["Index", "Middle", "Ring", "Pinky"]
const _PIERNA := ["UpLeg", "Leg", "Foot", "ToeBase"]
var _BRAZO := []


func _ready():
	# Cada jinete empieza a contar desde un punto distinto, para que no
	# fustiguen todos al mismo tiempo.
	_t_latigo = randf() * latigo_cada_segundos
	_proximo_latigo = _tiempo_al_azar()
	_esq = _buscar_esqueleto(self)
	if _esq == null:
		push_warning("Jinete_Jockey: no encontré el esqueleto.")
		activo = false
		return
	for ap in _buscar_todos(self, "AnimationPlayer"):
		ap.stop()
	_BRAZO = ["Shoulder", "Arm", "ForeArm", "Hand"]
	for d in _DEDOS + ["Thumb"]:
		for k in [1, 2, 3]:
			_BRAZO.append("Hand" + d + str(k))
	_rest.clear()
	_padre.clear()
	for i in _esq.get_bone_count():
		_esq.set_bone_pose(i, Transform())
		_rest.append(_esq.get_bone_rest(i))
		_padre.append(_esq.get_bone_parent(i))
	_pz.clear()
	_gb.clear()
	_b0.clear()
	for i in _esq.get_bone_count():
		_b0.append(_glob(i))
	for n in ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head"]:
		_h[n] = _hueso(n)
	for lado in ["Left", "Right"]:
		for p in _PIERNA + _BRAZO:
			_h[lado + p] = _hueso(lado + p)


func latigazo():
	_latigo_activo = true
	_latigo_tiempo = 0.0


func _tiempo_al_azar() -> float:
	var v : float = clamp(latigo_variacion, 0.0, 0.9)
	var base : float = latigo_cada_segundos
	if _estaba_en_final:
		base = latigo_cada_segundos_final
	return base * rand_range(1.0 - v, 1.0 + v)


# True cuando a este caballo le faltan menos de metros_castigo para la
# meta, en la ultima vuelta. Lo mide GestorNivel, igual que el juez.
var _estaba_en_final := false
func _en_los_ultimos_metros() -> bool:
	if Engine.editor_hint or GestorNivel == null:
		return false
	_adelante_caballo()   # deja guardado el enrutador de este caballo
	if _enrutador_cache == null:
		return false
	var d = GestorNivel.obtener_distancia_hasta_meta(_enrutador_cache)
	return d >= 0.0 and d <= metros_castigo


func _process(delta):
	if not activo or _esq == null or _b0.empty():
		return
	_t += delta

	if latigo_automatico and not _latigo_activo:
		var en_final := _en_los_ultimos_metros()
		if en_final and not _estaba_en_final:
			# Al entrar a los ultimos metros cada uno arranca a castigar
			# en un momento distinto (no todos a la vez).
			_t_latigo = 0.0
			_proximo_latigo = rand_range(0.1, 1.5)
		_estaba_en_final = en_final
		if castigar_solo_al_final and not en_final:
			_t_latigo = 0.0
		else:
			_t_latigo += delta
			if _t_latigo >= _proximo_latigo:
				_t_latigo = 0.0
				_proximo_latigo = _tiempo_al_azar()
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
			golpe = 1.0
			_fase_latigo = p

	_pz.clear()
	_po.clear()
	_gb.clear()

	# Cadera
	_mover("Hips", Vector3(0, fase * rebote_cadera, 0))

	# Cuerpo y cabeza (se doblan solo hacia adelante)
	_centro("Spine", Vector3(0, 0, inclinar_cintura + fase * vaiven_cuerpo))
	_centro("Spine1", Vector3(0, 0, inclinar_pecho_bajo))
	_centro("Spine2", Vector3(0, 0, inclinar_pecho_alto))
	_centro("Neck", Vector3(0, 0, levantar_cuello - fase * vaiven_cuerpo))
	_centro("Head", Vector3(0, 0, levantar_cabeza))

	# Pierna izquierda (la derecha la copia en espejo)
	var muslo := muslos_adelante - fase * rebote_rodillas * 0.5
	var rodilla := doblar_rodillas + fase * rebote_rodillas
	var largo : float = max(largo_piernas, 0.3)
	var s_largo := Basis().scaled(Vector3(1, largo, 1))
	var s_vuelve := Basis().scaled(Vector3(1, 1.0 / largo, 1))
	_fijar("LeftUpLeg", _giro(Vector3(0, -abrir_piernas, muslo)) * s_largo)
	_fijar("LeftLeg", s_vuelve * _giro(Vector3(abrir_pantorrillas, 0, rodilla)) * s_largo)
	# Pie recto: plano y mirando al frente, como cuando está de pie
	var ip = _h.get("LeftFoot", -1)
	if ip >= 0:
		var giro_pie := _giro(Vector3(-inclinar_pies, girar_pies, 0))
		_fijar("LeftFoot", (_base_padre(ip).inverse() * giro_pie * _b0[ip]).scaled(Vector3.ONE * tamano_pies))

	# Brazo derecho (el izquierdo lo copia en espejo)
	var brazo := brazos_adelante + fase * empuje_brazos
	var codo := doblar_codos - fase * empuje_brazos * 0.5
	_fijar("RightArm", _giro(Vector3(-juntar_manos, 0, brazo)))
	_fijar("RightForeArm", _giro(Vector3(0, 0, codo)))
	for d in _DEDOS:
		for k in [1, 2, 3]:
			_fijar("RightHand" + d + str(k), _giro(Vector3(cerrar_manos, 0, 0)))

	if simetria:
		for p in _PIERNA:
			_copiar_espejo("Left" + p, "Right" + p)
		for p in _BRAZO:
			_copiar_espejo("Right" + p, "Left" + p)
	else:
		_fijar("RightUpLeg", _giro(Vector3(0, abrir_piernas, muslo)) * s_largo)
		_fijar("RightLeg", s_vuelve * _giro(Vector3(-abrir_pantorrillas, 0, rodilla)) * s_largo)
		var ipd = _h.get("RightFoot", -1)
		if ipd >= 0:
			var giro_pie_d := _giro(Vector3(-inclinar_pies, -girar_pies, 0))
			_fijar("RightFoot", (_base_padre(ipd).inverse() * giro_pie_d * _b0[ipd]).scaled(Vector3.ONE * tamano_pies))
		_fijar("LeftArm", _giro(Vector3(juntar_manos, 0, brazo)))
		_fijar("LeftForeArm", _giro(Vector3(0, 0, codo)))
		for d in _DEDOS:
			for k in [1, 2, 3]:
				_fijar("LeftHand" + d + str(k), _giro(Vector3(-cerrar_manos, 0, 0)))

	# Latigazo: el brazo derecho se va hacia atrás
	if golpe > 0.0:
		var p = _fase_latigo
		var s1 = clamp(latigo_subida, 0.05, 0.9)
		var s2 = clamp(latigo_bajada, 0.05, 0.9)
		var arriba = 0.0
		var medio = 0.0
		var abajo = 0.0
		if p < s1:
			arriba = smoothstep(0.0, 1.0, p / s1)
			_muneca = -0.6 * arriba
		elif p < s1 + s2:
			# Bajada en diagonal: arriba -> medio -> abajo, cada vez mas rapido.
			var q = pow((p - s1) / s2, 1.5)
			arriba = 1.0
			if q < 0.5:
				medio = q / 0.5
			else:
				medio = 1.0
				abajo = (q - 0.5) / 0.5
			_muneca = lerp(-0.6, 1.0, q)
		else:
			abajo = 1.0 - smoothstep(0.0, 1.0, (p - s1 - s2) / max(1.0 - s1 - s2, 0.05))
			medio = abajo
			_muneca = abajo
		_mezclar("RightArm", _giro(latigo_arriba_brazo), arriba)
		_mezclar("RightForeArm", _giro(latigo_arriba_codo), arriba)
		_mezclar("RightArm", _giro(latigo_medio_brazo), medio)
		_mezclar("RightForeArm", _giro(latigo_medio_codo), medio)
		_mezclar("RightArm", _giro(latigo_abajo_brazo), abajo)
		_mezclar("RightForeArm", _giro(latigo_abajo_codo), abajo)
		if latigo_muneca != 0.0 and _muneca != 0.0:
			var g = Vector3.ZERO
			g[latigo_muneca_eje] = latigo_muneca * sign(_muneca)
			_fijar("RightHand", Basis(Quat().slerp(Quat(_giro(g).orthonormalized()), abs(_muneca))))
	else:
		_muneca = 0.0

	# Aplicar todo al esqueleto
	for i in _pz.keys():
		_esq.set_bone_pose(i, Transform(_pz[i], _po.get(i, Vector3.ZERO)))
	for i in _po.keys():
		if not _pz.has(i):
			_esq.set_bone_pose(i, Transform(Basis(), _po[i]))


# ---------- simetría ----------
func _centro(nombre, grados : Vector3):
	var i = _h.get(nombre, -1)
	if i < 0:
		return
	_fijar(nombre, _giro(grados))
	if not simetria:
		return
	# Deja solo el doblez hacia adelante/atrás (quita la torcedura de lado)
	var s : Basis = _glob(i) * _b0[i].inverse()
	var q := Quat(s.orthonormalized())
	var t := Quat(q.x, 0, 0, q.w)
	if t.length() < 0.000001:
		t = Quat()
	else:
		t = t.normalized()
	_fijar(nombre, _base_padre(i).inverse() * Basis(t) * _b0[i])


func _copiar_espejo(origen, destino):
	var a = _h.get(origen, -1)
	var b = _h.get(destino, -1)
	if a < 0 or b < 0:
		return
	var s : Basis = _glob(a) * _b0[a].inverse()
	var s_esp : Basis = _espejo * s * _espejo
	_pz[b] = _base_padre(b).inverse() * s_esp * _b0[b]
	_gb.clear()


func _mezclar(nombre, destino : Basis, cuanto : float):
	var i = _h.get(nombre, -1)
	if i < 0 or not _pz.has(i):
		return
	var q1 := Quat(_pz[i].orthonormalized())
	var q2 := Quat(destino.orthonormalized())
	_pz[i] = Basis(q1.slerp(q2, cuanto))
	_gb.clear()


func _base_padre(i) -> Basis:
	var p = _padre[i]
	if p >= 0:
		return _glob(p) * _rest[i].basis
	return _rest[i].basis


func _glob(i) -> Basis:
	if _gb.has(i):
		return _gb[i]
	var b : Basis = _rest[i].basis * _pz.get(i, Basis())
	var p = _padre[i]
	if p >= 0:
		b = _glob(p) * b
	_gb[i] = b
	return b


# ---------- utilidades ----------
func _fijar(nombre, base : Basis):
	var i = _h.get(nombre, -1)
	if i < 0:
		return
	_pz[i] = base
	_gb.clear()


func _mover(nombre, mover : Vector3):
	var i = _h.get(nombre, -1)
	if i < 0:
		return
	_po[i] = mover


func _giro(grados : Vector3) -> Basis:
	return Basis(Vector3(deg2rad(grados.x), deg2rad(grados.y), deg2rad(grados.z)))


func _hueso(fin : String) -> int:
	for i in _esq.get_bone_count():
		var n : String = _esq.get_bone_name(i)
		if n == fin or n.ends_with(":" + fin) or n.ends_with("_" + fin):
			return i
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

# ---------- LÁTIGO EN LA MANO DERECHA ----------
export(PackedScene) var latigo_modelo    # arrastra aquí Latigo_Jockey_02.glb
export var latigo_posicion := Vector3(-0.022, 0.044, 0.001)
export var latigo_giro := Vector3(-6, -32, 109)
export var latigo_tamano := 0.62
export var latigo_grosor_mango := 1.5     # 1 = grosor original
export var latigo_grosor_vara := 3.0      # 1 = grosor original
# La fusta apunta siempre hacia abajo (como la sostiene el jinete con la muñeca),
# un poco hacia atras, y al pegar se va mas hacia atras, al anca.
export var latigo_siempre_abajo := false
# La fusta es la extension del brazo: sale de la punta de la mano en linea
# recta con el antebrazo (codo -> mano), sin doblar la muneca.
export var latigo_como_extension := true
export var latigo_extension_atras := 0.0      # 0 = linea recta exacta con el brazo
export var latigo_bajar_punta := 0.0          # 0 = linea recta exacta con el brazo
export var latigo_inclinacion_atras := 0.35   # 0 = derecho abajo; mas alto = mas hacia atras
export var latigo_atras_al_pegar := 0.8       # cuanto mas se va hacia atras en el golpe
# Cuando el brazo sube para pegar, la punta del latigo gira hacia arriba
# y hacia atras (como en la vida real), y al bajar va hacia el anca.
export var latigo_alzar := true
export var latigo_alzar_altura := 1.0         # cuanto apunta hacia arriba con el brazo arriba
export var latigo_alzar_atras := 1.0          # cuanto apunta hacia atras con el brazo arriba

var _latigo_mano = null
var _latigo = null
var _latigo_usado = null


func _physics_process(_delta):
	_poner_latigo()
	_vestir()


# Hacia donde va el caballo (el Enrutador que lo lleva por la pista).
var _enrutador_cache = null
func _adelante_caballo() -> Vector3:
	if _enrutador_cache == null or not is_instance_valid(_enrutador_cache):
		var n = get_parent()
		while n != null and not (n is PathFollow):
			n = n.get_parent()
		_enrutador_cache = n
	if _enrutador_cache != null:
		return (-_enrutador_cache.global_transform.basis.z).normalized()
	return (-global_transform.basis.z).normalized()


func _poner_latigo():
	if _esq == null:
		return
	var ih = _h.get("RightHand", -1)
	if ih < 0:
		return
	if _latigo_mano == null or not is_instance_valid(_latigo_mano):
		_latigo_mano = _esq.get_node_or_null("Latigo_Mano")
		if _latigo_mano == null:
			_latigo_mano = BoneAttachment.new()
			_latigo_mano.name = "Latigo_Mano"
			_latigo_mano.bone_name = _esq.get_bone_name(ih)
			_esq.add_child(_latigo_mano)
	if latigo_modelo != _latigo_usado:
		_latigo_usado = latigo_modelo
		for c in _latigo_mano.get_children():
			c.queue_free()
		_latigo = null
		if latigo_modelo != null:
			_latigo = latigo_modelo.instance()
			_latigo_mano.add_child(_latigo)
	if _latigo != null and is_instance_valid(_latigo):
		_latigo.transform = Transform(_giro(latigo_giro).scaled(Vector3.ONE * latigo_tamano), latigo_posicion)
		var y = Vector3.ZERO
		var adelante = _adelante_caballo()
		if latigo_como_extension:
			var ic = _h.get("RightForeArm", -1)
			var im = _h.get("RightHand", -1)
			if ic >= 0 and im >= 0:
				var p_codo = _esq.global_transform.xform(_esq.get_bone_global_pose(ic).origin)
				var p_mano = _esq.global_transform.xform(_esq.get_bone_global_pose(im).origin)
				var linea = p_mano - p_codo
				if linea.length() > 0.0001:
					y = (linea.normalized() - adelante * latigo_extension_atras - Vector3.UP * latigo_bajar_punta).normalized()
		elif latigo_siempre_abajo:
			var atras = latigo_inclinacion_atras + max(_muneca, 0.0) * latigo_atras_al_pegar
			y = (-Vector3.UP - adelante * atras).normalized()
			# Brazo arriba: la punta sube y apunta hacia atras.
			var alzar = clamp(-_muneca / 0.6, 0.0, 1.0)
			if latigo_alzar and alzar > 0.0:
				var arriba = (Vector3.UP * latigo_alzar_altura - adelante * latigo_alzar_atras).normalized()
				y = y.slerp(arriba, alzar).normalized()
		if y != Vector3.ZERO:
			var x = y.cross(adelante)
			if x.length() < 0.01:
				x = y.cross(Vector3.RIGHT)
			x = x.normalized()
			var z = x.cross(y).normalized()
			var gt = _latigo.global_transform
			gt.basis = Basis(x, y, z).scaled(gt.basis.get_scale())
			_latigo.global_transform = gt
		var mango = _latigo.get_node_or_null("Latigo_Mango")
		if mango != null:
			mango.scale = Vector3(latigo_grosor_mango, 1, latigo_grosor_mango)
		var vara = _latigo.get_node_or_null("Latigo_Vara_Paleta")
		if vara != null:
			vara.scale = Vector3(latigo_grosor_vara, 1, latigo_grosor_vara)


# ---------- SEDAS DEL JINETE ----------
# Necesita el Jinete_Sentado.glb partido en prendas (Cara, Cuerpo, Mangas,
# Guantes, Pantalon, Botas, Casco). Tu jinete (Enrutador_Caballo1) usa
# estos valores; los rivales sacan sedas al azar en cada carrera.
export var colores_al_azar := true
export var color_1 := Color("6d1a2a")        # color principal de la chaquetilla
export var color_2 := Color("d4af37")        # color del diseño
export(int, "Liso", "Aros", "Franjas", "Banda cruzada", "Cuartos", "Mitades", "Rombos", "Lunares", "Estrellas", "Estrella grande", "Cheurones", "Cruz") var diseno_cuerpo := 0
export(int, "Lisas", "Aros", "Puños", "Hombros") var diseno_mangas := 0
export var mangas_color_2 := true            # mangas del color 2 (si no, del color 1)
export var cantidad_diseno := 5.0            # cuántos aros, franjas, lunares o estrellas
export var color_casco := Color("d4af37")
export var color_pantalon := Color("ffffff")
export var color_guantes := Color("ffffff")
export var color_botas := Color("0a0a0a")
export var color_latigo := Color("0a0a0a")
export var aspereza_seda := 0.45             # 0 = seda muy brillante, 1 = mate
export var tono_piel := Color("ffffff")      # piel de tu jinete (ffffff = tono original)
# Tonos de piel de los rivales (uno al azar en cada carrera): Blanco, Asiatico,
# Mestizo, Indigena, Moreno, Oscuro, Muy oscuro. Repite uno para que salga mas.
export var tonos_piel := PoolColorArray([Color("ffffff"), Color("ffffd1"), Color("e2caa3"), Color("c9a880"), Color("a38667"), Color("7e6752"), Color("58493f")])
# Tamano del jinete: cada rival sale con un tamano al azar entre el minimo y
# el maximo. Crece o se achica desde la cadera, sin despegarse de la silla.
export var tamano_jinete := 1.0              # tu jinete (1 = como esta)
export var tamano_al_azar := true
export var tamano_minimo := 0.94
export var tamano_maximo := 1.06

# Sedas de los rivales: un color vivo con uno oscuro, o dos que contrastan
# fuerte. Sin blanco y sin pasteles. Se arman todas las combinaciones de
# estas listas, y en cada carrera ningun rival repite color principal ni
# dibujo de la chaquetilla.
const _VIVOS = ["c8102e", "e4002b", "ff6a13", "ff4f00", "ffd100", "ffa300", "009a44",
	"00a3e0", "0033a0", "5f259f", "9b26b6", "e10098", "00b5ad", "d50032"]
const _OSCUROS = ["1a1a1a", "0b1f4b", "3d0c11", "0a3d1f"]
const _CONTRASTES = [["ffd100", "0033a0"], ["ffd100", "5f259f"], ["ffd100", "c8102e"],
	["ffd100", "009a44"], ["ffa300", "0033a0"], ["00a3e0", "c8102e"], ["e10098", "ffd100"]]
const _BOTAS = ["0a0a0a", "0a0a0a", "0a0a0a", "3b2314"]
const _CODIGO = """
shader_type spatial;
uniform vec4 color_1 : hint_color;
uniform vec4 color_2 : hint_color;
uniform int diseno = 0;
uniform float cantidad = 5.0;
uniform float aspereza = 0.45;
uniform bool manga = false;

float estrella(vec2 p, float r) {
	float a = atan(p.x, p.y);
	float seg = 6.2831853 / 5.0;
	float an = abs(mod(a + seg * 0.5, seg) - seg * 0.5);
	return step(length(p), mix(r, r * 0.4, an / (seg * 0.5)));
}

void fragment() {
	float u = UV2.x;
	float v = UV2.y;
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
	ALBEDO = mix(color_1.rgb, color_2.rgb, k);
	ROUGHNESS = aspereza;
	SPECULAR = 0.5;
}
"""

var _mats := {}
var _vestido := false
var _pintado := false


func _vestir():
	if _esq == null:
		return
	if not _vestido:
		var malla = null
		for c in _esq.get_children():
			if c is MeshInstance:
				malla = c
				break
		if malla == null or malla.mesh == null:
			return
		_vestido = true
		if not Engine.editor_hint:
			_poner_tamano()
		malla.material_override = null
		if not Engine.editor_hint and colores_al_azar and not _es_del_jugador():
			_sortear_sedas()
		var sh = Shader.new()
		sh.code = _CODIGO
		for i in malla.mesh.get_surface_count():
			var m = malla.mesh.surface_get_material(i)
			var n = m.resource_name if m != null else ""
			if n == "Cuerpo" or n == "Mangas":
				var s = ShaderMaterial.new()
				s.shader = sh
				s.set_shader_param("manga", n == "Mangas")
				_mats[n] = s
				malla.set_surface_material(i, s)
			elif n == "Cara" and m is SpatialMaterial:
				if not Engine.editor_hint and colores_al_azar and not _es_del_jugador() and tonos_piel.size() > 0:
					tono_piel = tonos_piel[randi() % tonos_piel.size()]
				var cara = m.duplicate()
				cara.albedo_color = m.albedo_color * tono_piel
				cara.emission = m.emission * tono_piel
				malla.set_surface_material(i, cara)
			elif n in ["Guantes", "Pantalon", "Botas", "Casco"]:
				var sp = SpatialMaterial.new()
				_mats[n] = sp
				malla.set_surface_material(i, sp)
		_mats["Latigo"] = SpatialMaterial.new()
	if Engine.editor_hint or not _pintado:
		_pintar()
		_pintado = true
	if _latigo != null and is_instance_valid(_latigo):
		_pintar_latigo(_latigo)


func _sortear_sedas():
	var usados = _registro_sedas()
	var combos = []
	for v in _VIVOS:
		for o in _OSCUROS:
			combos.append([v, o])
			combos.append([o, v])
	for c in _CONTRASTES:
		combos.append(c)
		combos.append([c[1], c[0]])
	# Primero los que no repiten color principal ni la pareja exacta.
	var libres = []
	for c in combos:
		if not (c[0] in usados["colores"]) and not ((c[0] + c[1]) in usados["parejas"]):
			libres.append(c)
	if libres.size() == 0:
		libres = combos
	var par = libres[randi() % libres.size()]
	usados["colores"].append(par[0])
	usados["parejas"].append(par[0] + par[1])
	usados["parejas"].append(par[1] + par[0])
	color_1 = Color(par[0])
	color_2 = Color(par[1])
	# Dibujo de la chaquetilla: uno distinto para cada rival (hay 12).
	var disenos_libres = []
	for d in range(12):
		if not (d in usados["disenos"]):
			disenos_libres.append(d)
	if disenos_libres.size() == 0:
		disenos_libres = range(12)
	diseno_cuerpo = disenos_libres[randi() % disenos_libres.size()]
	usados["disenos"].append(diseno_cuerpo)
	diseno_mangas = randi() % 4
	mangas_color_2 = randf() < 0.5
	cantidad_diseno = float(3 + randi() % 4)
	color_casco = color_2 if randf() < 0.5 else color_1
	color_pantalon = Color("ffffff") if randf() < 0.8 else Color("f3ecd8")
	color_guantes = Color("ffffff") if randf() < 0.6 else Color("1a1a1a")
	color_botas = Color(_BOTAS[randi() % _BOTAS.size()])


# Tamano del jinete. Solo durante el juego (en el editor no se toca, para no
# guardar el cambio en la escena). Se escala desde la cadera para que el
# jinete siga sentado en la silla; riendas y estribos se ajustan solos.
func _poner_tamano():
	var f : float = tamano_jinete
	if tamano_al_azar and colores_al_azar and not _es_del_jugador():
		f = rand_range(min(tamano_minimo, tamano_maximo), max(tamano_minimo, tamano_maximo))
	if f <= 0.0 or abs(f - 1.0) < 0.001:
		return
	var cadera : int = _h.get("Hips", -1)
	var p := Vector3.ZERO
	if cadera >= 0:
		p = to_local(_esq.to_global(_esq.get_bone_global_pose(cadera).origin))
	var t : Transform = transform
	var antes : Vector3 = t.basis.xform(p)
	t.basis = t.basis.scaled(Vector3(f, f, f))
	t.origin += antes - t.basis.xform(p)
	transform = t


# Lista de sedas ya usadas en ESTA carrera (se reinicia al recargar la pista).
func _registro_sedas():
	var escena = get_tree().current_scene
	var clave = "bdg_sedas_" + (str(escena.get_instance_id()) if escena else "0")
	var raiz = get_tree().root
	if not raiz.has_meta(clave):
		raiz.set_meta(clave, {"colores": [], "parejas": [], "disenos": []})
	return raiz.get_meta(clave)


func _pintar():
	var c_mangas = color_2 if mangas_color_2 else color_1
	var c_otro = color_1 if mangas_color_2 else color_2
	if _mats.has("Cuerpo"):
		_seda(_mats["Cuerpo"], color_1, color_2, diseno_cuerpo)
	if _mats.has("Mangas"):
		_seda(_mats["Mangas"], c_mangas, c_otro, diseno_mangas)
	_liso("Casco", color_casco, 0.35)
	_liso("Pantalon", color_pantalon, 0.7)
	_liso("Guantes", color_guantes, 0.6)
	_liso("Botas", color_botas, 0.3)
	_liso("Latigo", color_latigo, 0.5)


func _seda(s, c1, c2, diseno):
	s.set_shader_param("color_1", c1)
	s.set_shader_param("color_2", c2)
	s.set_shader_param("diseno", diseno)
	s.set_shader_param("cantidad", cantidad_diseno)
	s.set_shader_param("aspereza", aspereza_seda)


func _liso(nombre, color, aspereza):
	if not _mats.has(nombre):
		return
	var m = _mats[nombre]
	m.albedo_color = color
	m.roughness = aspereza


func _pintar_latigo(n):
	if n is MeshInstance and n.material_override != _mats["Latigo"]:
		n.material_override = _mats["Latigo"]
	for h in n.get_children():
		_pintar_latigo(h)


func _es_del_jugador() -> bool:
	var n = get_parent()
	while n != null:
		if n.name == "Enrutador_Caballo1":
			return true
		n = n.get_parent()
	return false
