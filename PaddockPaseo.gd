tool
extends Spatial

# PaddockPaseo.gd — Viste la caja CSGBox cuyo nombre empiece con "Prefijo Cajas".
# NO mueve nada: toma posicion, giro y medidas de la caja que tu ubicas a mano.
# Ovalo de paseo: baranda blanca por fuera, camino de arena, cesped al centro con su baranda,
# y un portal de entrada con el logo BDG mirando hacia +Z (hacia la pista). "Girar 180" lo da vuelta.

export var prefijo_cajas = "Paddock_de_Paseo"
export var ocultar_cajas = true
export var sin_sombreado = false
export var girar_180 = false

# --- Ovalo ---
export var ancho_camino = 7.0
export var separacion_postes = 3.0
export var alto_baranda = 1.35
export var ancho_entrada = 8.0
export var poner_baranda_interna = true

# --- Portal de entrada ---
export var poner_portal = true
export var alto_portal = 5.5
export var poner_logo = true
export var ruta_logo = "res://Caballos/Logo_BDG.png"
export var tamano_logo = 2.6

# --- Colores ---
export var color_baranda = Color("fbf8f0")
export var color_camino = Color("c9b28a")
export var color_cesped = Color("4f8a3a")
export var color_letrero = Color("222988")
export var color_dorado = Color("d4af37")

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


func _cajas():
	var lista = []
	var padre = get_parent()
	if padre == null:
		return lista
	for n in padre.get_children():
		if n is CSGBox and n.name.begins_with(prefijo_cajas):
			lista.append(n)
	return lista


func _calcular_firma():
	var s = ""
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_EDITOR:
			s += str(get(p.name))
	for c in _cajas():
		s += c.name + str(c.global_transform) + str(c.width) + str(c.depth)
	return s


func _reconstruir():
	if not is_inside_tree():
		return
	_firma = _calcular_firma()
	for h in get_children():
		if h.name.begins_with("_Vestido"):
			remove_child(h)
			h.queue_free()
	var mats = _materiales()
	for caja in _cajas():
		caja.visible = not ocultar_cajas
		var t = caja.global_transform
		var esc = t.basis.get_scale()
		t.basis = t.basis.orthonormalized()
		if girar_180:
			t.basis = t.basis.rotated(Vector3.UP, PI)
		var raiz = Spatial.new()
		raiz.name = "_Vestido_" + caja.name
		add_child(raiz)
		raiz.transform = global_transform.affine_inverse() * t
		_construir(raiz, caja.width * esc.x, caja.depth * esc.z, mats)


func _construir(raiz, W, D, mats):
	var s = {}
	var rx = W * 0.5 - 1.0
	var rz = D * 0.5 - 1.0
	var c0 = Vector3.ZERO

	# 1. Camino de arena y cesped al centro
	var rxc = rx - 0.6
	var rzc = rz - 0.6
	var ac = min(ancho_camino, min(rxc, rzc) - 2.0)
	_anillo(_st(s, "camino"), c0, rxc, rzc, ac, 0.12, 64)
	var rxi = rxc - ac
	var rzi = rzc - ac
	_elipse(_st(s, "cesped"), c0, rxi, rzi, 0.25, 64)

	# 2. Baranda de afuera con la entrada del lado +Z, y baranda del cesped
	var entrada = Vector2(0, rz)
	_baranda(s, rx, rz, entrada, ancho_entrada * 0.5)
	if poner_baranda_interna:
		_baranda(s, rxi - 0.6, rzi - 0.6, Vector2(0, 99999), 0.0)

	# 3. Portal de entrada con el logo BDG por ambas caras
	if poner_portal:
		var hg = ancho_entrada * 0.5 + 0.4
		var zp = rz
		for sx in [-1.0, 1.0]:
			var x = sx * hg
			_caja(_st(s, "baranda"), Vector3(x - 0.35, 0, zp - 0.35), Vector3(x + 0.35, alto_portal, zp + 0.35))
			_caja(_st(s, "dorado"), Vector3(x - 0.45, alto_portal, zp - 0.45), Vector3(x + 0.45, alto_portal + 0.2, zp + 0.45))
			_esfera(_st(s, "dorado"), Vector3(x, alto_portal + 0.55, zp), 0.35, 10, 6, false)
		_caja(_st(s, "baranda"), Vector3(-hg, alto_portal - 0.9, zp - 0.25), Vector3(hg, alto_portal - 0.4, zp + 0.25))
		var h = tamano_logo * 0.5
		var yl = alto_portal - 0.4 + h + 0.35
		_caja(_st(s, "dorado"), Vector3(-h - 0.3, yl - h - 0.3, zp - 0.12), Vector3(h + 0.3, yl + h + 0.3, zp + 0.12))
		_caja(_st(s, "letrero"), Vector3(-h - 0.18, yl - h - 0.18, zp - 0.2), Vector3(h + 0.18, yl + h + 0.18, zp + 0.2))
		if mats.has("logo"):
			for sz in [-1.0, 1.0]:
				var c = Vector3(0, yl, zp + sz * 0.22)
				var p4 = [c + Vector3(-sz * h, h, 0), c + Vector3(sz * h, h, 0), c + Vector3(sz * h, -h, 0), c + Vector3(-sz * h, -h, 0)]
				_quad_uv(_st(s, "logo"), p4, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)], Vector3(0, 0, sz))

	for clave in s.keys():
		if not mats.has(clave):
			continue
		var mi = MeshInstance.new()
		mi.name = clave
		mi.mesh = s[clave].commit()
		mi.material_override = mats[clave]
		raiz.add_child(mi)


# Baranda blanca de dos tablas sobre un ovalo; deja libre un hueco alrededor del punto "entrada"
func _baranda(s, rx, rz, entrada, medio_hueco):
	var datos = _puntos_ovalo(rx, rz, separacion_postes)
	var pts = datos[0]
	var vivos = []
	for p in pts:
		vivos.append(p[0].distance_to(entrada) > medio_hueco)
	var ab = alto_baranda
	for k in range(pts.size()):
		if not vivos[k]:
			continue
		var q = pts[k][0]
		_caja(_st(s, "baranda"), Vector3(q.x - 0.1, 0, q.y - 0.1), Vector3(q.x + 0.1, ab, q.y + 0.1))
		var k2 = (k + 1) % pts.size()
		if vivos[k2]:
			var q2 = pts[k2][0]
			for yb in [ab * 0.42, ab * 0.88]:
				_tabla(_st(s, "baranda"), Vector3(q.x, yb, q.y), Vector3(q2.x, yb, q2.y), 0.12, 0.18)


# Postes repartidos a igual distancia sobre el ovalo. Devuelve [[punto, distancia_recorrida], ...] y el largo total.
func _puntos_ovalo(rx, rz, paso):
	var muestras = 720
	var lista = [Vector2(rx, 0)]
	var acum = [0.0]
	var total = 0.0
	for i in range(1, muestras + 1):
		var a = TAU * i / muestras
		var p = Vector2(cos(a) * rx, sin(a) * rz)
		total += p.distance_to(lista[i - 1])
		lista.append(p)
		acum.append(total)
	var n = int(max(8, round(total / paso)))
	var d = total / n
	var res = []
	var j = 0
	for k in range(n):
		var objetivo = k * d
		while j < muestras - 1 and acum[j + 1] < objetivo:
			j += 1
		var f = (objetivo - acum[j]) / max(0.0001, acum[j + 1] - acum[j])
		res.append([lista[j].linear_interpolate(lista[j + 1], f), objetivo])
	return [res, total]


# Elipse maciza (cesped del centro)
func _elipse(st, c, rx, rz, alto, segs):
	var up = Vector3(0, alto, 0)
	for i in range(segs):
		var a0 = TAU * i / segs
		var a1 = TAU * (i + 1) / segs
		var p0 = c + Vector3(cos(a0) * rx, 0, sin(a0) * rz)
		var p1 = c + Vector3(cos(a1) * rx, 0, sin(a1) * rz)
		var n0 = Vector3(cos(a0) / rx, 0, sin(a0) / rz).normalized()
		var n1 = Vector3(cos(a1) / rx, 0, sin(a1) / rz).normalized()
		_tri(st, c + up, p0 + up, p1 + up, Vector3.UP, Vector3.UP, Vector3.UP)
		_tri(st, p0, p1, p1 + up, n0, n1, n1)
		_tri(st, p0, p1 + up, p0 + up, n0, n1, n0)


# Anillo eliptico (camino de arena)
func _anillo(st, c, rx, rz, ancho, alto, segs):
	var up = Vector3(0, alto, 0)
	for i in range(segs):
		var a0 = TAU * i / segs
		var a1 = TAU * (i + 1) / segs
		var o0 = c + Vector3(cos(a0) * rx, 0, sin(a0) * rz)
		var o1 = c + Vector3(cos(a1) * rx, 0, sin(a1) * rz)
		var i0 = c + Vector3(cos(a0) * (rx - ancho), 0, sin(a0) * (rz - ancho))
		var i1 = c + Vector3(cos(a1) * (rx - ancho), 0, sin(a1) * (rz - ancho))
		var n0 = Vector3(cos(a0) / rx, 0, sin(a0) / rz).normalized()
		var n1 = Vector3(cos(a1) / rx, 0, sin(a1) / rz).normalized()
		_quad(st, o0 + up, o1 + up, i1 + up, i0 + up, Vector3.UP)
		_tri(st, o0, o1, o1 + up, n0, n1, n1)
		_tri(st, o0, o1 + up, o0 + up, n0, n1, n0)


# ---------- Materiales ----------

func _materiales():
	var m = {}
	m["baranda"] = _mat(color_baranda)
	m["camino"] = _mat(color_camino)
	m["cesped"] = _mat(color_cesped)
	m["letrero"] = _mat(color_letrero)
	var d = _mat(color_dorado)
	d.metallic = 0.4
	d.roughness = 0.35
	m["dorado"] = d
	if poner_logo and ResourceLoader.exists(ruta_logo):
		var tex = load(ruta_logo)
		if tex is Texture:
			var ml = SpatialMaterial.new()
			ml.albedo_texture = tex
			ml.flags_transparent = true
			ml.params_use_alpha_scissor = true
			ml.params_alpha_scissor_threshold = 0.5
			ml.params_cull_mode = SpatialMaterial.CULL_DISABLED
			ml.flags_unshaded = sin_sombreado
			m["logo"] = ml
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


func _esfera(st, centro, radio, segs, anillos, media):
	_elipsoide_parcial(st, centro, Vector3(radio, radio, radio), Basis(), segs, anillos, PI * 0.5 if media else PI)


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
