tool
extends Spatial
# Riendas.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Va en un nodo "Riendas" (Spatial) que es hijo directo del jinete.
# Tiende una rienda desde cada argolla del bocado hasta las manos del jinete,
# rodeando el cuello y la cabeza del caballo por fuera. Sigue el galope, la cabeza y los brazos.
# Reconoce solo si el caballo es el árabe o el americano. Para el Cuarto de Milla hay que
# escribir "cuartomilla" en "Caballo", y para el Inglés "ingles". Todo se ajusta en el Inspector.

export var ancho_rienda := 1.8            # centímetros
export var grosor_rienda := 0.5           # centímetros
export var color_rienda := Color("704a2b") setget _poner_color
export var separar_del_cuello := 1.5      # centímetros de aire entre la rienda y el cuello
export var grosor_cuello := 1.0           # 1 = medida del caballo; más de 1 = riendas más abiertas
export var agarre_mano := Vector3(0.006, 0.0476, -0.0149)   # centro del puño izquierdo; el derecho va en espejo
export var segmentos := 10                # más = rienda más curva y suave
export var vueltas_ajuste := 3            # PESO: veces que acomoda la rienda alrededor del cuello (antes 8). Más = más exacta, más pesada
export var distancia_detalle := 80.0      # PESO: más lejos que esto de la cámara, la rienda se acomoda cada pocos cuadros
export var cuadros_lejos := 3             # PESO: cada cuántos cuadros se acomoda la rienda de los caballos lejanos
export var riendas_en_una_mano := true    # las dos riendas en la mano izquierda; la derecha queda libre para el látigo
export var soltar_para_latigo := true     # si no van en una mano: al echar látigo, la rienda derecha pasa a la izquierda
export var tiempo_regreso := 0.3          # segundos que tarda la mano derecha en volver a tomar su rienda
export var caballo := ""                  # vacío = reconoce solo al árabe o al americano; "cuartomilla" = Cuarto de Milla; "ingles" = Inglés
export var estado := ""                   # aquí el script dice si armó las riendas o qué le falta

# Medidas de cada caballo, en su propio tamaño.
# "elipses": una por hueso del cuello y una por cada punto de la cabeza:
# [corrimiento hacia la garganta, medio ancho, medio alto]
var _caballos := {
	"arabe": {
		"cabeza": "tripo::Head_5",
		"argolla": Vector3(-0.281, 0.176, 0.080),
		"cuello": ["tripo::Spine_8", "tripo::Spine_9", "tripo::Head_0", "tripo::Head_1",
				"tripo::Head_2", "tripo::Head_3", "tripo::Head_4", "tripo::Head_5"],
		"puntos_cabeza": [Vector3(-0.0983, 0.0616, 0.0), Vector3(-0.1826, 0.1144, 0.0)],
		"elipses": [[-0.0894, 0.2041, 0.1708], [-0.0763, 0.1604, 0.1890], [-0.0798, 0.1486, 0.2128],
				[-0.0020, 0.1405, 0.2884], [0.0482, 0.1226, 0.2431], [0.0872, 0.1126, 0.2051],
				[0.0629, 0.1148, 0.1747], [0.0937, 0.1161, 0.2095], [0.0751, 0.1161, 0.1987],
				[0.0950, 0.1009, 0.1965]]
	},
	# Cuarto de Milla: se escoge a mano (su hueso de la cabeza se llama igual que uno del americano).
	# Sus dos argollas van aparte porque el hueso de su cabeza no está de costado.
	"cuartomilla": {
		"manual": true,
		"cabeza": "bone_9",
		"argolla": Vector3(0.0178, 0.0339, -0.1638),
		"argolla_der": Vector3(0.0924, 0.0386, -0.1377),
		"cuello": ["tripo::Head_0", "bone_6", "bone_7", "bone_8", "bone_9"],
		"puntos_cabeza": [Vector3(0.0189, 0.0611, -0.0515), Vector3(0.0356, 0.0496, -0.0973)],
		"elipses": [[0.0069, 0.0968, 0.1118], [-0.0375, 0.0976, 0.1200], [-0.0188, 0.0696, 0.1047],
				[0.0125, 0.0686, 0.1094], [0.0391, 0.0631, 0.1096], [0.0626, 0.0603, 0.0877],
				[0.0628, 0.0568, 0.0922]]
	},
	# Inglés: también se escoge a mano. Su cuello tiene pocos huesos, por eso lleva
	# más puntos dentro de la cabeza (cuello alto y cara).
	"ingles": {
		"manual": true,
		"cabeza": "tripo::Head_1",
		"argolla": Vector3(0.0819, 0.2126, 0.0135),
		"argolla_der": Vector3(0.0880, 0.1906, -0.0674),
		"cuello": ["tripo::Spine_6", "tripo::Head_0", "tripo::Head_1"],
		"puntos_cabeza": [Vector3(0.1264, -0.0518, 0.0083), Vector3(0.1387, 0.0489, 0.0013),
				Vector3(0.1698, 0.1282, -0.0006), Vector3(0.1306, 0.1621, -0.0127)],
		"elipses": [[-0.0164, 0.1123, 0.0715], [-0.0291, 0.1551, 0.1279], [0.0027, 0.1668, 0.1446],
				[0.0427, 0.0800, 0.1008], [-0.0109, 0.0549, 0.0891], [0.0653, 0.0823, 0.0920],
				[0.0565, 0.0582, 0.0876]]
	},
	"americano": {
		"cabeza": "bone_16",
		"argolla": Vector3(-0.064, -0.140, 0.0365),
		"cuello": ["bone_9", "bone_10", "bone_11", "bone_12", "bone_13", "bone_14", "bone_15", "bone_16"],
		"puntos_cabeza": [Vector3(-0.0224, -0.0490, 0.0), Vector3(-0.0416, -0.0910, 0.0)],
		"elipses": [[-0.0350, 0.0567, 0.0771], [-0.0357, 0.0535, 0.0842], [-0.0029, 0.0499, 0.1167],
				[0.0045, 0.0518, 0.1125], [0.0194, 0.0509, 0.0879], [0.0453, 0.0489, 0.0741],
				[0.0431, 0.0497, 0.0666], [0.0410, 0.0584, 0.0748], [0.0332, 0.0608, 0.0831],
				[0.0349, 0.0533, 0.0790]]
	}
}

var _datos = null
var _esq_caballo : Skeleton
var _esq_jinete : Skeleton
var _i_lomo := -1
var _i_cabeza := -1
var _i_cuello := []
var _i_manos := []
var _tramos := []          # [rienda izquierda, rienda derecha], cada una con el numero de sus pedazos
# PESO: antes cada pedazo de rienda era un objeto aparte (20 por caballo,
# 240 dibujos en toda la carrera). Ahora todos los pedazos de este
# caballo van en UN solo dibujo que se mueve igual.
var _mm : MultiMesh
var _mmi : MultiMeshInstance
var _mat : SpatialMaterial
var _malla : CubeMesh
var _listo := false
var _ultimo_aviso := ""
var _mezcla := 0.0         # 0 = cada mano con su rienda, 1 = las dos en la izquierda
var _contador := -1


func _init():
	set_process(true)


func _ready():
	_armar()


func _poner_color(v):
	color_rienda = v
	if _mat:
		_mat.albedo_color = v


func _armar():
	if _mmi and is_instance_valid(_mmi):
		_mmi.queue_free()
	_mmi = null
	_mm = null
	_tramos.clear()
	_listo = false
	var jinete = get_parent()
	if jinete == null:
		return
	var marco = jinete.get_parent()
	if marco == null or not marco is BoneAttachment:
		_avisar("el nodo Riendas debe ir dentro del jinete, y el jinete dentro del BoneAttachment del caballo")
		return
	_esq_caballo = marco.get_parent() as Skeleton
	if _esq_caballo == null:
		_avisar("no encuentro el esqueleto del caballo")
		return
	_datos = null
	if caballo != "":
		if _caballos.has(caballo):
			_datos = _caballos[caballo]
		else:
			_avisar("no conozco el caballo \"" + caballo + "\"")
			return
	else:
		for k in _caballos:
			if _caballos[k].get("manual", false):
				continue
			if _buscar(_esq_caballo, _caballos[k]["cabeza"]) >= 0:
				_datos = _caballos[k]
	if _datos == null:
		_avisar("no reconozco al caballo")
		return
	_esq_jinete = _buscar_esqueleto(jinete)
	if _esq_jinete == null:
		_avisar("no encuentro el esqueleto del jinete")
		return
	_i_lomo = _buscar(_esq_caballo, marco.bone_name)
	_i_cabeza = _buscar(_esq_caballo, _datos["cabeza"])
	_i_cuello.clear()
	for n in _datos["cuello"]:
		_i_cuello.append(_buscar(_esq_caballo, n))
	_i_manos = [_hueso(_esq_jinete, "LeftHand"), _hueso(_esq_jinete, "RightHand")]
	if _i_lomo < 0 or _i_cabeza < 0 or _i_manos[0] < 0 or _i_manos[1] < 0 or _i_cuello.has(-1):
		_avisar("faltan huesos: lomo %d, cabeza %d, manos %s, cuello %s" % [_i_lomo, _i_cabeza, str(_i_manos), str(_i_cuello)])
		return
	_mat = SpatialMaterial.new()
	_mat.albedo_color = color_rienda
	_mat.roughness = 0.8
	_malla = CubeMesh.new()
	_malla.size = Vector3.ONE
	var n : int = int(max(segmentos, 2))
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.mesh = _malla
	_mm.instance_count = n * 2
	_mmi = MultiMeshInstance.new()
	_mmi.multimesh = _mm
	_mmi.material_override = _mat
	add_child(_mmi)
	for lado in 2:
		var r := []
		for i in n:
			r.append(lado * n + i)
		_tramos.append(r)
	_listo = true
	_avisar("listas")


func _process(delta):
	if not _listo or _tramos.empty() or _tramos[0].size() != int(max(segmentos, 2)):
		_armar()
		if not _listo:
			return
	var jinete = get_parent()
	if jinete == null or not is_instance_valid(_esq_caballo) or not is_instance_valid(_esq_jinete) or _mm == null:
		_listo = false
		return
	# PESO: los caballos lejos de la cámara (o que no se ven) no se
	# recalculan en cada cuadro; de lejos no se nota la diferencia.
	if not Engine.editor_hint:
		if not is_visible_in_tree():
			return
		if _contador < 0:
			_contador = get_instance_id() % int(max(cuadros_lejos, 1))
		_contador += 1
		var camara = get_viewport().get_camera()
		if camara and cuadros_lejos > 1:
			if camara.global_transform.origin.distance_to(global_transform.origin) > distancia_detalle:
				if _contador % int(cuadros_lejos) != 0:
					return
	# Todo se calcula dentro del jinete para que no se atrase en el galope
	var a_este : Transform = transform.affine_inverse()
	var lomo : Transform = _esq_caballo.get_bone_global_pose(_i_lomo)
	var caballo_a_jinete : Transform = jinete.transform.affine_inverse() * lomo.affine_inverse()
	var t_esq : Transform = jinete.global_transform.affine_inverse() * _esq_jinete.global_transform
	var escala_caballo : float = caballo_a_jinete.basis.get_scale().x
	var escala_mundo : float = max(jinete.global_transform.basis.get_scale().x, 0.0001)
	var aire : float = separar_del_cuello / 100.0 / escala_mundo
	var costado : Vector3 = jinete.transform.basis.inverse().xform(Vector3(0, 0, 1)).normalized()
	var cabeza : Transform = _esq_caballo.get_bone_global_pose(_i_cabeza)
	# Mientras el jinete echa látigo, la rienda derecha pasa a la mano izquierda
	var latigo := false
	if soltar_para_latigo:
		var v = jinete.get("_latigo_activo")
		latigo = typeof(v) == TYPE_BOOL and v
	if riendas_en_una_mano or latigo:
		_mezcla = 1.0
	else:
		_mezcla = move_toward(_mezcla, 0.0, delta / max(tiempo_regreso, 0.01))
	# Cuello y cabeza como una cadena de óvalos
	var puntos := []
	for k in _i_cuello.size():
		puntos.append(caballo_a_jinete.xform(_esq_caballo.get_bone_global_pose(_i_cuello[k]).origin))
	for q in _datos["puntos_cabeza"]:
		puntos.append(caballo_a_jinete.xform(cabeza.xform(q)))
	var ovalos := []
	for e in _datos["elipses"]:
		ovalos.append([e[0] * escala_caballo,
				e[1] * grosor_cuello * escala_caballo + aire,
				e[2] * grosor_cuello * escala_caballo + aire])
	var ancho : float = ancho_rienda / 100.0 / escala_mundo
	var grueso : float = grosor_rienda / 100.0 / escala_mundo
	for lado in 2:
		var signo := 1.0 if lado == 0 else -1.0
		var argolla : Vector3 = _datos["argolla"]
		if lado == 1 and _datos.has("argolla_der"):
			argolla = _datos["argolla_der"]
		else:
			argolla.z *= signo
		var agarre := Vector3(agarre_mano.x * signo, agarre_mano.y, agarre_mano.z * signo)
		var mano : Vector3 = t_esq.xform(_esq_jinete.get_bone_global_pose(_i_manos[lado]).xform(agarre))
		if lado == 1 and _mezcla > 0.0:
			var izq : Vector3 = t_esq.xform(_esq_jinete.get_bone_global_pose(_i_manos[0]).xform(agarre_mano))
			mano = mano.linear_interpolate(izq - costado * (1.5 / 100.0 / escala_mundo), _mezcla)
		var boca : Vector3 = caballo_a_jinete.xform(cabeza.xform(argolla))
		var cuerda := _tender(mano, boca, puntos, ovalos, costado, signo)
		var r : Array = _tramos[lado]
		for i in r.size():
			var a : Vector3 = cuerda[i]
			var b : Vector3 = cuerda[i + 1]
			var y : Vector3 = b - a
			var largo : float = y.length()
			if largo < 0.00001:
				_mm.set_instance_transform(r[i], Transform(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
				continue
			y = y / largo
			# lo delgado mira hacia el costado; lo ancho se ve de lado
			var z : Vector3 = costado - y * y.dot(costado)
			if z.length() < 0.001:
				z = y.cross(Vector3(0, 1, 0))
			z = z.normalized()
			var x : Vector3 = y.cross(z)
			var b3 := Basis(x * ancho, y * largo, z * grueso)
			_mm.set_instance_transform(r[i], a_este * Transform(b3, (a + b) * 0.5))


# Tiende la rienda en pedazos; cada rienda va por su costado del cuello y de la cabeza
func _tender(desde : Vector3, hasta : Vector3, puntos : Array, ovalos : Array, costado : Vector3, lado : float) -> Array:
	var n : int = int(max(segmentos, 2))
	var c := []
	for i in n + 1:
		c.append(desde.linear_interpolate(hasta, float(i) / n))
	for vuelta in int(max(vueltas_ajuste, 1)):
		_empujar(c, puntos, ovalos, costado, lado)
		var s := c.duplicate()
		for i in range(1, n):
			s[i] = c[i] * 0.5 + (c[i - 1] + c[i + 1]) * 0.25
		c = s
	_empujar(c, puntos, ovalos, costado, lado)
	return c


func _empujar(c : Array, puntos : Array, ovalos : Array, costado : Vector3, lado : float):
	for i in range(1, c.size() - 1):
		var p : Vector3 = c[i]
		for k in puntos.size() - 1:
			var a : Vector3 = puntos[k]
			var ab : Vector3 = puntos[k + 1] - a
			var largo : float = ab.length()
			if largo < 0.00001:
				continue
			var d : Vector3 = ab / largo
			var g : Vector3 = costado.cross(d)
			if g.length() < 0.00001:
				continue
			g = g.normalized()
			var l2 : Vector3 = d.cross(g)
			var t : float = clamp((p - a).dot(d) / largo, 0.0, 1.0)
			var e0 : Array = ovalos[k]
			var e1 : Array = ovalos[k + 1]
			var corrido : float = lerp(e0[0], e1[0], t)
			var medio_ancho : float = lerp(e0[1], e1[1], t)
			var medio_alto : float = lerp(e0[2], e1[2], t)
			var centro : Vector3 = a + d * (t * largo) + g * corrido
			var x : float = (p - centro).dot(l2)
			var y : float = (p - centro).dot(g)
			if abs(y) < medio_alto:
				# la saca hacia su propio costado, a la misma altura
				var afuera : float = medio_ancho * sqrt(1.0 - (y / medio_alto) * (y / medio_alto))
				if lado * x < afuera:
					p = p + l2 * (lado * afuera - x)
		c[i] = p


# ---------- utilidades ----------
func _avisar(texto : String):
	if texto != _ultimo_aviso:
		_ultimo_aviso = texto
		estado = texto
		property_list_changed_notify()
		print("RIENDAS (", get_parent().name if get_parent() else "?", "): ", texto)


# Godot cambia los ":" de los nombres de huesos por "_" al importar; así los encuentra igual
func _buscar(esq : Skeleton, nombre : String) -> int:
	var i := esq.find_bone(nombre)
	if i >= 0:
		return i
	var limpio := nombre.replace(":", "_").replace("/", "_")
	for k in esq.get_bone_count():
		if esq.get_bone_name(k).replace(":", "_").replace("/", "_") == limpio:
			return k
	# último intento: por el final del nombre (Head_5, Spine_8...)
	var partes := nombre.split(":")
	var corto : String = partes[partes.size() - 1]
	for k in esq.get_bone_count():
		if esq.get_bone_name(k).ends_with(corto):
			return k
	return -1


func _hueso(esq : Skeleton, fin : String) -> int:
	for i in esq.get_bone_count():
		var n : String = esq.get_bone_name(i)
		if n == fin or n.ends_with(":" + fin) or n.ends_with("_" + fin):
			return i
	return -1


func _buscar_esqueleto(n):
	if n == self:
		return null
	if n is Skeleton:
		return n
	for c in n.get_children():
		var r = _buscar_esqueleto(c)
		if r:
			return r
	return null
