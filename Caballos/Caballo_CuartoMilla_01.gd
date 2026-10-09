tool
extends Spatial
# Caballo_CuartoMilla_01.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Va en la raíz del Caballo_CuartoMilla_01 (.glb).
# Galope de carrera por script, igual que el del árabe: arranca suave y
# acelera en 3 etapas. Todo se ajusta en el Inspector. Ángulos en grados.
# Diferencia con el árabe: las patas se paran derechas solas (se calcula
# al arrancar), porque este modelo viene en pose de paso, no parado.

export var activo := true

# ---------- ETAPAS (arranque) ----------
export var usar_etapas := true
export var segundos_por_etapa := 3.0
export var trancos_etapa_1 := 1.6
export var trancos_etapa_2 := 2.0
export var trancos_etapa_3 := 2.4
export var fuerza_etapa_1 := 0.7
export var fuerza_etapa_2 := 0.85
export var fuerza_etapa_3 := 1.0
export var repetir_etapas := true   # vuelve a empezar al terminar (para probar)

# ---------- PATAS ----------
export var enderezar_patas := 1.0       # 1 = patas paradas derechas; 0 = como vino de Tripo
export var enderezar_cuello := 1.0      # 1 = cabeza mirando al frente; 0 = girada de lado como vino de Tripo
export var alcance_delanteras := 34.0   # cuánto se estiran adelante/atrás
export var alcance_traseras := 30.0
export var doblar_codo := 10.0
export var doblar_rodilla_delantera := 60.0
export var doblar_menudillo_delantero := 25.0
export var doblar_babilla := 25.0
export var doblar_corvejon := 50.0
export var doblar_menudillo_trasero := 25.0
export var amortiguar_apoyo := 20.0     # cuánto ceden las delanteras al apoyar
export var amortiguar_traseras := 4.0   # cuánto ceden las traseras al apoyar
export var tiempo_apoyo := 0.30         # parte del tranco con el casco en el suelo
# Cuánto después pisa la pata derecha que la izquierda (parte del tranco).
# Más alto = se nota más que llegan al piso una seguida de la otra.
export var separar_delanteras := 0.22
export var separar_traseras := 0.12
# Cuánto del vaivén de la pata sale del hombro/cadera; el resto sale del codo/babilla.
# Menos hombro = la pata se estira sin deformar el pecho ni las ancas.
export var reparto_hombro := 0.45
export var reparto_cadera := 0.6
# Forma de las dos delanteras paradas (las dos quedan iguales, así doblan igual).
# Brazo: del hombro al codo, hacia adelante. Antebrazo y caña quedan derechos.
export var angulo_brazo := 10.0
export var angulo_cuartilla := 25.0
# Forma de las dos traseras paradas. Muslo: de la cadera a la babilla, hacia
# adelante. Pierna: de la babilla al corvejón, hacia atrás. La caña queda derecha.
export var angulo_muslo := 28.0
export var angulo_pierna := 28.0
# Tripo hizo una pata más larga que su pareja (la que venía estirada).
# 1 = las dos del mismo largo; 0 = como vinieron de Tripo.
export var igualar_largo := 1.0

# ---------- CUERPO ----------
export var rebote_cuerpo := 0.012       # cuánto sube y baja el lomo (en tamaño del modelo)
export var bajar_cuerpo := 0.0          # baja todo el cuerpo (en tamaño del modelo)
export var alargar_cuerpo := 1.0 setget _poner_alargar_cuerpo   # más de 1 = caballo más largo (corre pecho, cuello y patas de adelante)
export var alzar_cuerpo := 1.0 setget _poner_alzar_cuerpo       # más de 1 = patas más largas: el caballo queda más alto
export var cabeceo_cuello := 10.0       # el cuello sube y baja con el galope
export var cabeceo_cabeza := 6.0        # la cabeza acompaña al cuello
export var estirar_cuello := 25.0       # cuello hacia adelante
export var subir_nariz := 10.0          # levanta la nariz para mirar al frente
export var mover_cola := 18.0           # la cola sube y baja con el galope
export var mecer_cola := 10.0           # la cola se mece de lado a lado
export var bajar_cola := 10.0           # negativo = la sube

# ---------- HUESOS DE ESTE MODELO ----------
export var hueso_cuello := "bone_6"
export var hueso_cabeza := "bone_9"
export var hueso_cola_1 := "Tail_0"
export var hueso_cola_2 := "Tail_1"
export var hueso_cola_3 := "bone_32"

# ---------- EN LA PISTA (igual que el árabe) ----------
export var seguir_velocidad := true
export var velocidad_crucero := 20.0
export var trancos_crucero := 2.1
export var velocidad_tope := 30.0
export var trancos_tope := 2.8
export var velocidad_minima := 1.0
export var suavizado_galope := 3.0
export var desfase_jinete := 0.62
export var variacion_ritmo := 0.05
export var zancada_lenta := 0.7
export var zancada_tope := 1.3

var _esq : Skeleton
var _h := {}
var _eje := {}          # eje de giro (de costado) de cada hueso, en su propio espacio
var _neutro := {}
var _doblez := {}       # doblez fija de rodilla/corvejón para emparejar el largo de las patas
var _fijo := {}         # giro fijo de cada articulación de la pata para la forma pareja
var _reposo := {}       # ángulo y largo de cada tramo de la pata como vino de Tripo
var _escala := {}       # hueso -> acortado de su tramo (para igualar el largo)
var _anula := {}        # hueso -> deshace el acortado del hueso de arriba
var _factor := {}       # hueso -> cuánto se estiró o acortó su tramo
var _i_frente := -1     # hueso donde empieza la parte de adelante (pecho, cuello y patas delanteras)
var _corrimiento_frente := Vector3.ZERO
var _arriba_raiz := Vector3.UP
var _subir_patas := 0.0  # lo que hay que subir el cuerpo para que los cascos no se hundan
var _cadena_cuello := []   # huesos del cuello, de la base a la cabeza
var _eje_arriba := {}      # eje vertical de cada hueso del cuello, en su propio espacio
var _giro_cuello := 0.0    # grados que hay que girar el cuello para que mire al frente
var _adelante := 1.0     # +1 o -1: hacia donde gira "adelante" en este esqueleto
var _t := 0.0
var _fase := 0.0
var _enrutador = null
var _jinete = null
var _ultimo_offset := 0.0
var _vel := 0.0
var _trancos_suaves := 0.0
var _fuerza_suave := 0.0
var _ritmo_propio := 1.0
var _estirar := 1.0

const _PATAS := ["0_Left_Limb", "0_Right_Limb", "1_Left_Limb", "1_Right_Limb"]
# Orden del galope de carrera: trasera izq, trasera der, delantera izq, delantera der
const _DESFASE := {"1_Left_Limb": 0.0, "1_Right_Limb": 0.12,
		"0_Left_Limb": 0.32, "0_Right_Limb": 0.44}


func _ready():
	_fase = randf()
	_ritmo_propio = rand_range(1.0 - variacion_ritmo, 1.0 + variacion_ritmo)
	_preparar()


# Al cambiar estos dos valores en el Inspector se vuelve a armar el caballo (se ve al instante)
func _poner_alargar_cuerpo(v):
	alargar_cuerpo = v
	if _esq != null:
		_preparar()


func _poner_alzar_cuerpo(v):
	alzar_cuerpo = v
	if _esq != null:
		_preparar()


func arrancar():
	_t = 0.0


func _preparar():
	_esq = _buscar_esqueleto(self)
	if _esq == null:
		return
	for ap in _buscar_todos(self, "AnimationPlayer"):
		ap.stop()
	for i in _esq.get_bone_count():
		_esq.set_bone_pose(i, Transform())
	var nombres := ["Root", hueso_cuello, hueso_cabeza, hueso_cola_1, hueso_cola_2, hueso_cola_3]
	for p in _PATAS:
		for k in 5:
			nombres.append(p + "_" + str(k))
	for n in nombres:
		_h[n] = _hueso(n)
	# Eje de costado: el promedio del eje Z de los huesos de las patas
	var costado := Vector3.ZERO
	var abajo := Vector3.ZERO
	for p in _PATAS:
		for k in 4:
			var i = _h.get(p + "_" + str(k), -1)
			if i >= 0:
				costado += _esq.get_bone_global_pose(i).basis.z.normalized()
		var a = _h.get(p + "_0", -1)
		var b = _h.get(p + "_4", _h.get(p + "_3", -1))
		if a >= 0 and b >= 0:
			abajo += (_esq.get_bone_global_pose(b).origin - _esq.get_bone_global_pose(a).origin).normalized()
	costado = costado.normalized()
	# "Abajo" de verdad: el abajo del modelo (su eje Y), visto desde el esqueleto
	var rel : Transform = global_transform.affine_inverse() * _esq.global_transform
	var abajo_modelo : Vector3 = (rel.basis.inverse() * Vector3.DOWN).normalized()
	if abajo_modelo.dot(abajo) > 0.5:
		abajo = abajo_modelo
	else:
		abajo = (abajo - costado * abajo.dot(costado)).normalized()
	# el costado queda acostado del todo (sin inclinación)
	costado = (costado - abajo * costado.dot(abajo)).normalized()
	for n in _h:
		var i = _h[n]
		if i >= 0:
			_eje[n] = (_esq.get_bone_global_pose(i).basis.inverse() * costado).normalized()
	# Hacia adelante: de la cola a la cabeza
	var ic = _h.get(hueso_cabeza, -1)
	var it = _h.get(hueso_cola_1, -1)
	if ic >= 0 and it >= 0:
		var fr : Vector3 = _esq.get_bone_global_pose(ic).origin - _esq.get_bone_global_pose(it).origin
		_adelante = 1.0 if costado.cross(abajo).dot(fr) >= 0.0 else -1.0
	# Cuello derecho: la cabeza viene girada de lado; se calcula cuánto
	_cadena_cuello = []
	var ib = _h.get(hueso_cuello, -1)
	var n_c = ic
	while n_c >= 0 and n_c != ib:
		n_c = _esq.get_bone_parent(n_c)
		if n_c >= 0:
			_cadena_cuello.push_front(n_c)
	if n_c != ib:
		_cadena_cuello = [ib] if ib >= 0 else []
	var frente := Vector3.ZERO
	var atras := Vector3.ZERO
	for p in _PATAS:
		var a0 = _h.get(p + "_0", -1)
		if a0 >= 0:
			if p.begins_with("0"):
				frente += _esq.get_bone_global_pose(a0).origin
			else:
				atras += _esq.get_bone_global_pose(a0).origin
	var cuerpo : Vector3 = frente - atras
	cuerpo = (cuerpo - abajo * cuerpo.dot(abajo)).normalized()
	if ib >= 0 and ic >= 0:
		var mira : Vector3 = _esq.get_bone_global_pose(ic).origin - _esq.get_bone_global_pose(ib).origin
		mira = (mira - abajo * mira.dot(abajo)).normalized()
		_giro_cuello = rad2deg(atan2(-abajo.dot(mira.cross(cuerpo)), mira.dot(cuerpo)))
	for i in _cadena_cuello:
		_eje_arriba[i] = (_esq.get_bone_global_pose(i).basis.inverse() * (-abajo)).normalized()
	for n_cola in [hueso_cola_1, hueso_cola_2, hueso_cola_3]:
		var i_cola = _h.get(n_cola, -1)
		if i_cola >= 0:
			_eje_arriba[i_cola] = (_esq.get_bone_global_pose(i_cola).basis.inverse() * (-abajo)).normalized()
	var r = _h.get("Root", -1)
	if r >= 0:
		_arriba_raiz = _esq.get_bone_global_pose(r).basis.inverse() * (-abajo)
	# Patas paradas.
	# Cada pata toma la misma forma que su pareja (mismos largos y ángulos),
	# así las dos doblan igual al galopar.
	# Las delanteras mandan la altura: si una queda más larga se agacha un poco
	# en el codo; las traseras se estiran o se agachan hasta llegar al mismo piso.
	var adel : Vector3 = costado.cross(abajo).normalized() * _adelante
	# Cuerpo más largo: la parte de adelante se corre hacia la cabeza
	_corrimiento_frente = Vector3.ZERO
	_i_frente = _hueso("Spine_2")
	if _i_frente >= 0 and abs(alargar_cuerpo - 1.0) > 0.001:
		var largo_cuerpo : float = (frente - atras).length() * 0.5
		var mover : Vector3 = adel * (largo_cuerpo * (alargar_cuerpo - 1.0))
		_corrimiento_frente = _esq.get_bone_global_pose(_i_frente).basis.inverse() * mover
	for i_b in _esq.get_bone_count():
		_esq.set_bone_pose(i_b, Transform())
	_fijo = {}
	_escala = {}
	_anula = {}
	_factor = {}
	var con_forma := []
	for par in [["0_Left_Limb", "0_Right_Limb"], ["1_Left_Limb", "1_Right_Limb"]]:
		var medidas := 0
		for p in par:
			if _medir_reposo(p, adel, abajo):
				medidas += 1
		if medidas == 2:
			_igualar_largo(par[0], par[1], abajo)
			con_forma += par
	# Patas más largas (Alzar Cuerpo): se estiran los tramos de abajo de las 4 patas
	if abs(alzar_cuerpo - 1.0) > 0.001:
		for p in con_forma:
			for k in range(1, 4):
				var i_t = _h.get(p + "_" + str(k), -1)
				var hijo_t = _h.get(p + "_" + str(k + 1), -1)
				if i_t < 0 or hijo_t < 0:
					continue
				var f_t : float = _factor.get(i_t, 1.0) * alzar_cuerpo
				var d_t : Vector3 = _esq.get_bone_rest(hijo_t).origin.normalized()
				var e_t := f_t - 1.0
				var s_t := Basis(Vector3(1, 0, 0) + d_t * (d_t.x * e_t), Vector3(0, 1, 0) + d_t * (d_t.y * e_t), Vector3(0, 0, 1) + d_t * (d_t.z * e_t))
				_escala[i_t] = s_t
				_factor[i_t] = f_t
				var rb_t : Basis = _esq.get_bone_rest(hijo_t).basis
				_anula[hijo_t] = rb_t.inverse() * s_t.inverse() * rb_t
				_reposo[p][1][k] *= alzar_cuerpo
	var alturas := {}
	for p in _PATAS:
		_doblez[p] = 0.0
		_neutro[p] = 0.0
		if con_forma.has(p):
			_fijo[p] = _forma(p, 0.0)
			_poner_fijo(p)
		else:
			_neutro[p] = _angulo_vertical(p, 0.0, costado, abajo)
		alturas[p] = _altura_casco(p, abajo)
	var objetivo := -INF
	for p in alturas:
		if p.begins_with("0") or not con_forma.has("0_Left_Limb"):
			objetivo = max(objetivo, alturas[p])
	for p in _PATAS:
		if _fijo.has(p):
			if abs(alturas[p] - objetivo) < 0.0005:
				continue
			var bajar : float = objetivo - alturas[p]
			for _k in 6:
				_fijo[p] = _forma(p, bajar)
				_poner_fijo(p)
				bajar += objetivo - _altura_casco(p, abajo)
			continue
		if alturas[p] >= objetivo - 0.0005:
			continue
		var bajo := 0.0
		var alto := 70.0
		for _k in 18:
			var medio := (bajo + alto) * 0.5
			_neutro[p] = _angulo_vertical(p, medio, costado, abajo)
			if _altura_casco(p, abajo) < objetivo:
				bajo = medio
			else:
				alto = medio
		_doblez[p] = (bajo + alto) * 0.5
		_neutro[p] = _angulo_vertical(p, _doblez[p], costado, abajo)
	for i_b in _esq.get_bone_count():
		_esq.set_bone_pose(i_b, Transform())
	# Cuánto subir el cuerpo para que los cascos no se hundan
	var antes := 0.0
	var cuenta := 0
	for p in _PATAS:
		var b = _h.get(p + "_4", _h.get(p + "_3", -1))
		if b >= 0:
			antes += _esq.get_bone_global_pose(b).origin.dot(-abajo)
			cuenta += 1
	if cuenta > 0:
		_subir_patas = antes / cuenta - objetivo


func _process(delta):
	if not activo:
		return
	if _esq == null:
		_preparar()
		if _esq == null:
			return
	_t += delta
	var trancos := trancos_etapa_3
	var fuerza := fuerza_etapa_3
	if usar_etapas:
		var total := segundos_por_etapa * 3.0
		if repetir_etapas and _t > total + segundos_por_etapa:
			_t = 0.0
		var e := clamp(_t / segundos_por_etapa, 0.0, 2.0)
		var tr := [trancos_etapa_1, trancos_etapa_2, trancos_etapa_3]
		var fu := [fuerza_etapa_1, fuerza_etapa_2, fuerza_etapa_3]
		var i := int(min(floor(e), 1.0))
		var m := smoothstep(0.0, 1.0, e - i)
		trancos = lerp(tr[i], tr[i + 1], m)
		fuerza = lerp(fu[i], fu[i + 1], m)
		# a más velocidad, zancada más larga
		_estirar = lerp(zancada_lenta, zancada_tope, e / 2.0)
	var en_pista := false
	if seguir_velocidad and not Engine.editor_hint:
		_pista(delta)
		if _enrutador != null:
			en_pista = true
			trancos = _trancos_suaves
			fuerza = _fuerza_suave
	_fase = fmod(_fase + delta * trancos * _ritmo_propio, 1.0)
	if en_pista:
		_jinete_al_ritmo(trancos * _ritmo_propio)
	_poner_pose(fuerza)


func _poner_pose(fuerza : float):
	# Patas
	for p in _PATAS:
		var desfase : float = _DESFASE[p]
		if p == "0_Right_Limb":
			desfase = _DESFASE["0_Left_Limb"] + separar_delanteras
		elif p == "1_Right_Limb":
			desfase = _DESFASE["1_Left_Limb"] + separar_traseras
		var q := fmod(_fase - desfase + 2.0, 1.0)
		var delantera : bool = p.begins_with("0")
		var alcance := (alcance_delanteras if delantera else alcance_traseras) * _estirar
		var s := 0.0
		var f := 0.0
		var c := 0.0
		if q < tiempo_apoyo:
			s = alcance * cos(PI * q / tiempo_apoyo)
			c = sin(PI * q / tiempo_apoyo)
		else:
			var u := (q - tiempo_apoyo) / (1.0 - tiempo_apoyo)
			s = -alcance * cos(PI * u)
			f = pow(sin(PI * u), 1.5)
		var k := amortiguar_apoyo if delantera else amortiguar_traseras
		var dob := []
		if delantera:
			dob = [0.0, doblar_codo * f + k * 0.3 * c,
					-doblar_rodilla_delantera * f - k * 0.3 * c,
					-doblar_menudillo_delantero * f + k * c]
		else:
			dob = [0.0, -doblar_babilla * f - k * 0.4 * c,
					doblar_corvejon * f + k * 0.6 * c,
					-doblar_menudillo_trasero * f + k * c]
		for n in 4:
			var fijo := 0.0
			if _fijo.has(p):
				fijo = _fijo[p][n] * enderezar_patas
			elif n == 0:
				fijo = _neutro[p] * enderezar_patas
			elif n == 2:
				fijo = (-1.0 if delantera else 1.0) * _doblez[p] * enderezar_patas * _adelante
			var reparto := reparto_hombro if delantera else reparto_cadera
			var vaiven := 0.0
			if n == 0:
				vaiven = s * reparto
			elif n == 1:
				vaiven = s * (1.0 - reparto)
			var ang : float = fijo + (vaiven * fuerza + dob[n] * fuerza) * _adelante
			_girar(p + "_" + str(n), ang)
		var i_casco = _h.get(p + "_4", -1)
		if _anula.has(i_casco):
			_pose_hueso(i_casco, Basis())
	# Cuerpo: baja al apoyar y sube en el vuelo
	# (el lomo baja cuando apoyan las delanteras)
	var sube := sin(TAU * (_fase - _retraso_rebote())) * rebote_cuerpo * fuerza
	var i_root = _h.get("Root", -1)
	if i_root >= 0:
		_esq.set_bone_pose(i_root, Transform(Basis(), _arriba_raiz * (sube - bajar_cuerpo + _subir_patas * enderezar_patas)))
	if _i_frente >= 0:
		_esq.set_bone_pose(_i_frente, Transform(Basis(), _corrimiento_frente))
	_girar(hueso_cuello, -_adelante * (estirar_cuello + sin(TAU * (_fase - 0.28)) * cabeceo_cuello * fuerza))
	_enderezar_cuello()
	_girar(hueso_cabeza, _adelante * (subir_nariz + sin(TAU * (_fase - 0.4)) * cabeceo_cabeza * fuerza))
	_girar(hueso_cola_1, _adelante * (bajar_cola + sin(TAU * _fase) * mover_cola * fuerza))
	_girar(hueso_cola_2, _adelante * sin(TAU * (_fase - 0.15)) * mover_cola * fuerza)
	_girar(hueso_cola_3, _adelante * sin(TAU * (_fase - 0.3)) * mover_cola * 0.5 * fuerza)
	# la cola se mece de lado (medio tranco de retraso entre un hueso y el siguiente)
	var lado_cola := [sin(TAU * _fase * 0.5), sin(TAU * (_fase * 0.5 - 0.1)), sin(TAU * (_fase * 0.5 - 0.2))]
	var k_cola := 0
	for n_cola in [hueso_cola_1, hueso_cola_2, hueso_cola_3]:
		var i_cola = _h.get(n_cola, -1)
		if i_cola >= 0 and _eje_arriba.has(i_cola):
			var actual : Transform = _esq.get_bone_pose(i_cola)
			var giro := deg2rad(lado_cola[k_cola] * mecer_cola * fuerza)
			_esq.set_bone_pose(i_cola, Transform(Basis(_eje_arriba[i_cola], giro) * actual.basis, actual.origin))
		k_cola += 1


# Reparte el giro de lado entre los huesos del cuello, para que la cabeza
# mire al frente sin quebrar el cuello en un solo punto.
func _enderezar_cuello():
	var n := _cadena_cuello.size()
	if n == 0 or abs(_giro_cuello * enderezar_cuello) < 0.01:
		return
	var parte := deg2rad(_giro_cuello * enderezar_cuello) / n
	var base_cuello = _h.get(hueso_cuello, -1)
	for i in _cadena_cuello:
		var actual := Transform()
		if i == base_cuello:
			actual = _esq.get_bone_pose(i)
		_esq.set_bone_pose(i, Transform(Basis(_eje_arriba[i], parte) * actual.basis, actual.origin))


# Pone la pata con la rodilla/corvejón doblado "doblez" grados y devuelve el
# giro de arriba que la deja vertical. Deja la pose puesta.
func _angulo_vertical(p, doblez : float, costado : Vector3, abajo : Vector3) -> float:
	var a = _h.get(p + "_0", -1)
	var r = _h.get(p + "_2", -1)
	var b = _h.get(p + "_4", _h.get(p + "_3", -1))
	if a < 0 or b < 0:
		return 0.0
	_esq.set_bone_pose(a, Transform())
	if r >= 0:
		var signo := -1.0 if p.begins_with("0") else 1.0
		_esq.set_bone_pose(r, Transform(Basis(_eje[p + "_2"], deg2rad(signo * doblez * _adelante)), Vector3.ZERO))
	var v : Vector3 = _esq.get_bone_global_pose(b).origin - _esq.get_bone_global_pose(a).origin
	v = (v - costado * v.dot(costado)).normalized()
	var ang := rad2deg(atan2(costado.dot(v.cross(abajo)), v.dot(abajo)))
	_esq.set_bone_pose(a, Transform(Basis(_eje[p + "_0"], deg2rad(ang)), Vector3.ZERO))
	return ang


func _altura_casco(p, abajo : Vector3) -> float:
	var b = _h.get(p + "_4", _h.get(p + "_3", -1))
	if b < 0:
		return 0.0
	return _esq.get_bone_global_pose(b).origin.dot(-abajo)


# Guarda el ángulo (hacia adelante) y el largo de los 4 tramos de la pata,
# tal como vino de Tripo. Hay que llamarla con la pata sin girar.
func _medir_reposo(p, adel : Vector3, abajo : Vector3) -> bool:
	var angulos := []
	var largos := []
	var largos_3d := []
	for k in 4:
		var a = _h.get(p + "_" + str(k), -1)
		var b = _h.get(p + "_" + str(k + 1), -1)
		if a < 0 or b < 0:
			return false
		var v : Vector3 = _esq.get_bone_global_pose(b).origin - _esq.get_bone_global_pose(a).origin
		angulos.append(rad2deg(atan2(v.dot(adel), v.dot(abajo))))
		largos.append(Vector2(v.dot(adel), v.dot(abajo)).length())
		largos_3d.append(v.length())
	_reposo[p] = [angulos, largos, largos_3d]
	return true


# Ángulos de la forma pareja (hacia adelante +, hacia atrás -), en grados
func _angulos_forma(p) -> Array:
	if p.begins_with("0"):
		return [angulo_brazo, 0.0, 0.0, angulo_cuartilla]
	return [angulo_muslo, -angulo_pierna, 0.0, angulo_cuartilla]


# Giro de cada articulación para que la pata quede con la forma pareja.
# "bajar" agacha la pata (o la estira si es negativo) sin correr el menudillo:
# las delanteras en el codo, las traseras en la babilla y el corvejón.
func _forma(p, bajar : float) -> Array:
	var r : Array = _reposo[p][0]
	var l : Array = _reposo[p][1]
	var t : Array = _angulos_forma(p)
	var delantera : bool = p.begins_with("0")
	if abs(bajar) > 0.00001:
		var t0 := deg2rad(t[0])
		var t1 := deg2rad(t[1])
		var lc : float = l[1]
		if delantera:
			lc += l[2]
		var x : float = l[0] * sin(t0) + lc * sin(t1)
		var y : float = l[0] * cos(t0) + lc * cos(t1) - bajar
		var d : float = clamp(sqrt(x * x + y * y), abs(l[0] - lc) + 0.0001, l[0] + lc - 0.0001)
		var al := acos(clamp((l[0] * l[0] + d * d - lc * lc) / (2.0 * l[0] * d), -1.0, 1.0))
		var th := atan2(x, y) + al
		var psi := atan2(x - l[0] * sin(th), y - l[0] * cos(th))
		t[0] = rad2deg(th)
		t[1] = rad2deg(psi)
		if delantera:
			t[2] = rad2deg(psi)
	var giros := []
	var antes := 0.0
	for k in 4:
		var d_k : float = t[k] - r[k]
		giros.append((d_k - antes) * _adelante)
		antes = d_k
	return giros


func _poner_fijo(p):
	for k in 4:
		var i = _h.get(p + "_" + str(k), -1)
		if i >= 0:
			_pose_hueso(i, Basis(_eje[p + "_" + str(k)], deg2rad(_fijo[p][k])))
	var i_casco = _h.get(p + "_4", -1)
	if _anula.has(i_casco):
		_pose_hueso(i_casco, Basis())


# La pata más larga copia el largo de su pareja: los tres tramos de abajo
# quedan iguales (se acortan a lo largo, sin afinarlos). El de arriba (metido
# en el cuerpo) se ajusta para que los dos cascos lleguen al mismo piso aunque
# Tripo puso un hombro o una cadera más alta que la otra.
func _igualar_largo(pa, pb, abajo : Vector3):
	var suma_a := 0.0
	var suma_b := 0.0
	for k in 4:
		suma_a += _reposo[pa][2][k]
		suma_b += _reposo[pb][2][k]
	var modelo = pa if suma_a <= suma_b else pb
	var otra = pb if suma_a <= suma_b else pa
	var t := []
	for a in _angulos_forma(modelo):
		t.append(deg2rad(a))
	var factores := [1.0, 1.0, 1.0, 1.0]
	var alto_modelo : float = _esq.get_bone_global_pose(_h[modelo + "_0"]).origin.dot(-abajo)
	var alto_otra : float = _esq.get_bone_global_pose(_h[otra + "_0"]).origin.dot(-abajo)
	var resto := 0.0
	for k in range(1, 4):
		factores[k] = _reposo[modelo][2][k] / _reposo[otra][2][k]
		alto_modelo -= _reposo[modelo][1][k] * cos(t[k])
		alto_otra -= _reposo[otra][1][k] * factores[k] * cos(t[k])
	alto_modelo -= _reposo[modelo][1][0] * cos(t[0])
	# el brazo de la otra tiene que bajar lo que falta para llegar al mismo suelo
	factores[0] = clamp((alto_otra - alto_modelo) / max(_reposo[otra][1][0] * cos(t[0]), 0.001), 0.75, 1.3)
	for k in 4:
		var f : float = lerp(1.0, factores[k], clamp(igualar_largo, 0.0, 1.0))
		if abs(f - 1.0) < 0.001:
			continue
		var i = _h[otra + "_" + str(k)]
		var hijo = _h[otra + "_" + str(k + 1)]
		var d : Vector3 = _esq.get_bone_rest(hijo).origin.normalized()
		var e := f - 1.0
		var s := Basis(Vector3(1, 0, 0) + d * (d.x * e), Vector3(0, 1, 0) + d * (d.y * e), Vector3(0, 0, 1) + d * (d.z * e))
		_escala[i] = s
		_factor[i] = f
		var rb : Basis = _esq.get_bone_rest(hijo).basis
		_anula[hijo] = rb.inverse() * s.inverse() * rb
		_reposo[otra][1][k] *= f


# Pone el giro de un hueso respetando el acortado de su tramo
func _pose_hueso(i : int, giro : Basis):
	var b := giro
	if _escala.has(i):
		b = b * _escala[i]
	if _anula.has(i):
		b = _anula[i] * b
	_esq.set_bone_pose(i, Transform(b, Vector3.ZERO))


# Desfase del rebote del lomo: sigue a las delanteras cuando se separan más
func _retraso_rebote() -> float:
	return 0.62 + 0.6 * (separar_delanteras - 0.12)


# ---------- utilidades ----------
func _girar(nombre, grados : float):
	var i = _h.get(nombre, -1)
	if i < 0:
		return
	_pose_hueso(i, Basis(_eje[nombre], deg2rad(grados)))


func _hueso(fin : String) -> int:
	for i in _esq.get_bone_count():
		var n : String = _esq.get_bone_name(i)
		if n == fin or n.ends_with(":" + fin) or n.ends_with("_" + fin):
			return i
	return -1


# ---------- EN LA PISTA ----------
func _pista(delta):
	if _enrutador == null:
		_enrutador = _buscar_enrutador()
		if _enrutador == null:
			return
		_jinete = _buscar_jinete(self)
		_ultimo_offset = _enrutador.offset
		usar_etapas = false
	var o : float = _enrutador.offset
	var avance : float = o - _ultimo_offset
	_ultimo_offset = o
	if delta > 0.0 and abs(avance) < 50.0:
		_vel = lerp(_vel, abs(avance) / delta, clamp(delta * 5.0, 0.0, 1.0))
	var t_obj := 0.0
	var f_obj := 0.0
	if _vel > velocidad_minima:
		if _vel <= velocidad_crucero:
			t_obj = trancos_crucero * _vel / max(velocidad_crucero, 0.1)
		else:
			var x : float = clamp((_vel - velocidad_crucero) / max(velocidad_tope - velocidad_crucero, 0.1), 0.0, 1.0)
			t_obj = lerp(trancos_crucero, trancos_tope, x)
		f_obj = clamp(_vel / max(velocidad_crucero * 0.6, 0.1), 0.0, 1.0) * fuerza_etapa_3
	var k : float = clamp(delta * suavizado_galope, 0.0, 1.0)
	_trancos_suaves = lerp(_trancos_suaves, t_obj, k)
	_fuerza_suave = lerp(_fuerza_suave, f_obj, k)
	var e_obj := zancada_lenta
	if _vel <= velocidad_crucero:
		e_obj = lerp(zancada_lenta, 1.0, clamp(_vel / max(velocidad_crucero, 0.1), 0.0, 1.0))
	else:
		var y : float = clamp((_vel - velocidad_crucero) / max(velocidad_tope - velocidad_crucero, 0.1), 0.0, 1.0)
		e_obj = lerp(1.0, zancada_tope, y)
	_estirar = lerp(_estirar, e_obj, k)


func _jinete_al_ritmo(trancos : float):
	if _jinete == null:
		return
	if trancos < 0.05:
		_jinete.trancos_por_segundo = 0.0
		return
	_jinete.trancos_por_segundo = trancos
	_jinete._t = fposmod(_fase - desfase_jinete - (_retraso_rebote() - 0.62), 1.0) / trancos


func _buscar_enrutador():
	var n = get_parent()
	while n != null:
		if n is PathFollow and n.name.begins_with("Enrutador_Caballo"):
			return n
		n = n.get_parent()
	return null


func _buscar_jinete(n):
	for h in n.get_children():
		if h.has_method("latigazo"):
			return h
		var r = _buscar_jinete(h)
		if r:
			return r
	return null


func _buscar_esqueleto(n):
	if n is Skeleton:
		for i in n.get_bone_count():
			if n.get_bone_name(i).ends_with("Spine_0"):
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
