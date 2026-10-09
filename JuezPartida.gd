tool
extends Spatial

# JuezPartida.gd — Podio del juez de partida, al lado de la gatera.
# Va como hijo de Aparato_Partida, asi que se mueve solo con la gatera
# cuando cambia la distancia de la carrera. Se para del lado del jardin,
# un poco adelante de la gatera, y mira hacia los caballos.

# Tamano del juez (1 = persona real en metros). Con 3.4 queda un poco
# mas alto que los jockeys del juego. El podio NO crece con el juez.
export var escala_juez = 3.4
export var distancia_a_la_baranda = 7.0
export var adelante_de_la_gatera = 10.0
export var altura_plataforma = 3.0
export var ancho_plataforma = 5.0
export var alto_baranda = 2.4
export var poner_juez = true
export var poner_techito = false

export var color_estructura = Color("fbf8f0")
export var color_detalle = Color("7b1e2b")
export var color_techito = Color("222988")
export var color_saco = Color("7b1e2b")
export var color_pantalon = Color("1f1f1f")
export var color_piel = Color("e0ac69")
export var sin_sombreado = true

var _firma = ""
var _ultimo_offset = -1.0


func _ready():
	call_deferred("_reconstruir")


func _process(_delta):
	var linea = get_parent()
	if linea == null or not ("offset" in linea):
		return
	if abs(linea.offset - _ultimo_offset) > 0.01:
		_ubicar()
	if Engine.editor_hint and _calcular_firma() != _firma:
		_reconstruir()


func _calcular_firma():
	var s = ""
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_EDITOR:
			s += str(get(p.name))
	return s


# Pone el podio en la pista: adelante de la gatera y del lado del jardin.
func _ubicar():
	var linea = get_parent()
	if linea == null or not ("offset" in linea):
		return
	var camino = linea.get_parent()
	if camino == null or not ("curve" in camino) or camino.curve == null:
		return
	var curva = camino.curve
	var largo = curva.get_baked_length()
	if largo <= 0.0:
		return
	_ultimo_offset = linea.offset
	var centro = Vector3.ZERO
	for i in range(100):
		centro += camino.to_global(curva.interpolate_baked(largo * i / 100.0))
	centro /= 100.0
	var d = fposmod(linea.offset + adelante_de_la_gatera, largo)
	var p = camino.to_global(curva.interpolate_baked(d))
	var p2 = camino.to_global(curva.interpolate_baked(fposmod(d + 1.0, largo)))
	var avance = p2 - p
	avance.y = 0
	avance = avance.normalized()
	var hacia_jardin = centro - p
	hacia_jardin.y = 0
	var lateral = Vector3(avance.z, 0, -avance.x)
	if lateral.dot(hacia_jardin) < 0:
		lateral = -lateral
	var pos = p + lateral * distancia_a_la_baranda
	# Mira hacia la gatera (hacia atras en la pista y hacia afuera)
	var mira = -avance * 0.6 - lateral * 0.8
	var z = -mira.normalized()
	var x = Vector3.UP.cross(z).normalized()
	global_transform = Transform(Basis(x, Vector3.UP, z), pos)


func _reconstruir():
	if not is_inside_tree():
		return
	_firma = _calcular_firma()
	for h in get_children():
		if h.name.begins_with("_Vestido"):
			remove_child(h)
			h.queue_free()
	_ubicar()
	var s = {}
	var a = ancho_plataforma * 0.5
	var hp = altura_plataforma
	# Cuatro patas, plataforma y faldon de color
	for px in [-a + 0.15, a - 0.15]:
		for pz in [-a + 0.15, a - 0.15]:
			_caja(_st(s, "estructura"), Vector3(px - 0.12, 0, pz - 0.12), Vector3(px + 0.12, hp, pz + 0.12))
	_caja(_st(s, "estructura"), Vector3(-a, hp, -a), Vector3(a, hp + 0.2, a))
	_caja(_st(s, "detalle"), Vector3(-a - 0.02, hp - 0.35, -a - 0.02), Vector3(a + 0.02, hp, a + 0.02))
	# Baranda en tres lados (el de atras queda abierto para la escalera)
	var yb = hp + 0.2
	for lado in [[-a, -a, a, -a], [-a, -a, -a, a], [a, -a, a, a]]:
		var p0 = Vector3(lado[0], yb, lado[1])
		var p1 = Vector3(lado[2], yb, lado[3])
		_caja(_st(s, "estructura"), _min(p0, p1) - Vector3(0.05, 0, 0.05), _max(p0, p1) + Vector3(0.05, 0.08, 0.05))
		_caja(_st(s, "detalle"), _min(p0, p1) - Vector3(0.06, -alto_baranda + 0.1, 0.06), _max(p0, p1) + Vector3(0.06, alto_baranda, 0.06))
		for k in range(4):
			var q = p0.linear_interpolate(p1, k / 3.0)
			_caja(_st(s, "estructura"), q + Vector3(-0.05, 0, -0.05), q + Vector3(0.05, alto_baranda, 0.05))
	# Escalera por detras (lado +Z)
	var largo_esc = hp + 0.2
	var pie = Vector3(0, 0, a + hp * 0.45)
	var tope = Vector3(0, hp + 0.2, a)
	for sx in [-0.5, 0.5]:
		_tabla(_st(s, "estructura"), pie + Vector3(sx, 0, 0), tope + Vector3(sx, 0, 0), 0.12, 0.12)
	var peldanos = int(max(3, round(largo_esc / 0.45)))
	for k in range(1, peldanos):
		var q = pie.linear_interpolate(tope, float(k) / peldanos)
		_caja(_st(s, "detalle"), q + Vector3(-0.5, -0.04, -0.06), q + Vector3(0.5, 0.04, 0.06))
	# Techito tipo sombrilla
	if poner_techito:
		var ht = yb + 2.6
		_caja(_st(s, "estructura"), Vector3(-a + 0.05, yb, a - 0.15), Vector3(-a + 0.2, ht, a - 0.05))
		_caja(_st(s, "estructura"), Vector3(a - 0.2, yb, a - 0.15), Vector3(a - 0.05, ht, a - 0.05))
		_caja(_st(s, "techito"), Vector3(-a - 0.3, ht, -a - 0.3), Vector3(a + 0.3, ht + 0.15, a + 0.3))
		_caja(_st(s, "detalle"), Vector3(-a - 0.32, ht - 0.25, -a - 0.32), Vector3(a + 0.32, ht, a + 0.32))
	# El juez, de pie, con los brazos abajo (el timbre de largada no se ve)
	if poner_juez:
		var e = escala_juez
		var b = Vector3(0, yb, -0.4)
		_caja(_st(s, "pantalon"), b + Vector3(-0.28, 0, -0.14) * e, b + Vector3(-0.04, 0.85, 0.14) * e)
		_caja(_st(s, "pantalon"), b + Vector3(0.04, 0, -0.14) * e, b + Vector3(0.28, 0.85, 0.14) * e)
		_caja(_st(s, "saco"), b + Vector3(-0.32, 0.85, -0.18) * e, b + Vector3(0.32, 1.55, 0.18) * e)
		_caja(_st(s, "piel"), b + Vector3(-0.07, 1.55, -0.07) * e, b + Vector3(0.07, 1.62, 0.07) * e)
		_esfera(_st(s, "piel"), b + Vector3(0, 1.78, 0) * e, 0.17 * e, 8, 6)
		_tabla(_st(s, "saco"), b + Vector3(-0.32, 1.5, 0) * e, b + Vector3(-0.4, 0.95, 0) * e, 0.14 * e, 0.14 * e)
		_tabla(_st(s, "saco"), b + Vector3(0.32, 1.5, 0) * e, b + Vector3(0.4, 0.95, 0) * e, 0.14 * e, 0.14 * e)
	var mats = _materiales()
	var raiz = Spatial.new()
	raiz.name = "_Vestido_Podio"
	add_child(raiz)
	for clave in s.keys():
		var mi = MeshInstance.new()
		mi.name = clave
		mi.mesh = s[clave].commit()
		mi.material_override = mats[clave]
		raiz.add_child(mi)


func _min(a, b):
	return Vector3(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z))


func _max(a, b):
	return Vector3(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z))


func _materiales():
	var m = {}
	m["estructura"] = _mat(color_estructura)
	m["detalle"] = _mat(color_detalle)
	m["techito"] = _mat(color_techito)
	m["saco"] = _mat(color_saco)
	m["pantalon"] = _mat(color_pantalon)
	m["piel"] = _mat(color_piel)
	return m


func _mat(c):
	var m = SpatialMaterial.new()
	m.albedo_color = c
	m.flags_unshaded = sin_sombreado
	return m


# ---------- Geometria ----------

func _st(s, clave):
	if not s.has(clave):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		s[clave] = st
	return s[clave]


func _caja(st, a, b):
	var mn = Vector3(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z))
	var mxv = Vector3(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z))
	_caja_orientada(st, (mn + mxv) * 0.5, (mxv - mn) * 0.5, Basis())


func _caja_orientada(st, c, h, b):
	var nx = b.x.normalized()
	var ny = b.y.normalized()
	var nz = b.z.normalized()
	var ex = nx * h.x
	var ey = ny * h.y
	var ez = nz * h.z
	var c000 = c - ex - ey - ez
	var c100 = c + ex - ey - ez
	var c010 = c - ex + ey - ez
	var c110 = c + ex + ey - ez
	var c001 = c - ex - ey + ez
	var c101 = c + ex - ey + ez
	var c011 = c - ex + ey + ez
	var c111 = c + ex + ey + ez
	_quad(st, c000, c100, c110, c010, -nz)
	_quad(st, c001, c011, c111, c101, nz)
	_quad(st, c000, c010, c011, c001, -nx)
	_quad(st, c100, c101, c111, c110, nx)
	_quad(st, c010, c110, c111, c011, ny)
	_quad(st, c000, c001, c101, c100, -ny)


func _tabla(st, a, b, ancho, grosor):
	var f = b - a
	var largo = f.length()
	if largo < 0.001:
		return
	f = f / largo
	var lado = f.cross(Vector3.UP)
	if lado.length() < 0.01:
		lado = f.cross(Vector3.RIGHT)
	lado = lado.normalized()
	var arriba = lado.cross(f).normalized()
	_caja_orientada(st, (a + b) * 0.5, Vector3(largo * 0.5, grosor * 0.5, ancho * 0.5), Basis(f, arriba, lado))


func _quad_uv(st, p, uv, n):
	var orden = [0, 1, 2, 0, 2, 3]
	if (p[1] - p[0]).cross(p[2] - p[0]).dot(n) > 0:
		orden = [0, 2, 1, 0, 3, 2]
	for i in orden:
		st.add_normal(n)
		st.add_uv(uv[i])
		st.add_vertex(p[i])


func _quad(st, a, b, c, d, n):
	_tri(st, a, b, c, n, n, n)
	_tri(st, a, c, d, n, n, n)


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


func _cono(st, base, eje, r0, r1, largo, segs, tapa_base, tapa_punta):
	var e = eje.normalized()
	var u = e.cross(Vector3.UP)
	if u.length() < 0.01:
		u = e.cross(Vector3.RIGHT)
	u = u.normalized()
	var v = e.cross(u).normalized()
	var punta = base + e * largo
	for i in range(segs):
		var a0 = TAU * i / segs
		var a1 = TAU * (i + 1) / segs
		var n0 = u * cos(a0) + v * sin(a0)
		var n1 = u * cos(a1) + v * sin(a1)
		var p0 = base + n0 * r0
		var p1 = base + n1 * r0
		var q0 = punta + n0 * r1
		var q1 = punta + n1 * r1
		_tri(st, p0, p1, q1, n0, n1, n1)
		_tri(st, p0, q1, q0, n0, n1, n0)
		if tapa_punta:
			_tri(st, punta, q0, q1, e, e, e)
		if tapa_base:
			_tri(st, base, p1, p0, -e, -e, -e)


func _esfera(st, centro, radio, segs, anillos):
	_elipsoide_parcial(st, centro, Vector3(radio, radio, radio), Basis(), segs, anillos, PI)


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
			if j < anillos - 1 or lat_max < PI:
				_tri(st, p00, p11, p10, n00, n11, n10)
