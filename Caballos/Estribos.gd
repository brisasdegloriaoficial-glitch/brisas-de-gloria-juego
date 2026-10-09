tool
extends Spatial
# Estribos.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Va en un nodo "Estribos" (Spatial) que es hijo directo del jinete.
# Pone un estribo bajo cada pie y estira su correa hasta la silla.
# Los estribos siguen a los pies en el galope. Todo se ajusta en el Inspector.
#
# ENGANCHE SILLA: punto de la silla donde se engancha la correa izquierda,
# medido en el hueso del caballo donde va montado el jinete.
# La correa derecha usa el mismo punto en espejo.

export(PackedScene) var modelo_estribo setget _poner_modelo
export var tamano_estribo := 1.0                        # 1 = 13,7 cm de ancho
export var enganche_silla := Vector3(0.11, 0.24, 0.27)  # valores del árabe
export var planta_pie := Vector3(0, 0, -0.0137)         # Y: + hacia la punta, - hacia el talón; Z: - baja, + sube
export var ancho_correa := 2.5                          # centímetros
export var grosor_correa := 0.5                         # centímetros
export var color_metal := Color("96969b") setget _poner_color_metal
export var color_correa := Color("3a2618") setget _poner_color_correa

# Medidas del modelo Estribo_02.glb (en metros)
const Y_PISADERA := -0.4434
const Y_CORREA_ABAJO := -0.33
const LARGO_CORREA_MODELO := 0.33
const ANCHO_CORREA_MODELO := 2.5
const GROSOR_CORREA_MODELO := 0.5

var _esq : Skeleton
var _pies := []
var _estribos := []
var _correas := []
var _mat_metal : SpatialMaterial
var _mat_correa : SpatialMaterial
var _listo := false


func _init():
	set_process(true)


func _ready():
	_armar()


func _poner_modelo(v):
	modelo_estribo = v
	_listo = false


func _poner_color_metal(v):
	color_metal = v
	if _mat_metal:
		_mat_metal.albedo_color = v


func _poner_color_correa(v):
	color_correa = v
	if _mat_correa:
		_mat_correa.albedo_color = v


func _armar():
	for e in _estribos:
		if is_instance_valid(e):
			e.queue_free()
	_estribos.clear()
	_correas.clear()
	_listo = false
	var jinete = get_parent()
	if jinete == null or modelo_estribo == null:
		return
	_esq = _buscar_esqueleto(jinete)
	if _esq == null:
		return
	_pies = [_hueso("LeftToeBase"), _hueso("RightToeBase")]
	if _pies[0] < 0 or _pies[1] < 0:
		return
	_mat_metal = SpatialMaterial.new()
	_mat_metal.albedo_color = color_metal
	_mat_metal.metallic = 0.8
	_mat_metal.roughness = 0.35
	_mat_correa = SpatialMaterial.new()
	_mat_correa.albedo_color = color_correa
	_mat_correa.roughness = 0.8
	for lado in 2:
		var e = modelo_estribo.instance()
		add_child(e)
		var correa = null
		for m in _buscar_todos(e, "MeshInstance"):
			if m.name.find("Correa") >= 0:
				m.material_override = _mat_correa
				correa = m
			else:
				m.material_override = _mat_metal
		_estribos.append(e)
		_correas.append(correa)
	_listo = true


func _process(_delta):
	if not _listo:
		_armar()
		if not _listo:
			return
	var jinete = get_parent()
	if jinete == null or not is_instance_valid(_esq):
		_listo = false
		return
	# Todo se calcula dentro del jinete para que no se atrase en el galope
	var a_este : Transform = transform.affine_inverse()
	var t_esq : Transform = jinete.global_transform.affine_inverse() * _esq.global_transform
	var t_marco : Transform = jinete.transform.affine_inverse()
	var costado : Vector3 = t_marco.basis.xform(Vector3(0, 0, 1)).normalized()
	var escala : float = jinete.global_transform.basis.get_scale().x
	var s : float = tamano_estribo / max(escala, 0.0001)
	var t_min : float = max(tamano_estribo, 0.01)
	for lado in 2:
		var e = _estribos[lado]
		if not is_instance_valid(e):
			_listo = false
			return
		var punto : Vector3 = enganche_silla
		if lado == 1:
			punto.z = -punto.z
		var pie : Vector3 = t_esq.xform(_esq.get_bone_global_pose(_pies[lado]).xform(planta_pie))
		var barra : Vector3 = t_marco.xform(punto)
		var sube : Vector3 = barra - pie
		var d : float = sube.length()
		if d < 0.0001:
			continue
		sube = sube / d
		var x : Vector3 = (costado - sube * sube.dot(costado)).normalized()
		var z : Vector3 = x.cross(sube)
		var b : Basis = Basis(x, sube, z).scaled(Vector3(s, s, s))
		var t := Transform(b, pie - b.xform(Vector3(0, Y_PISADERA, 0)))
		e.transform = a_este * t
		var c = _correas[lado]
		if c:
			var y_barra : float = Y_PISADERA + d / s
			var largo : float = max(y_barra - Y_CORREA_ABAJO, 0.001)
			var sx : float = (ancho_correa / ANCHO_CORREA_MODELO) / t_min
			var sz : float = (grosor_correa / GROSOR_CORREA_MODELO) / t_min
			var bc : Basis = Basis().scaled(Vector3(sx, largo / LARGO_CORREA_MODELO, sz))
			c.transform = Transform(bc, Vector3(0, y_barra, 0))


# ---------- utilidades ----------
func _hueso(fin : String) -> int:
	for i in _esq.get_bone_count():
		var n : String = _esq.get_bone_name(i)
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


func _buscar_todos(n, clase : String) -> Array:
	var r := []
	if n.is_class(clase):
		r.append(n)
	for c in n.get_children():
		r += _buscar_todos(c, clase)
	return r
