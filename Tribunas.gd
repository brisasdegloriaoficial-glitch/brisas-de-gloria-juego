tool
extends Spatial

# Tribunas.gd — Viste cada caja CSGBox cuyo nombre empiece con "Prefijo Cajas".
# NO mueve nada: toma posicion, giro y ancho de cada caja que tu ubicas a mano.
# Gradas abajo, palcos arriba, columnas, cornisas doradas, torre con reloj y cupula,
# y mastiles con banderas. Cada parte se prende o apaga con su casilla.

export var prefijo_cajas = "Tribuna"
export var ocultar_cajas = true
export var sin_sombreado = false
# PESO: une todas las partes de cada tribuna en UNA pieza con sus
# colores (el vidrio y el dorado van aparte porque se pintan distinto).
# Antes eran unas 16 piezas por tribuna. Desmarcar = como estaba.
export var unir_en_una_pieza = true
var _mats_actuales = {}
var _color_actual = Color(1, 1, 1)

# --- Gradas ---
export var altura_podio = 4.0
export var cantidad_escalones = 20
export var alto_escalon = 1.2
export var profundidad_gradas = 40.0
export var alto_asiento = 0.45
export var fondo_asiento = 0.9
export var ancho_seccion = 20.0
export var ancho_pasillo = 1.5

# --- Palcos ---
export var pisos_palcos = 4
export var alto_palco = 5.0
export var profundidad_palco = 14.0
export var ancho_palco = 12.0
export var alto_antepecho = 1.0
export var grosor_muro = 0.5

# --- Techo ---
export var voladizo_techo = 34.0
export var grosor_techo = 1.2
export var alto_franja_techo = 2.5

# --- Cornisa y remates dorados ---
export var poner_cornisa = true
export var separacion_remates = 26.0
export var radio_remate = 0.8

# --- Columnas de la fachada ---
export var poner_columnas = true
export var separacion_columnas = 12.0
export var radio_columna = 0.7

# --- Torre central con reloj y cupula ---
export var poner_torre = true
export var torre_solo_en = ""
export var ancho_torre = 18.0
export var adelanto_torre = 2.0
export var alto_torre = 16.0
export var radio_reloj = 5.0
export var alto_tambor = 3.0
export var alto_aguja = 5.0

# --- Mastiles con banderas ---
export var poner_mastiles = true
export var cantidad_mastiles = 7
export var alto_mastil = 12.0
export var grosor_mastil = 0.35
export var ancho_bandera = 6.0
export var alto_bandera = 3.5
export var colores_banderas = "7b1e2b,d4af37,222988,ffffff,1311f7"

# --- Colores ---
export var color_concreto = Color("d9d4c7")
export var color_fachada = Color("f3ecdc")
export var color_columnas = Color("fbf8f0")
export var color_asientos = Color("222988")
export var color_vidrio = Color("6fb3dc")
export var opacidad_vidrio = 0.45
export var color_techo = Color("222988")
export var color_franja = Color("1311f7")
export var color_dorado = Color("d4af37")
export var metal_dorado = 0.4
export var aspereza_dorado = 0.35
export var color_cupula = Color("7b1e2b")
export var color_reloj = Color("fbf8f0")
export var color_manecillas = Color("1a1a1a")
export var color_mastil = Color("f2f2f2")

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
		var ancho = caja.width * t.basis.get_scale().x
		t.basis = t.basis.orthonormalized()
		if t.origin.z < 0.0:
			t.basis = t.basis.rotated(Vector3.UP, PI)
		var raiz = Spatial.new()
		raiz.name = "_Vestido_" + caja.name
		add_child(raiz)
		raiz.transform = global_transform.affine_inverse() * t
		var con_torre = poner_torre and (torre_solo_en.strip_edges() == "" or torre_solo_en.find(caja.name) >= 0)
		_construir(raiz, ancho, caja.depth, mats, con_torre)


func _construir(raiz, ancho, fondo_caja, mats, con_torre):
	_mats_actuales = mats
	var s = {}
	var mx = ancho * 0.5
	var z0 = -fondo_caja * 0.5
	var zg = z0 + profundidad_gradas
	var zp = zg + profundidad_palco
	var n = int(max(1, cantidad_escalones))
	var huella = profundidad_gradas / n
	var y_gradas = altura_podio + n * alto_escalon
	var hay_palcos = pisos_palcos > 0

	# 1. Podio y antepecho frontal
	_caja(_st(s, "concreto"), Vector3(-mx, 0, z0), Vector3(mx, altura_podio, zg))
	_caja(_st(s, "franja"), Vector3(-mx, altura_podio, z0), Vector3(mx, altura_podio + 1.1, z0 + grosor_muro))
	if poner_cornisa:
		_caja(_st(s, "dorado"), Vector3(-mx, altura_podio + 1.1, z0 - 0.05), Vector3(mx, altura_podio + 1.3, z0 + grosor_muro + 0.05))

	# 2. Escalones y asientos (la fila de arriba queda libre como pasillo)
	var nsec = int(max(1, round(ancho / ancho_seccion)))
	var wsec = ancho / nsec
	for i in range(n):
		var zi = z0 + i * huella
		var ytop = altura_podio + (i + 1) * alto_escalon
		_caja(_st(s, "concreto"), Vector3(-mx, ytop - alto_escalon, zi), Vector3(mx, ytop, zg))
		if i == n - 1 and n > 1:
			continue
		var zs = zi + huella * 0.3
		for k in range(nsec):
			var xa = -mx + k * wsec + ancho_pasillo * 0.5
			var xb = -mx + (k + 1) * wsec - ancho_pasillo * 0.5
			_caja(_st(s, "asientos"), Vector3(xa, ytop, zs), Vector3(xb, ytop + alto_asiento, zs + fondo_asiento))

	# 3. Base maciza bajo los palcos
	_caja(_st(s, "concreto"), Vector3(-mx, 0, zg), Vector3(mx, y_gradas, zp))

	# 4. Palcos
	var y = y_gradas
	var npal = int(max(1, round(ancho / ancho_palco)))
	var paso = ancho / npal
	for p in range(int(max(0, pisos_palcos))):
		_caja(_st(s, "fachada"), Vector3(-mx, y, zg), Vector3(mx, y + grosor_muro, zp))
		_caja(_st(s, "fachada"), Vector3(-mx, y, zp - grosor_muro), Vector3(mx, y + alto_palco, zp))
		_caja(_st(s, "fachada"), Vector3(-mx, y, zg), Vector3(mx, y + grosor_muro + alto_antepecho, zg + grosor_muro))
		_caja(_st(s, "vidrio"), Vector3(-mx, y + grosor_muro + alto_antepecho, zg + 0.1), Vector3(mx, y + alto_palco, zg + 0.2))
		for k in range(npal + 1):
			var x = -mx + k * paso
			_caja(_st(s, "fachada"), Vector3(x - grosor_muro * 0.5, y, zg), Vector3(x + grosor_muro * 0.5, y + alto_palco, zp))
		if poner_cornisa:
			_caja(_st(s, "dorado"), Vector3(-mx, y - 0.2, zg - 0.3), Vector3(mx, y + 0.2, zg + 0.05))
		y += alto_palco
	var y_techo = y

	# 5. Columnas en la fachada de los palcos
	if poner_columnas and hay_palcos:
		var ncol = int(max(1, round(ancho / separacion_columnas)))
		var pc = ancho / ncol
		var rc = radio_columna
		var zc = zg - rc - 0.3
		var alto_col = y_techo - y_gradas
		var mat_capitel = "dorado" if poner_cornisa else "fachada"
		for k in range(ncol + 1):
			var x = -mx + k * pc
			_caja(_st(s, "fachada"), Vector3(x - rc - 0.3, y_gradas, zc - rc - 0.3), Vector3(x + rc + 0.3, y_gradas + 0.6, zc + rc + 0.3))
			_cilindro(_st(s, "columnas"), Vector3(x, y_gradas + 0.6, zc), Vector3.UP, rc, alto_col - 1.2, 12, false, false)
			_caja(_st(s, mat_capitel), Vector3(x - rc - 0.35, y_techo - 0.6, zc - rc - 0.35), Vector3(x + rc + 0.35, y_techo, zc + rc + 0.35))

	# 6. Techo en voladizo y franja frontal
	var zf = zg - voladizo_techo
	var y_arriba = y_techo + grosor_techo
	var y_bajo_franja = y_arriba - alto_franja_techo
	_caja(_st(s, "techo"), Vector3(-mx, y_techo, zf), Vector3(mx, y_arriba, zp))
	_caja(_st(s, "franja"), Vector3(-mx, y_bajo_franja, zf - 0.4), Vector3(mx, y_arriba, zf))

	# 7. Cornisa y remates dorados
	if poner_cornisa:
		_caja(_st(s, "dorado"), Vector3(-mx - 0.1, y_arriba, zf - 0.5), Vector3(mx + 0.1, y_arriba + 0.35, zf + 0.1))
		_caja(_st(s, "dorado"), Vector3(-mx - 0.1, y_bajo_franja - 0.3, zf - 0.5), Vector3(mx + 0.1, y_bajo_franja, zf + 0.1))
		var nrem = int(max(1, round(ancho / separacion_remates)))
		var pr = ancho / nrem
		for k in range(nrem + 1):
			var x = -mx + k * pr
			if con_torre and abs(x) < ancho_torre * 0.5 + 2.0:
				continue
			_caja(_st(s, "fachada"), Vector3(x - 0.6, y_arriba, zg - 0.6), Vector3(x + 0.6, y_arriba + 1.5, zg + 0.6))
			_esfera(_st(s, "dorado"), Vector3(x, y_arriba + 1.5 + radio_remate, zg), radio_remate, 10, 6, false)

	# 8. Torre central con reloj y cupula
	if con_torre:
		var tx = ancho_torre * 0.5
		var tz0 = zg - adelanto_torre
		var tz1 = zp
		var ty0 = y_arriba
		var ty1 = ty0 + alto_torre
		_caja(_st(s, "fachada"), Vector3(-tx, ty0, tz0), Vector3(tx, ty1, tz1))
		if poner_cornisa:
			_caja(_st(s, "dorado"), Vector3(-tx - 0.4, ty1 - 0.6, tz0 - 0.4), Vector3(tx + 0.4, ty1, tz1 + 0.4))
			_caja(_st(s, "dorado"), Vector3(-tx - 0.3, ty0, tz0 - 0.3), Vector3(tx + 0.3, ty0 + 0.5, tz1 + 0.3))
		# Reloj en la cara que mira a la pista
		var cr = Vector3(0, ty0 + alto_torre * 0.55, tz0)
		var hacia_pista = Vector3(0, 0, -1)
		_cilindro(_st(s, "dorado"), cr, hacia_pista, radio_reloj + 0.6, 0.25, 32, false, true)
		_cilindro(_st(s, "reloj"), cr, hacia_pista, radio_reloj, 0.4, 32, false, true)
		for h in range(12):
			var ang = TAU * h / 12.0
			var px = sin(ang) * radio_reloj * 0.82
			var py = cos(ang) * radio_reloj * 0.82
			var tm = 0.35 if h % 3 == 0 else 0.2
			_caja(_st(s, "dorado"), cr + Vector3(px - tm, py - tm, -0.5), cr + Vector3(px + tm, py + tm, -0.4))
		_caja(_st(s, "manecillas"), cr + Vector3(-0.18, -0.5, -0.65), cr + Vector3(0.18, radio_reloj * 0.8, -0.5))
		_caja(_st(s, "manecillas"), cr + Vector3(-0.5, -0.25, -0.65), cr + Vector3(radio_reloj * 0.55, 0.25, -0.5))
		# Tambor, cupula y aguja
		var rd = min(ancho_torre, tz1 - tz0) * 0.42
		var cz = (tz0 + tz1) * 0.5
		_cilindro(_st(s, "fachada"), Vector3(0, ty1, cz), Vector3.UP, rd, alto_tambor, 24, false, false)
		if poner_cornisa:
			_cilindro(_st(s, "dorado"), Vector3(0, ty1 + alto_tambor - 0.4, cz), Vector3.UP, rd + 0.3, 0.4, 24, true, true)
		_esfera(_st(s, "cupula"), Vector3(0, ty1 + alto_tambor, cz), rd, 24, 10, true)
		var yc = ty1 + alto_tambor + rd
		_cilindro(_st(s, "dorado"), Vector3(0, yc - 0.5, cz), Vector3.UP, 0.3, alto_aguja, 8, false, true)
		_esfera(_st(s, "dorado"), Vector3(0, yc + alto_aguja - 0.5, cz), 0.8, 10, 6, false)

	# 9. Mastiles con banderas en el techo
	if poner_mastiles and cantidad_mastiles > 0:
		var lista = colores_banderas.split(",", false)
		var z_m = (zg + zp) * 0.5
		var g = grosor_mastil * 0.5
		for m in range(cantidad_mastiles):
			var x_m = -mx + ancho * (m + 0.5) / cantidad_mastiles
			if con_torre and abs(x_m) < ancho_torre * 0.5 + 2.0:
				continue
			_cilindro(_st(s, "mastil"), Vector3(x_m, y_arriba, z_m), Vector3.UP, g, alto_mastil, 8, false, true)
			if poner_cornisa:
				_esfera(_st(s, "dorado"), Vector3(x_m, y_arriba + alto_mastil + 0.3, z_m), 0.4, 8, 5, false)
			if lista.size() > 0:
				var yb = y_arriba + alto_mastil - 0.3
				var clave = "bandera_" + str(m % lista.size())
				_caja(_st(s, clave), Vector3(x_m + g, yb - alto_bandera, z_m - 0.05), Vector3(x_m + g + ancho_bandera, yb, z_m + 0.05))

	for clave in s.keys():
		var mat = null
		if clave == "todo":
			mat = SpatialMaterial.new()
			mat.vertex_color_use_as_albedo = true
			mat.vertex_color_is_srgb = true
			mat.flags_unshaded = sin_sombreado
			mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
		elif mats.has(clave):
			mat = mats[clave]
		else:
			continue
		var mi = MeshInstance.new()
		mi.name = clave
		mi.mesh = s[clave].commit()
		mi.material_override = mat
		raiz.add_child(mi)


func _materiales():
	var cv = color_vidrio
	cv.a = opacidad_vidrio
	var m = {}
	m["concreto"] = _mat(color_concreto, false)
	m["fachada"] = _mat(color_fachada, false)
	m["columnas"] = _mat(color_columnas, false)
	m["asientos"] = _mat(color_asientos, false)
	m["vidrio"] = _mat(cv, true)
	m["techo"] = _mat(color_techo, false)
	m["franja"] = _mat(color_franja, false)
	m["cupula"] = _mat(color_cupula, false)
	m["reloj"] = _mat(color_reloj, false)
	m["manecillas"] = _mat(color_manecillas, false)
	m["mastil"] = _mat(color_mastil, false)
	var d = _mat(color_dorado, false)
	d.metallic = metal_dorado
	d.roughness = aspereza_dorado
	m["dorado"] = d
	var lista = colores_banderas.split(",", false)
	for i in range(lista.size()):
		var bm = _mat(Color(lista[i].strip_edges()), false)
		bm.params_cull_mode = SpatialMaterial.CULL_DISABLED
		m["bandera_" + str(i)] = bm
	return m


func _mat(c, transparente):
	var m = SpatialMaterial.new()
	m.albedo_color = c
	m.flags_unshaded = sin_sombreado
	if transparente:
		m.flags_transparent = true
		m.params_cull_mode = SpatialMaterial.CULL_DISABLED
	return m


func _st(s, clave):
	# Todo lo que no es vidrio ni dorado va a la misma pieza, con su color.
	if unir_en_una_pieza and clave != "vidrio" and clave != "dorado" and _mats_actuales.has(clave):
		_color_actual = _mats_actuales[clave].albedo_color
		clave = "todo"
	else:
		_color_actual = Color(1, 1, 1)
	if not s.has(clave):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		s[clave] = st
	return s[clave]


func _caja(st, a, b):
	var x0 = min(a.x, b.x)
	var x1 = max(a.x, b.x)
	var y0 = min(a.y, b.y)
	var y1 = max(a.y, b.y)
	var z0 = min(a.z, b.z)
	var z1 = max(a.z, b.z)
	var c000 = Vector3(x0, y0, z0)
	var c100 = Vector3(x1, y0, z0)
	var c010 = Vector3(x0, y1, z0)
	var c110 = Vector3(x1, y1, z0)
	var c001 = Vector3(x0, y0, z1)
	var c101 = Vector3(x1, y0, z1)
	var c011 = Vector3(x0, y1, z1)
	var c111 = Vector3(x1, y1, z1)
	_quad(st, c000, c100, c110, c010, Vector3(0, 0, -1))
	_quad(st, c001, c011, c111, c101, Vector3(0, 0, 1))
	_quad(st, c000, c010, c011, c001, Vector3(-1, 0, 0))
	_quad(st, c100, c101, c111, c110, Vector3(1, 0, 0))
	_quad(st, c010, c110, c111, c011, Vector3(0, 1, 0))
	_quad(st, c000, c001, c101, c100, Vector3(0, -1, 0))


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
	st.add_color(_color_actual)
	st.add_normal(na)
	st.add_vertex(a)
	st.add_color(_color_actual)
	st.add_normal(nb)
	st.add_vertex(b)
	st.add_color(_color_actual)
	st.add_normal(nc)
	st.add_vertex(c)


func _cilindro(st, base, eje, radio, largo, segs, tapa_base, tapa_punta):
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
		var p0 = base + n0 * radio
		var p1 = base + n1 * radio
		var q0 = punta + n0 * radio
		var q1 = punta + n1 * radio
		_tri(st, p0, p1, q1, n0, n1, n1)
		_tri(st, p0, q1, q0, n0, n1, n0)
		if tapa_punta:
			_tri(st, punta, q0, q1, e, e, e)
		if tapa_base:
			_tri(st, base, p1, p0, -e, -e, -e)


func _esfera(st, centro, radio, segs, anillos, media):
	var lat_max = PI * 0.5 if media else PI
	for j in range(anillos):
		var t0 = lat_max * j / anillos
		var t1 = lat_max * (j + 1) / anillos
		for i in range(segs):
			var a0 = TAU * i / segs
			var a1 = TAU * (i + 1) / segs
			var n00 = Vector3(sin(t0) * cos(a0), cos(t0), sin(t0) * sin(a0))
			var n01 = Vector3(sin(t0) * cos(a1), cos(t0), sin(t0) * sin(a1))
			var n10 = Vector3(sin(t1) * cos(a0), cos(t1), sin(t1) * sin(a0))
			var n11 = Vector3(sin(t1) * cos(a1), cos(t1), sin(t1) * sin(a1))
			if j > 0:
				_tri(st, centro + n00 * radio, centro + n01 * radio, centro + n11 * radio, n00, n01, n11)
			_tri(st, centro + n00 * radio, centro + n11 * radio, centro + n10 * radio, n00, n11, n10)
