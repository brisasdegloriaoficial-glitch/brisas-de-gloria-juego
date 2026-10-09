tool
extends Spatial
# Caballo_Americano_01_Rigueado.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Va en la raíz del Caballo_Americano_01_Rigueado (.glb).
# Mismo galope del árabe, adaptado a los huesos bone_0 ... bone_53.
# Todo se ajusta en el Inspector. Ángulos en grados.

export var activo := true

# ---------- GIRO DE LOS HUESOS ----------
# Si las patas se abren hacia los lados en vez de ir adelante/atrás, cambia el eje.
export(int, "X", "Y", "Z") var eje := 2
export var invertir_delanteras := true
export var invertir_traseras := true
export var invertir_lado_derecho := false

# ---------- NÚMEROS DE HUESOS ----------
export var hueso_raiz := 0
# Orden de cada pata: arriba (balanceo), codo/babilla, rodilla/corvejón, menudillo
export(Array, int) var delantera_izq = [29, 31, 32, 33]
export(Array, int) var delantera_der = [23, 25, 26, 27]
export(Array, int) var trasera_izq = [49, 50, 51, 52]
export(Array, int) var trasera_der = [44, 45, 46, 47]
export(Array, int) var cola = [35, 36, 37, 38, 39, 40, 41, 42, 43]
export(Array, int) var cuello = [10, 11, 12, 13, 14, 15, 16]

# ---------- ETAPAS (arranque) ----------
export var usar_etapas := true
export var segundos_por_etapa := 3.0
export var trancos_etapa_1 := 1.6
export var trancos_etapa_2 := 2.0
export var trancos_etapa_3 := 2.4
export var fuerza_etapa_1 := 0.7
export var fuerza_etapa_2 := 0.85
export var fuerza_etapa_3 := 1.0
export var repetir_etapas := true

# ---------- ORDEN DE PISADA (0 a 1) ----------
# Más separados = cada pata cae más a destiempo de la otra
export var desfase_trasera_izq := 0.0
export var desfase_trasera_der := 0.15
export var desfase_delantera_izq := 0.35
export var desfase_delantera_der := 0.47

# ---------- PATAS ----------
export var alcance_delanteras := 25.0
export var alcance_traseras := 30.0
export var doblar_codo := 40.0
export var doblar_rodilla_delantera := 95.0
export var doblar_menudillo_delantero := 40.0
export var doblar_babilla := 35.0
export var doblar_corvejon := 70.0
export var doblar_menudillo_trasero := 25.0
export var amortiguar_apoyo := 20.0
export var tiempo_apoyo := 0.25

# ---------- CUERPO ----------
export var rebote_cuerpo := 0.05
export var bajar_cuerpo := 0.10
export var largo_cuello := 0.9         # menos de 1 = cuello más corto (prueba 0.85)
export var tamano_cabeza := 1.0        # más de 1 = cabeza más grande (prueba 1.1)
export var cabeceo_cuello := 14.0
export var desfase_cabeceo := 0.40     # 0.40 = el cuello baja con el vaiven, como el caballo hecho a mano
# Cuanto del vaiven lleva cada hueso del cuello, de la base a la cabeza.
# La base del cuello mueve casi todo; la cabeza solo acompana.
export(Array, float) var reparto_cuello = [0.4, 0.3, 0.2, 0.1, 0.0, 0.0, 0.0]
export var compensar_cabeza := 0.8     # la cabeza gira al reves para seguir mirando al frente
export var estirar_cuello := 10.0
export var subir_nariz := 25.0         # mas = la cabeza mira mas al frente
export var mover_cola := 20.0
export var bajar_cola := 10.0

# ---------- EN LA PISTA ----------
# Si el caballo va en un carril (Enrutador_CaballoN), el galope sigue la
# velocidad real del carril y el jinete sube y baja al mismo paso.
export var seguir_velocidad := true
export var velocidad_crucero := 20.0        # velocidad normal de carrera
export var trancos_crucero := 2.1           # trancos por segundo a esa velocidad
export var velocidad_tope := 30.0           # con arreo y latigo a fondo
export var trancos_tope := 2.8              # trancos por segundo a tope
export var velocidad_minima := 1.0          # por debajo de esto se queda quieto
export var suavizado_galope := 3.0          # que tan rapido acompana los cambios
export var variacion_ritmo := 0.05          # cada caballo galopa a su ritmo: 0.05 = hasta 5% mas rapido o mas lento
export var zancada_lenta := 0.7             # largo de la zancada a baja velocidad (1 = normal)
export var zancada_tope := 1.3              # largo de la zancada a toda velocidad: las patas se estiran mas
export var desfase_jinete := 0.62           # el cuerpo del jinete sube y baja con el lomo
export var brazos_con_el_cuello := true    # los brazos van atados al cuello por la rienda
# Tamano en la pista (1 = el largo del caballo viejo). Cada rival tiene el
# suyo, siempre el mismo para cada carril; el del jugador es el mas grande.
export var tamano_jugador := 1.25
export var tamano_rival_min := 0.92
export var tamano_rival_max := 1.08

var _esq : Skeleton
var _t := 0.0
var _fase := 0.0
var _enrutador = null
var _jinete = null
var _jockey = null
var _es_jugador := false
var _ultimo_offset := 0.0
var _vel := 0.0
var _trancos_suaves := 0.0
var _fuerza_suave := 0.0
var _brazos_base = null
var _codos_base := 0.0
var _empuje := 0.0
var _ritmo_propio := 1.0
var _estirar := 1.0


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
		_brazos_al_cuello(fuerza)

	# Patas: trasera izq, trasera der, delantera izq, delantera der
	_pata(trasera_izq, false, false, desfase_trasera_izq, fuerza)
	_pata(trasera_der, false, true, desfase_trasera_der, fuerza)
	_pata(delantera_izq, true, false, desfase_delantera_izq, fuerza)
	_pata(delantera_der, true, true, desfase_delantera_der, fuerza)

	# Cuerpo: baja al apoyar y sube en el vuelo
	if hueso_raiz >= 0 and hueso_raiz < _esq.get_bone_count():
		var sube := sin(TAU * (_fase - 0.62)) * rebote_cuerpo * fuerza
		_esq.set_bone_pose(hueso_raiz, Transform(Basis(), Vector3(0, sube - bajar_cuerpo, 0)))

	# Cuello repartido entre sus huesos; el último levanta la nariz y da el tamaño de la cabeza
	var nc : int = cuello.size()
	var vaiven : float = sin(TAU * (_fase - desfase_cabeceo)) * cabeceo_cuello * fuerza
	for i in nc:
		var peso := 0.0
		if i < reparto_cuello.size():
			peso = float(reparto_cuello[i])
		var ang : float = estirar_cuello / nc + vaiven * peso
		var esc := 1.0
		if i == 0:
			esc = largo_cuello
		if i == nc - 1:
			ang -= subir_nariz
			ang -= vaiven * compensar_cabeza
			esc = tamano_cabeza / max(largo_cuello, 0.1)
		_girar(cuello[i], ang, esc)

	# Cola en ola
	var nt : int = cola.size()
	for i in nt:
		var ang := (-bajar_cola + sin(TAU * (_fase - 0.05 * i)) * mover_cola * fuerza) / nt
		_girar(cola[i], ang)


# ---------- EN LA PISTA ----------
func _pista(delta):
	if _enrutador == null:
		_enrutador = _buscar_enrutador()
		if _enrutador == null:
			return
		_jinete = _buscar_jinete(self)
		_es_jugador = _enrutador.name == "Enrutador_Caballo1"
		_jockey = _enrutador.get_node_or_null("Jockey")
		_ultimo_offset = _enrutador.offset
		usar_etapas = false
		if _jinete and _es_jugador:
			_jinete.latigo_automatico = false
		scale = scale * _tamano_del_carril()
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
	# Latigazo del jugador con su boton (en 800 m no hay latigo)
	if _es_jugador and _jinete and Input.is_action_just_pressed("latigazo_derecho"):
		if _jockey == null or not ("modo_arreo_ritmo" in _jockey) or not _jockey.modo_arreo_ritmo:
			_jinete.latigazo()


# El jinete sube y baja al mismo paso que el caballo.
func _jinete_al_ritmo(trancos : float):
	if _jinete == null:
		return
	if trancos < 0.05:
		_jinete.trancos_por_segundo = 0.0
		return
	_jinete.trancos_por_segundo = trancos
	_jinete._t = fposmod(_fase - desfase_jinete, 1.0) / trancos


# Los brazos del jinete siguen al cuello: cuando el cuello baja y se
# estira, las manos van adelante; cuando sube, vuelven.
func _brazos_al_cuello(fuerza : float):
	if _jinete == null or not brazos_con_el_cuello:
		return
	if _brazos_base == null:
		_brazos_base = _jinete.brazos_adelante
		_codos_base = _jinete.doblar_codos
		_empuje = _jinete.empuje_brazos
		_jinete.empuje_brazos = 0.0
	var fb : float = -sin(TAU * (_fase - desfase_cabeceo)) * fuerza
	_jinete.brazos_adelante = _brazos_base + fb * _empuje
	_jinete.doblar_codos = _codos_base - fb * _empuje * 0.5


func _tamano_del_carril() -> float:
	if _es_jugador:
		return tamano_jugador
	var k := int(_enrutador.name.replace("Enrutador_Caballo", ""))
	var h : float = fposmod(k * 0.618034, 1.0)
	return lerp(tamano_rival_min, tamano_rival_max, h)


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


func _pata(huesos : Array, delantera : bool, derecha : bool, desfase : float, fuerza : float):
	var q := fmod(_fase - desfase + 1.0, 1.0)
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
		dob = [s, doblar_codo * f + k * 0.3 * c,
				-doblar_rodilla_delantera * f - k * 0.3 * c,
				-doblar_menudillo_delantero * f + k * c]
	else:
		dob = [s, -doblar_babilla * f - k * 0.4 * c,
				doblar_corvejon * f + k * 0.6 * c,
				-doblar_menudillo_trasero * f + k * c]
	var signo := 1.0
	if delantera and invertir_delanteras:
		signo = -signo
	if not delantera and invertir_traseras:
		signo = -signo
	if derecha and invertir_lado_derecho:
		signo = -signo
	for n in min(huesos.size(), dob.size()):
		_girar(huesos[n], dob[n] * fuerza * signo)


# ---------- utilidades ----------
func _girar(i : int, grados : float, esc := 1.0):
	if i < 0 or i >= _esq.get_bone_count():
		return
	var v := Vector3(0, 0, 1)
	if eje == 0:
		v = Vector3(1, 0, 0)
	elif eje == 1:
		v = Vector3(0, 1, 0)
	var b := Basis(v, deg2rad(grados))
	if esc != 1.0:
		b = b.scaled(Vector3.ONE * esc)
	_esq.set_bone_pose(i, Transform(b, Vector3.ZERO))


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
