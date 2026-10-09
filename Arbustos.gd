tool
extends Spatial

# Arbustos.gd — Planta arbustos bajos a los dos lados de las barandas, siguiendo la pista.
# Toma la forma de la pista de TrackPath y la distancia de las barandas del nodo Barandas,
# asi que si mueves las barandas, los arbustos las siguen solos.
# No pone arbustos encima de las tribunas, caballerizas ni paddock (ver "Respetar Cajas").
# Van todos en un solo dibujo (MultiMesh): se ven cientos y pesan casi nada en el telefono.

export var trackpath_path = NodePath("../TrackPath")
export var barandas_path = NodePath("../Barandas")

# --- Donde van ---
export var poner_lado_interior = true
export var poner_lado_exterior = true
export var distancia_a_baranda = 3.0
export var separacion = 8.0
export var filas = 1
export var separacion_filas = 3.5
export var altura_base = 0.0
export var respetar_cajas = "Tribuna,Caballerizas,Paddock_de_Paseo"
export var margen_cajas = 1.0

# --- Tamano ---
export var alto_arbusto = 1.9
export var ancho_arbusto = 2.2
export var variacion_tamano = 0.3
export var semilla = 11

# --- Colores ---
export var color_a = Color("1f4d1c")
export var color_b = Color("2c5e24")
export var color_c = Color("3a6e2c")
export var sin_sombreado = false

var _firma = ""
var _reloj = 0.0


func _ready():
	set_process(Engine.editor_hint)
	call_deferred("_reconstruir")


func _process(delta):
	_reloj += delta
	if _reloj < 0.5:
		return
	_reloj = 0.0
	if _calcular_firma() != _firma:
		_reconstruir()


func _calcular_firma():
	var s = ""
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_EDITOR:
			s += str(get(p.name))
	var b = get_node_or_null(barandas_path)
	if b:
		s += str(b.get("offset_interior")) + str(b.get("offset_exterior"))
	var tp = get_node_or_null(trackpath_path)
	if tp and tp.curve:
		s += str(tp.global_transform) + str(tp.curve.get_baked_length())
	for c in _cajas_a_respetar():
		s += str(c.global_transform) + str(c.width) + str(c.depth)
	return s


func _cajas_a_respetar():
	var lista = []
	var padre = get_parent()
	if padre == null:
		return lista
	var prefijos = respetar_cajas.split(",", false)
	for n in padre.get_children():
		if n is CSGBox:
			for pre in prefijos:
				if n.name.begins_with(pre.strip_edges()):
					lista.append(n)
					break
	return lista


func _reconstruir():
	if not is_inside_tree():
		return
	_firma = _calcular_firma()
	for h in get_children():
		if h.name.begins_with("_Vestido"):
			remove_child(h)
			h.queue_free()
	var tp = get_node_or_null(trackpath_path)
	if tp == null or tp.curve == null:
		return
	var curve = tp.curva_grama if tp.get("curva_grama") else tp.curve
	var largo = curve.get_baked_length()
	if largo <= 0.0 or separacion < 0.5:
		return

	# Distancia de las barandas: del nodo Barandas si existe
	var off_int = 2.0
	var off_ext = 118.0
	var b = get_node_or_null(barandas_path)
	if b:
		if b.get("offset_interior") != null:
			off_int = b.offset_interior
		if b.get("offset_exterior") != null:
			off_ext = b.offset_exterior

	# Centro del ovalo, para saber cual lado es "afuera" (igual que las barandas)
	var centro = Vector3.ZERO
	for i in range(200):
		centro += tp.to_global(curve.interpolate_baked(largo * i / 200.0))
	centro /= 200.0

	var cajas = _cajas_a_respetar()
	var rng = RandomNumberGenerator.new()
	rng.seed = semilla
	var colores = [color_a, color_b, color_c]
	var lados = []
	if poner_lado_interior:
		lados.append(-1.0)
	if poner_lado_exterior:
		lados.append(1.0)

	var transformes = []
	var tintes = []
	var n_puestos = int(largo / separacion)
	for lado in lados:
		for fila in range(int(max(1, filas))):
			var corrido = (separacion * 0.5) if fila % 2 == 1 else 0.0
			for i in range(n_puestos):
				var d = fposmod(i * separacion + corrido, largo)
				var p = tp.to_global(curve.interpolate_baked(d))
				var p2 = tp.to_global(curve.interpolate_baked(fposmod(d + 1.0, largo)))
				var tang = (p2 - p)
				tang.y = 0.0
				if tang.length() < 0.001:
					continue
				tang = tang.normalized()
				var lateral = Vector3(tang.z, 0, -tang.x)
				var afuera = p - centro
				afuera.y = 0.0
				if lateral.dot(afuera) < 0:
					lateral = -lateral
				var dist_lat
				if lado > 0:
					dist_lat = off_ext + distancia_a_baranda + fila * separacion_filas
				else:
					dist_lat = off_int - distancia_a_baranda - fila * separacion_filas
				var pos = p + lateral * dist_lat
				pos.y = p.y + altura_base
				var esc = 1.0 + rng.randf_range(-variacion_tamano, variacion_tamano)
				var ancho = ancho_arbusto * esc
				if _choca_con_caja(pos, ancho * 0.5, cajas):
					continue
				var giro = Basis(Vector3.UP, rng.randf() * TAU)
				var alto = alto_arbusto * esc * rng.randf_range(0.85, 1.15)
				var base = giro.scaled(Vector3(ancho, alto, ancho * rng.randf_range(0.8, 1.0)))
				transformes.append(Transform(base, to_local(pos)))
				var col = colores[rng.randi() % colores.size()]
				col = col.lightened(rng.randf_range(0.0, 0.08))
				tintes.append(col)

	if transformes.size() == 0:
		return
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.color_format = MultiMesh.COLOR_8BIT
	mm.mesh = _malla_arbusto()
	mm.instance_count = transformes.size()
	for i in range(transformes.size()):
		mm.set_instance_transform(i, transformes[i])
		mm.set_instance_color(i, tintes[i])
	var mmi = MultiMeshInstance.new()
	mmi.name = "_Vestido_Arbustos"
	mmi.multimesh = mm
	var mat = SpatialMaterial.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	mat.albedo_color = Color(1, 1, 1)
	mat.flags_unshaded = sin_sombreado
	mmi.material_override = mat
	add_child(mmi)


func _choca_con_caja(pos, radio, cajas):
	for c in cajas:
		var l = c.global_transform.affine_inverse().xform(pos)
		if abs(l.x) < c.width * 0.5 + radio + margen_cajas and abs(l.z) < c.depth * 0.5 + radio + margen_cajas:
			return true
	return false


# Un arbusto de 1 x 1 x 1: una mata central y dos mas chicas pegadas, para que no sea una bola perfecta
func _malla_arbusto():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_elipsoide_parcial(st, Vector3(0, 0.5, 0), Vector3(0.46, 0.52, 0.46), Basis(), 7, 4, PI * 0.8)
	_elipsoide_parcial(st, Vector3(0.26, 0.34, 0.12), Vector3(0.3, 0.34, 0.3), Basis(), 6, 3, PI * 0.8)
	_elipsoide_parcial(st, Vector3(-0.22, 0.32, -0.18), Vector3(0.28, 0.32, 0.28), Basis(), 6, 3, PI * 0.8)
	return st.commit()


func _tri(st, a, b, c, na, nb, nc):
	if (b - a).cross(c - a).dot(na + nb + nc) > 0:
		var t = b
		b = c
		c = t
		var tn = nb
		nb = nc
		nc = tn
	st.add_normal(na)
	st.add_vertex(a)
	st.add_normal(nb)
	st.add_vertex(b)
	st.add_normal(nc)
	st.add_vertex(c)


func _elipsoide_parcial(st, centro, r, b, segs, anillos, lat_max):
	for j in range(anillos):
		var t0 = lat_max * j / anillos
		var t1 = lat_max * (j + 1) / anillos
		for i in range(segs):
			var a0 = TAU * i / segs
			var a1 = TAU * (i + 1) / segs
			var u00 = Vector3(sin(t0) * cos(a0), cos(t0), sin(t0) * sin(a0))
			var u01 = Vector3(sin(t0) * cos(a1), cos(t0), sin(t0) * sin(a1))
			var u10 = Vector3(sin(t1) * cos(a0), cos(t1), sin(t1) * sin(a0))
			var u11 = Vector3(sin(t1) * cos(a1), cos(t1), sin(t1) * sin(a1))
			var p00 = centro + b.xform(u00 * r)
			var p01 = centro + b.xform(u01 * r)
			var p10 = centro + b.xform(u10 * r)
			var p11 = centro + b.xform(u11 * r)
			var n00 = b.xform(u00 / r).normalized()
			var n01 = b.xform(u01 / r).normalized()
			var n10 = b.xform(u10 / r).normalized()
			var n11 = b.xform(u11 / r).normalized()
			if j > 0:
				_tri(st, p00, p01, p11, n00, n01, n11)
			_tri(st, p00, p11, p10, n00, n11, n10)
