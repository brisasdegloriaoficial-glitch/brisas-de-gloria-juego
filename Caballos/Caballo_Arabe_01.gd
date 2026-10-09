tool
extends Spatial
# Caballo_Galope.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Va en la raíz del Caballo_Arabe_01 (.glb).
# Galope de carrera por script: arranca suave y acelera en 3 etapas.
# Todo se ajusta en el Inspector. Ángulos en grados.

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
export var alcance_delanteras := 34.0   # cuánto se estiran adelante/atrás
export var alcance_traseras := 30.0
export var doblar_codo := 10.0
export var doblar_rodilla_delantera := 60.0
export var doblar_menudillo_delantero := 25.0
export var doblar_babilla := 25.0
export var doblar_corvejon := 50.0
export var doblar_menudillo_trasero := 25.0
export var amortiguar_apoyo := 20.0
export var tiempo_apoyo := 0.30         # parte del tranco con el casco en el suelo

# ---------- CUERPO ----------
export var rebote_cuerpo := 0.05        # metros
export var bajar_cuerpo := 0.10         # metros
export var cabeceo_cuello := 6.0
export var mover_cola := 15.0
export var estirar_cuello := 25.0      # cuello hacia adelante
export var subir_nariz := 10.0         # levanta la nariz para mirar al frente
export var bajar_cola := 10.0          # negativo = la sube

# ---------- EN LA PISTA (igual que el caballo americano) ----------
# El galope acompana la velocidad real del caballo en la pista.
export var seguir_velocidad := true
export var velocidad_crucero := 20.0        # velocidad normal de carrera
export var trancos_crucero := 2.1           # trancos por segundo a esa velocidad
export var velocidad_tope := 30.0           # con arreo y latigo a fondo
export var trancos_tope := 2.8              # trancos por segundo a tope
export var velocidad_minima := 1.0          # por debajo de esto se queda quieto
export var suavizado_galope := 3.0          # que tan rapido acompana los cambios
export var desfase_jinete := 0.62           # el cuerpo del jinete sube y baja con el lomo
export var variacion_ritmo := 0.05          # cada caballo galopa a su ritmo: 0.05 = hasta 5% mas rapido o mas lento
export var zancada_lenta := 0.7             # largo de la zancada a baja velocidad (1 = normal)
export var zancada_tope := 1.3              # largo de la zancada a toda velocidad: las patas se estiran mas

var _esq : Skeleton
var _h := {}
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
# Corrección calculada para este esqueleto: deja las 4 patas paradas parejas
const _NEUTRO := {
	"0_Left_Limb": [3.0, 13.3, -1.2, -8.0],
	"0_Right_Limb": [-3.0, -13.3, 1.2, 8.0],
	"1_Left_Limb": [9.5, 1.6, 6.8, -5.6],
	"1_Right_Limb": [-9.5, -1.6, -6.8, 5.6]}


func _ready():
	# Cada caballo arranca en un punto distinto de la zancada y con su
	# propio ritmo, para que no galopen todos al mismo paso.
	_fase = randf()
	_ritmo_propio = rand_range(1.0 - variacion_ritmo, 1.0 + variacion_ritmo)
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
	var nombres := ["Root", "Spine_8", "Head_3", "Tail_0", "Tail_1"]
	for p in _PATAS:
		for k in 4:
			nombres.append(p + "_" + str(k))
	for n in nombres:
		_h[n] = _hueso(n)


func _process(delta):
	if not activo:
		return
	if _esq == null:
		_preparar()
		if _esq == null:
			return
	_t += delta

	# Etapas: velocidad y fuerza
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

	# Patas
	for p in _PATAS:
		var q := fmod(_fase - _DESFASE[p] + 1.0, 1.0)
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
		var k := amortiguar_apoyo
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
			var ang : float = _NEUTRO[p][n] + (s if n == 0 else 0.0) * fuerza + dob[n] * fuerza
			_girar(p + "_" + str(n), ang)

	# Cuerpo: baja al apoyar y sube en el vuelo
	var sube := sin(TAU * (_fase - 0.62)) * rebote_cuerpo * fuerza
	var i_root = _h.get("Root", -1)
	if i_root >= 0:
		_esq.set_bone_pose(i_root, Transform(Basis(), Vector3(0, sube - bajar_cuerpo, 0)))
	_girar("Spine_8", estirar_cuello + sin(TAU * (_fase - 0.28)) * cabeceo_cuello * fuerza)
	_girar("Head_3", -subir_nariz)
	_girar("Tail_0", -bajar_cola + sin(TAU * _fase) * mover_cola * fuerza)
	_girar("Tail_1", sin(TAU * (_fase - 0.15)) * mover_cola * fuerza)


# ---------- utilidades ----------
func _girar(nombre, grados : float):
	var i = _h.get(nombre, -1)
	if i < 0:
		return
	_esq.set_bone_pose(i, Transform(Basis(Vector3(0, 0, deg2rad(grados))), Vector3.ZERO))


func _hueso(fin : String) -> int:
	for i in _esq.get_bone_count():
		var n : String = _esq.get_bone_name(i)
		if n == fin or n.ends_with(":" + fin) or n.ends_with("_" + fin):
			return i
	push_warning("Caballo_Galope: no encontré el hueso " + fin)
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
	# Velocidad real: lo que avanzo el carril desde el cuadro anterior
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
	# Largo de la zancada: corta al ir lento, normal a velocidad de
	# carrera y mas estirada al acelerar a fondo.
	var e_obj := zancada_lenta
	if _vel <= velocidad_crucero:
		e_obj = lerp(zancada_lenta, 1.0, clamp(_vel / max(velocidad_crucero, 0.1), 0.0, 1.0))
	else:
		var y : float = clamp((_vel - velocidad_crucero) / max(velocidad_tope - velocidad_crucero, 0.1), 0.0, 1.0)
		e_obj = lerp(1.0, zancada_tope, y)
	_estirar = lerp(_estirar, e_obj, k)


# El jinete sube y baja al mismo paso que el caballo.
func _jinete_al_ritmo(trancos : float):
	if _jinete == null:
		return
	if trancos < 0.05:
		_jinete.trancos_por_segundo = 0.0
		return
	_jinete.trancos_por_segundo = trancos
	_jinete._t = fposmod(_fase - desfase_jinete, 1.0) / trancos


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
