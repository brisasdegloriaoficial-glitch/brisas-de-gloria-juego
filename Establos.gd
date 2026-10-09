tool
extends Spatial

# Establos.gd — Viste la caja CSGBox cuyo nombre empiece con "Prefijo Cajas" (las caballerizas).
# NO mueve nada: toma posicion, giro y medidas de la caja que tu ubicas a mano.
# Dos naves paralelas a lo largo de la caja, con un pasillo al medio y un portal en cada punta.

export var prefijo_cajas = "Caballerizas"
export var ocultar_cajas = true
export var sin_sombreado = false

# --- Naves ---
export var ancho_pasillo = 35.0
export var alto_pared = 6.0
export var alto_zocalo = 0.9
export var pendiente_techo = 30.0
export var alero = 1.5
export var grosor_techo = 0.4

# --- Boxes, puertas y ventanas ---
export var ancho_box = 5.0
export var ancho_puerta = 2.6
export var alto_puerta = 3.8
export var poner_ventanas = true

# --- Cupulas del techo ---
export var cupulas_por_nave = 3

# --- Faroles en el pasillo ---
export var poner_faroles = true
export var separacion_faroles = 24.0
export var alto_farol = 4.5

# --- Portales de entrada con el logo BDG ---
export var poner_portales = true
export var alto_portal = 8.0
export var poner_logo = true
export var ruta_logo = "res://Caballos/Logo_Moneda_BDG_transparente.png"
export var tamano_logo = 3.0

# --- Colores ---
export var color_pared = Color("efe6d2")
export var color_zocalo = Color("b5a58a")
export var color_moldura = Color("fbf8f0")
export var color_puerta = Color("7b1e2b")
export var color_hueco = Color("1c1c1c")
export var color_ventana = Color("2a3440")
export var color_techo = Color("33415c")
export var color_piso = Color("b9ad96")
export var color_letrero = Color("7b1e2b")
export var color_dorado = Color("d4af37")
export var color_farol = Color("1f2a2a")
export var color_luz_farol = Color("fff2c4")

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
		var raiz = Spatial.new()
		raiz.name = "_Vestido_" + caja.name
		add_child(raiz)
		raiz.transform = global_transform.affine_inverse() * t
		_construir(raiz, caja.width * esc.x, caja.depth * esc.z, mats)


func _construir(raiz, W, D, mats):
	var s = {}
	var mx = W * 0.5
	var mz = D * 0.5
	var hp = clamp(ancho_pasillo * 0.5, 1.0, mz - 3.0)
	_nave(s, -mx, mx, -mz, -hp, 1)
	_nave(s, -mx, mx, hp, mz, -1)
	_caja(_st(s, "piso"), Vector3(-mx - 2.0, 0, -hp), Vector3(mx + 2.0, 0.12, hp))
	if poner_faroles and separacion_faroles > 1.0:
		var nf = int(max(1, floor((W - 10.0) / separacion_faroles)))
		for i in range(nf + 1):
			var xf = -(nf * separacion_faroles) * 0.5 + i * separacion_faroles
			_farol(s, Vector3(xf, 0.12, 0))
	if poner_portales:
		for sx in [-1, 1]:
			_portal(s, sx * (mx + 1.0), hp, sx, mats.has("logo"))
	for clave in s.keys():
		if not mats.has(clave):
			continue
		var mi = MeshInstance.new()
		mi.name = clave
		mi.mesh = s[clave].commit()
		mi.material_override = mats[clave]
		raiz.add_child(mi)


# Una nave: muros, zocalo, techo a dos aguas, puertas hacia el pasillo, ventanas hacia afuera y cupulas
func _nave(s, x0, x1, za, zb, lado):
	var zp = zb if lado > 0 else za
	var ze = za if lado > 0 else zb
	var o = float(lado)
	var zc = (za + zb) * 0.5
	var dn = zb - za
	var sube = tan(deg2rad(pendiente_techo))
	var yr = alto_pared + dn * 0.5 * sube
	var ye = alto_pared - alero * sube

	# Muros, zocalo, moldura de arriba y esquineros
	_caja(_st(s, "pared"), Vector3(x0, 0, za), Vector3(x1, alto_pared - 0.02, zb))
	_caja(_st(s, "zocalo"), Vector3(x0 - 0.1, 0, za - 0.1), Vector3(x1 + 0.1, alto_zocalo, zb + 0.1))
	_caja(_st(s, "moldura"), Vector3(x0 - 0.12, alto_pared - 0.4, za - 0.12), Vector3(x1 + 0.12, alto_pared, zb + 0.12))
	for x in [x0, x1]:
		for z in [za, zb]:
			_caja(_st(s, "moldura"), Vector3(x - 0.3, 0, z - 0.3), Vector3(x + 0.3, alto_pared - 0.05, z + 0.3))

	# Frontones (triangulos de las puntas) con un ojo de buey
	var r_ojo = clamp((yr - alto_pared) * 0.22, 0.4, 1.4)
	var y_ojo = alto_pared + (yr - alto_pared) * 0.4
	for px in [[x0, -1.0], [x1, 1.0]]:
		var n = Vector3(px[1], 0, 0)
		_tri(_st(s, "pared"), Vector3(px[0], alto_pared, za), Vector3(px[0], alto_pared, zb), Vector3(px[0], yr, zc), n, n, n)
		_cono(_st(s, "moldura"), Vector3(px[0], y_ojo, zc), n, r_ojo + 0.25, r_ojo + 0.25, 0.15, 20, false, true)
		_cono(_st(s, "hueco"), Vector3(px[0], y_ojo, zc), n, r_ojo, r_ojo, 0.22, 20, false, true)

	# Techo a dos aguas, cumbrera y tapas blancas del borde
	var largo_techo = (x1 - x0) + alero * 2.0
	for sg in [-1.0, 1.0]:
		var z_alero = zc + sg * (dn * 0.5 + alero)
		_tabla(_st(s, "techo"), Vector3(0, ye, z_alero), Vector3(0, yr, zc), largo_techo, grosor_techo)
		_caja(_st(s, "moldura"), Vector3(x0 - alero, ye - 0.45, z_alero - 0.12), Vector3(x1 + alero, ye + 0.3, z_alero + 0.12))
		for xf in [x0 - alero + 0.12, x1 + alero - 0.12]:
			_tabla(_st(s, "moldura"), Vector3(xf, ye, z_alero), Vector3(xf, yr, zc), 0.25, 0.75)
	_caja(_st(s, "techo"), Vector3(x0 - alero, yr - 0.1, zc - 0.4), Vector3(x1 + alero, yr + 0.45, zc + 0.4))

	# Puertas de los boxes hacia el pasillo (hoja de abajo con cruz, hueco oscuro arriba)
	var nb = int(max(1, round((x1 - x0) / ancho_box)))
	var pb = (x1 - x0) / nb
	var hw = ancho_puerta * 0.5
	var ym = alto_puerta * 0.55
	for i in range(nb):
		var xc = x0 + (i + 0.5) * pb
		_caja(_st(s, "puerta"), Vector3(xc - hw, 0, zp), Vector3(xc + hw, ym, zp + o * 0.15))
		_caja(_st(s, "hueco"), Vector3(xc - hw, ym, zp), Vector3(xc + hw, alto_puerta, zp + o * 0.05))
		_caja(_st(s, "moldura"), Vector3(xc - hw - 0.25, 0, zp), Vector3(xc - hw, alto_puerta + 0.25, zp + o * 0.25))
		_caja(_st(s, "moldura"), Vector3(xc + hw, 0, zp), Vector3(xc + hw + 0.25, alto_puerta + 0.25, zp + o * 0.25))
		_caja(_st(s, "moldura"), Vector3(xc - hw - 0.25, alto_puerta, zp), Vector3(xc + hw + 0.25, alto_puerta + 0.25, zp + o * 0.25))
		_caja(_st(s, "moldura"), Vector3(xc - hw, ym - 0.1, zp), Vector3(xc + hw, ym + 0.1, zp + o * 0.22))
		var zf = zp + o * 0.2
		_tabla(_st(s, "moldura"), Vector3(xc - hw + 0.15, 0.2, zf), Vector3(xc + hw - 0.15, ym - 0.15, zf), 0.08, 0.2)
		_tabla(_st(s, "moldura"), Vector3(xc - hw + 0.15, ym - 0.15, zf), Vector3(xc + hw - 0.15, 0.2, zf), 0.08, 0.2)

	# Ventanas hacia afuera, una por box
	if poner_ventanas:
		var oe = -o
		var y0 = alto_pared * 0.45
		var y1 = y0 + 1.3
		var vw = 0.8
		for i in range(nb):
			var xc = x0 + (i + 0.5) * pb
			_caja(_st(s, "ventana"), Vector3(xc - vw, y0, ze), Vector3(xc + vw, y1, ze + oe * 0.06))
			_caja(_st(s, "moldura"), Vector3(xc - vw - 0.15, y0 - 0.15, ze), Vector3(xc + vw + 0.15, y0, ze + oe * 0.18))
			_caja(_st(s, "moldura"), Vector3(xc - vw - 0.15, y1, ze), Vector3(xc + vw + 0.15, y1 + 0.15, ze + oe * 0.18))
			_caja(_st(s, "moldura"), Vector3(xc - vw - 0.15, y0, ze), Vector3(xc - vw, y1, ze + oe * 0.18))
			_caja(_st(s, "moldura"), Vector3(xc + vw, y0, ze), Vector3(xc + vw + 0.15, y1, ze + oe * 0.18))
			_caja(_st(s, "moldura"), Vector3(xc - 0.05, y0, ze), Vector3(xc + 0.05, y1, ze + oe * 0.12))

	# Cupulas de ventilacion sobre la cumbrera
	for k in range(int(max(0, cupulas_por_nave))):
		var xk = x0 + (x1 - x0) * (k + 0.5) / cupulas_por_nave
		var b = 1.6
		var yb = yr - 0.6
		_caja(_st(s, "pared"), Vector3(xk - b, yb, zc - b), Vector3(xk + b, yb + 2.6, zc + b))
		_caja(_st(s, "hueco"), Vector3(xk - b * 0.6, yb + 0.9, zc - b - 0.05), Vector3(xk + b * 0.6, yb + 2.1, zc + b + 0.05))
		_caja(_st(s, "hueco"), Vector3(xk - b - 0.05, yb + 0.9, zc - b * 0.6), Vector3(xk + b + 0.05, yb + 2.1, zc + b * 0.6))
		_caja(_st(s, "moldura"), Vector3(xk - b - 0.15, yb + 2.6, zc - b - 0.15), Vector3(xk + b + 0.15, yb + 2.85, zc + b + 0.15))
		_piramide(_st(s, "techo"), Vector3(xk, yb + 2.85, zc), b + 0.5, 2.0)
		_cono(_st(s, "dorado"), Vector3(xk, yb + 4.7, zc), Vector3.UP, 0.08, 0.04, 1.6, 6, false, true)
		_esfera(_st(s, "dorado"), Vector3(xk, yb + 5.0, zc), 0.25, 8, 5, false)


# Portal de entrada al pasillo, con letrero y logo BDG por ambas caras
func _portal(s, xp, hp, sx, con_logo):
	var pz = hp - 0.9
	for sz in [-1.0, 1.0]:
		var z = sz * pz
		_caja(_st(s, "pared"), Vector3(xp - 0.7, 0, z - 0.7), Vector3(xp + 0.7, alto_portal, z + 0.7))
		_caja(_st(s, "zocalo"), Vector3(xp - 0.85, 0, z - 0.85), Vector3(xp + 0.85, 1.2, z + 0.85))
		_caja(_st(s, "moldura"), Vector3(xp - 0.85, alto_portal, z - 0.85), Vector3(xp + 0.85, alto_portal + 0.35, z + 0.85))
		_esfera(_st(s, "dorado"), Vector3(xp, alto_portal + 0.8, z), 0.45, 10, 6, false)
	_caja(_st(s, "moldura"), Vector3(xp - 0.5, alto_portal - 1.4, -pz), Vector3(xp + 0.5, alto_portal - 0.6, pz))
	var h = tamano_logo * 0.5
	var yl = alto_portal - 0.6 + h + 0.5
	_caja(_st(s, "dorado"), Vector3(xp - 0.2, yl - h - 0.45, -h - 0.45), Vector3(xp + 0.2, yl + h + 0.45, h + 0.45))
	_caja(_st(s, "letrero"), Vector3(xp - 0.3, yl - h - 0.3, -h - 0.3), Vector3(xp + 0.3, yl + h + 0.3, h + 0.3))
	if con_logo:
		for sg in [-1.0, 1.0]:
			var xq = xp + sg * 0.32
			var pts = [Vector3(xq, yl + h, sg * h), Vector3(xq, yl + h, -sg * h), Vector3(xq, yl - h, -sg * h), Vector3(xq, yl - h, sg * h)]
			var uvs = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
			_quad_uv(_st(s, "logo"), pts, uvs, Vector3(sg, 0, 0))


func _farol(s, base):
	var h = alto_farol
	_cono(_st(s, "farol"), base, Vector3.UP, 0.35, 0.35, 0.4, 8, false, true)
	_cono(_st(s, "farol"), base, Vector3.UP, 0.12, 0.09, h, 8, false, false)
	var c = base + Vector3(0, h, 0)
	_caja(_st(s, "farol"), c + Vector3(-0.4, 0, -0.4), c + Vector3(0.4, 0.1, 0.4))
	_caja(_st(s, "luz_farol"), c + Vector3(-0.3, 0.1, -0.3), c + Vector3(0.3, 0.9, 0.3))
	_piramide(_st(s, "farol"), c + Vector3(0, 0.9, 0), 0.45, 0.45)
	_esfera(_st(s, "dorado"), c + Vector3(0, 1.45, 0), 0.12, 6, 4, false)


func _piramide(st, c, m, alto):
	var cima = c + Vector3(0, alto, 0)
	var esquinas = [c + Vector3(-m, 0, -m), c + Vector3(m, 0, -m), c + Vector3(m, 0, m), c + Vector3(-m, 0, m)]
	for i in range(4):
		var a = esquinas[i]
		var b = esquinas[(i + 1) % 4]
		var n = (b - a).cross(cima - a).normalized()
		var fuera = ((a + b) * 0.5 - c)
		if n.dot(fuera) < 0:
			n = -n
		_tri(st, a, b, cima, n, n, n)


# ---------- Materiales ----------

func _materiales():
	var m = {}
	m["pared"] = _mat(color_pared)
	m["zocalo"] = _mat(color_zocalo)
	m["moldura"] = _mat(color_moldura)
	m["puerta"] = _mat(color_puerta)
	m["hueco"] = _mat(color_hueco)
	m["ventana"] = _mat(color_ventana)
	m["techo"] = _mat(color_techo)
	m["piso"] = _mat(color_piso)
	m["letrero"] = _mat(color_letrero)
	m["farol"] = _mat(color_farol)
	var luz = _mat(color_luz_farol)
	luz.flags_unshaded = true
	m["luz_farol"] = luz
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
