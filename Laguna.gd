tool
extends Spatial

# Laguna azul con fuente y cocoteros. Solo construye el dibujo alrededor de su
# propio centro: la laguna se ubica y se gira a mano en el editor (Translation y
# Rotation del nodo), igual que las tribunas. No se guarda nada dentro del .tscn.
# Rendimiento: 3 dibujos en total, sin transparencias y sin sombras.

# --- Forma del agua ---
export var radio_largo = 62.0
export var radio_corto = 44.0
export var irregularidad = 0.10
export var puntos_borde = 48
export var altura_agua = -0.15
export var color_agua_centro = Color("0b4f8a")
export var color_agua_orilla = Color("2fa6d9")
export var brillo_agua = 0.25
export var aspereza_agua = 0.12

# --- Orilla de piedra ---
export var ancho_orilla = 2.5
export var alto_orilla = 0.45
export var color_orilla = Color("e8dcc0")

# --- Fuente en el centro ---
export var poner_fuente = true
export var alto_chorro = 16.0
export var ancho_chorro = 0.9
export var ancho_corona = 5.5
export var color_chorro = Color("e8f7ff")
export var color_pedestal = Color("efe9dc")

# --- Cocoteros alrededor ---
export var poner_cocoteros = true
export var cantidad_cocoteros = 10
export var distancia_cocoteros = 7.0
export var alto_cocotero = 26.0
export var hojas_por_cocotero = 10
export var color_tronco = Color("8d6e4f")
export var color_hoja = Color("2e7d32")
export var color_coco = Color("6b4a2b")
export var semilla = 3

export var proyectar_sombra = false

var _firma = ""
var _reloj = 0.0
var _col = Color(1, 1, 1)


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
	return s


func _reconstruir():
	if not is_inside_tree():
		return
	_firma = _calcular_firma()
	for h in get_children():
		if h.name.begins_with("_Vestido"):
			remove_child(h)
			h.queue_free()

	var rng = RandomNumberGenerator.new()
	rng.seed = semilla
	# Borde irregular (que no parezca un ovalo perfecto)
	var fases = [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
	var n = int(max(12, puntos_borde))
	var borde = []
	for i in range(n):
		var a = TAU * i / n
		var k = 1.0 + irregularidad * (0.6 * sin(2.0 * a + fases[0]) + 0.3 * sin(3.0 * a + fases[1]) + 0.2 * sin(5.0 * a + fases[2]))
		borde.append(Vector3(cos(a) * radio_largo * k, 0, sin(a) * radio_corto * k))

	var s = {}
	var y = altura_agua
	var centro = Vector3(0, y, 0)

	# Agua: centro oscuro (hondo) y orilla clara (bajito)
	var sta = _st(s, "agua")
	for i in range(n):
		var p0 = borde[i]
		var p1 = borde[(i + 1) % n]
		var m0 = Vector3(p0.x * 0.55, y, p0.z * 0.55)
		var m1 = Vector3(p1.x * 0.55, y, p1.z * 0.55)
		var e0 = Vector3(p0.x, y, p0.z)
		var e1 = Vector3(p1.x, y, p1.z)
		_tri_col(sta, centro, m0, m1, color_agua_centro, color_agua_centro, color_agua_centro)
		_tri_col(sta, m0, e0, e1, color_agua_centro, color_agua_orilla, color_agua_orilla)
		_tri_col(sta, m0, e1, m1, color_agua_centro, color_agua_orilla, color_agua_centro)

	# Orilla de piedra
	var st = _st(s, "solido")
	_col = color_orilla
	var arriba = alto_orilla
	for i in range(n):
		var p0 = borde[i]
		var p1 = borde[(i + 1) % n]
		var d0 = Vector3(p0.x, 0, p0.z).normalized()
		var d1 = Vector3(p1.x, 0, p1.z).normalized()
		var i0 = Vector3(p0.x, arriba, p0.z)
		var i1 = Vector3(p1.x, arriba, p1.z)
		var o0 = i0 + d0 * ancho_orilla
		var o1 = i1 + d1 * ancho_orilla
		_quad(st, i0, i1, o1, o0, Vector3.UP)
		# pared hacia el agua y pared hacia afuera
		_quad(st, Vector3(p0.x, y, p0.z), Vector3(p1.x, y, p1.z), i1, i0, -d0)
		_quad(st, o0, o1, Vector3(o1.x, -0.4, o1.z), Vector3(o0.x, -0.4, o0.z), d0)

	# Fuente
	if poner_fuente:
		_col = color_pedestal
		_cono(st, Vector3(0, y - 0.1, 0), Vector3.UP, 2.6, 2.2, 1.1, 16, false, true)
		_cono(st, Vector3(0, y + 1.0, 0), Vector3.UP, 1.0, 0.8, 1.2, 12, false, true)
		_col = color_chorro
		var base_chorro = Vector3(0, y + 2.2, 0)
		_cono(st, base_chorro, Vector3.UP, ancho_chorro, ancho_chorro * 0.35, alto_chorro, 10, false, false)
		var tope = base_chorro + Vector3(0, alto_chorro, 0)
		# corona que cae como paraguas
		_cono(st, tope, Vector3.DOWN, ancho_chorro * 0.35, ancho_corona, alto_chorro * 0.35, 14, false, false)
		_cono(st, tope + Vector3(0, -alto_chorro * 0.35, 0), Vector3.DOWN, ancho_corona, ancho_corona * 1.15, alto_chorro * 0.12, 14, false, false)

	# Cocoteros alrededor
	if poner_cocoteros and cantidad_cocoteros > 0:
		for c in range(cantidad_cocoteros):
			var a = TAU * c / cantidad_cocoteros + rng.randf_range(-0.25, 0.25)
			var k = 1.0 + irregularidad * (0.6 * sin(2.0 * a + fases[0]) + 0.3 * sin(3.0 * a + fases[1]) + 0.2 * sin(5.0 * a + fases[2]))
			var rx = radio_largo * k + ancho_orilla + distancia_cocoteros * rng.randf_range(0.8, 1.3)
			var rz = radio_corto * k + ancho_orilla + distancia_cocoteros * rng.randf_range(0.8, 1.3)
			_cocotero(s, Vector3(cos(a) * rx, -0.3, sin(a) * rz), alto_cocotero * rng.randf_range(0.85, 1.15), rng)

	var mesh = ArrayMesh.new()
	var mats = _materiales()
	for clave in s.keys():
		var antes = mesh.get_surface_count()
		s[clave].commit(mesh)
		if mesh.get_surface_count() > antes:
			mesh.surface_set_material(antes, mats[clave])
	var mi = MeshInstance.new()
	mi.name = "_Vestido_Laguna"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_ON if proyectar_sombra else GeometryInstance.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


# ---------- Cocotero ----------

func _cocotero(s, base, alto, rng):
	var k = alto / 12.0
	var inclina = Vector3(rng.randf_range(-1.0, 1.0), 0, rng.randf_range(-1.0, 1.0)).normalized() * alto * 0.12
	var tramos = 6
	var prev = base
	var st = _st(s, "solido")
	for i in range(tramos):
		var t = float(i + 1) / tramos
		var p = base + Vector3(0, alto * t, 0) + inclina * t * t
		var r0 = lerp(0.6, 0.32, float(i) / tramos) * k
		var r1 = lerp(0.6, 0.32, t) * k
		_col = color_tronco if i % 2 == 0 else color_tronco.darkened(0.12)
		_cono(st, prev, p - prev, r0, r1, (p - prev).length(), 6, false, i == tramos - 1)
		prev = p
	_col = color_coco
	for c in range(3):
		var ac = TAU * c / 3.0 + rng.randf_range(0.0, 1.0)
		_esfera(st, prev + Vector3(cos(ac) * 0.45, -0.55, sin(ac) * 0.45) * k, 0.32 * k, 5, 3)
	_col = Color(1, 1, 1)
	var sth = _st(s, "hoja")
	for h in range(hojas_por_cocotero):
		var a = TAU * h / hojas_por_cocotero + rng.randf_range(-0.15, 0.15)
		var dir = Vector3(cos(a), 0, sin(a))
		var lado = Vector3(-dir.z, 0, dir.x)
		var largo = alto * rng.randf_range(0.36, 0.46)
		var sube = rng.randf_range(0.15, 0.45)
		var segs = 4
		var puntos = []
		for j in range(segs + 1):
			var u = float(j) / segs
			puntos.append(prev + dir * largo * u + Vector3(0, largo * (sube * u - (sube + 0.6) * u * u), 0))
		for j in range(segs):
			var u0 = float(j) / segs
			var u1 = float(j + 1) / segs
			var w0 = largo * 0.2 * sin(PI * lerp(0.18, 1.0, u0))
			var w1 = largo * 0.2 * sin(PI * lerp(0.18, 1.0, u1))
			var a0 = puntos[j]
			var a1 = puntos[j + 1]
			var caida0 = Vector3(0, -w0 * 0.35, 0)
			var caida1 = Vector3(0, -w1 * 0.35, 0)
			var arr = (a1 - a0).cross(lado).normalized()
			if arr.y < 0:
				arr = -arr
			_quad_uv(sth, [a0, a1, a1 + lado * w1 + caida1, a0 + lado * w0 + caida0],
				[Vector2(0.5, u0), Vector2(0.5, u1), Vector2(1.0, u1), Vector2(1.0, u0)], arr)
			_quad_uv(sth, [a0, a1, a1 - lado * w1 + caida1, a0 - lado * w0 + caida0],
				[Vector2(0.5, u0), Vector2(0.5, u1), Vector2(0.0, u1), Vector2(0.0, u0)], arr)


# ---------- Materiales ----------

func _materiales():
	var m = {}
	var solido = SpatialMaterial.new()
	solido.vertex_color_use_as_albedo = true
	solido.vertex_color_is_srgb = true
	m["solido"] = solido
	var agua = SpatialMaterial.new()
	agua.vertex_color_use_as_albedo = true
	agua.vertex_color_is_srgb = true
	agua.metallic = brillo_agua
	agua.roughness = aspereza_agua
	m["agua"] = agua
	var hoja = SpatialMaterial.new()
	hoja.albedo_color = color_hoja
	hoja.albedo_texture = _textura_hoja()
	hoja.params_use_alpha_scissor = true
	hoja.params_alpha_scissor_threshold = 0.3
	hoja.params_cull_mode = SpatialMaterial.CULL_DISABLED
	m["hoja"] = hoja
	return m


func _textura_hoja():
	var ancho = 64
	var alto = 256
	var img = Image.new()
	img.create(ancho, alto, true, Image.FORMAT_RGBA8)
	img.lock()
	var p = 6.0
	for yy in range(alto):
		for x in range(ancho):
			var dx = abs(x - ancho * 0.5 + 0.5)
			var c = Color(0, 0, 0, 0)
			if dx < 1.6:
				c = Color(0.78, 0.82, 0.55, 1.0)
			else:
				var fase = fmod(yy - dx * 0.55 + p * 10.0, p)
				var grueso = lerp(4.6, 3.0, dx / (ancho * 0.5))
				if fase < grueso and dx < ancho * 0.5 - 1.0:
					var tono = 1.0 - 0.25 * (dx / (ancho * 0.5))
					c = Color(tono, tono, tono * 0.92, 1.0)
			img.set_pixel(x, yy, c)
	img.unlock()
	img.generate_mipmaps()
	var tex = ImageTexture.new()
	tex.create_from_image(img, Texture.FLAG_MIPMAPS | Texture.FLAG_FILTER)
	return tex


# ---------- Geometria ----------

func _st(s, clave):
	if not s.has(clave):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		s[clave] = st
	return s[clave]


func _tri_col(st, a, b, c, ca, cb, cc):
	var n = Vector3.UP
	if (b - a).cross(c - a).dot(n) > 0:
		var t = b
		b = c
		c = t
		var tc = cb
		cb = cc
		cc = tc
	st.add_color(ca)
	st.add_normal(n)
	st.add_vertex(a)
	st.add_color(cb)
	st.add_normal(n)
	st.add_vertex(b)
	st.add_color(cc)
	st.add_normal(n)
	st.add_vertex(c)


func _quad_uv(st, p, uv, n):
	var orden = [0, 1, 2, 0, 2, 3]
	if (p[1] - p[0]).cross(p[2] - p[0]).dot(n) > 0:
		orden = [0, 2, 1, 0, 3, 2]
	for i in orden:
		st.add_color(_col)
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
	st.add_color(_col)
	st.add_normal(na)
	st.add_vertex(a)
	st.add_color(_col)
	st.add_normal(nb)
	st.add_vertex(b)
	st.add_color(_col)
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
	for j in range(anillos):
		var t0 = PI * j / anillos
		var t1 = PI * (j + 1) / anillos
		for i in range(segs):
			var a0 = TAU * i / segs
			var a1 = TAU * (i + 1) / segs
			var u00 = Vector3(sin(t0) * cos(a0), cos(t0), sin(t0) * sin(a0))
			var u01 = Vector3(sin(t0) * cos(a1), cos(t0), sin(t0) * sin(a1))
			var u10 = Vector3(sin(t1) * cos(a0), cos(t1), sin(t1) * sin(a0))
			var u11 = Vector3(sin(t1) * cos(a1), cos(t1), sin(t1) * sin(a1))
			if j > 0:
				_tri(st, centro + u00 * radio, centro + u01 * radio, centro + u11 * radio, u00, u01, u11)
			if j < anillos - 1:
				_tri(st, centro + u00 * radio, centro + u11 * radio, centro + u10 * radio, u00, u11, u10)
