tool
extends Spatial

# Vallas publicitarias y cocoteros por FUERA de las curvas (el lado derecho del jinete).
# Siguen la pista solos, igual que los postes de distancia y los arbustos.
# Cada curva lleva su color, y el jugador aprende a reconocerlas:
#   - ultima curva (la que entra a la recta de la meta): vino tinto con borde dorado,
#     y en su entrada siempre va la valla de "El Galope Final" (solo ahi).
#   - la otra curva: azul con borde blanco.
# Rendimiento: cada curva es UN solo dibujo con pocas partes, sin sombras, y se deja
# de dibujar sola cuando la camara no la ve. No se guarda nada dentro del .tscn.

export var trackpath_path = NodePath("../TrackPath")
export var barandas_path = NodePath("../Barandas")
export var meta_path = NodePath("../TrackPath/Meta_LLegada")

# --- Donde van ---
export var poner_en_ultima_curva = true
export var poner_en_primera_curva = true
export var distancia_desde_baranda = 22.0
export var separacion_vallas = 150.0
export var empezar_antes_de_curva = 0.0
export var terminar_despues_de_curva = 0.0
export var giro_hacia_caballos = 20.0
export var altura_suelo = -0.3
export var respetar_cajas = "Tribuna,Caballerizas,Paddock_de_Paseo"
export var margen_cajas = 6.0

# --- Valla ---
export var ancho_valla = 48.0
export var alto_valla = 12.0
export var altura_patas = 6.0
export var grosor_marco = 1.4
export var imagen_sin_sombra = true
# La valla de la entrada de la ultima curva (va solo ahi)
export(String, FILE, "*.png,*.jpg") var imagen_entrada_ultima_curva = "res://Vallas/Valla_02.png"
# Las que se van turnando en el resto de las vallas (un espacio vacio se salta)
export(String, FILE, "*.png,*.jpg") var imagen_valla_1 = "res://Vallas/Valla_01.png"
export(String, FILE, "*.png,*.jpg") var imagen_valla_2 = "res://Vallas/Valla_03.png"
export(String, FILE, "*.png,*.jpg") var imagen_valla_3 = "res://Vallas/Valla_05.png"
export(String, FILE, "*.png,*.jpg") var imagen_valla_4 = "res://Vallas/Valla_06.png"
export(String, FILE, "*.png,*.jpg") var imagen_valla_5 = "res://Vallas/Valla_04.png"
export(String, FILE, "*.png,*.jpg") var imagen_valla_6 = "res://Vallas/Valla_07.png"
export(String, FILE, "*.png,*.jpg") var imagen_valla_7 = "res://Vallas/Valla_08.png"
export(String, FILE, "*.png,*.jpg") var imagen_valla_8 = "res://Vallas/Valla_09.png"

# --- Colores de cada curva ---
export var color_marco_ultima = Color("6b1020")
export var color_borde_ultima = Color("d4af37")
export var color_marco_primera = Color("133caa")
export var color_borde_primera = Color("f2f2f2")
export var color_patas = Color("8a8a8a")
export var patas_color_de_curva = true

# --- Cocoteros ---
export var poner_cocoteros = true
export var cocoteros_entre_vallas = 2
export var fila_detras = true
export var distancia_fila_detras = 22.0
export var alto_cocotero = 30.0
export var hojas_por_cocotero = 10
export var color_tronco = Color("8d6e4f")
export var color_hoja = Color("2e7d32")
export var color_coco = Color("6b4a2b")
export var semilla = 5

# --- Rendimiento ---
export var proyectar_sombra = false

var _firma = ""
var _reloj = 0.0
var _col = Color(1, 1, 1)
var _n_img = 0


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
		s += str(b.get("offset_exterior"))
	var tp = get_node_or_null(trackpath_path)
	if tp and tp.curve:
		s += str(tp.global_transform) + str(tp.curve.get_baked_length())
	var m = get_node_or_null(meta_path)
	if m:
		s += str(m.get("offset"))
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


func _choca_con_caja(p, cajas, radio):
	for c in cajas:
		var l = c.to_local(p)
		if abs(l.x) < c.width * 0.5 + margen_cajas + radio and abs(l.z) < c.depth * 0.5 + margen_cajas + radio:
			return true
	return false


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
	var curva = tp.curva_grama if tp.get("curva_grama") else tp.curve
	var largo = curva.get_baked_length()
	if largo <= 0.0:
		return

	var off_ext = 118.0
	var b = get_node_or_null(barandas_path)
	if b and b.get("offset_exterior") != null:
		off_ext = b.offset_exterior
	var lateral_vallas = off_ext + distancia_desde_baranda

	var centro = Vector3.ZERO
	for i in range(200):
		centro += tp.to_global(curva.interpolate_baked(largo * i / 200.0))
	centro /= 200.0

	# Tramos de curva (todo lo que no es recta)
	var tramos = []
	var paso = 2.0
	var n = int(largo / paso)
	var en_curva_antes = _es_curva(curva, largo, (n - 1) * paso)
	var inicio = -1.0
	for i in range(n):
		var o = i * paso
		var c = _es_curva(curva, largo, o)
		if c and not en_curva_antes:
			inicio = o
		elif not c and en_curva_antes and inicio >= 0.0:
			tramos.append([inicio, o])
			inicio = -1.0
		en_curva_antes = c
	if inicio >= 0.0:
		# la curva cruza el cierre del circuito
		for i in range(n):
			var o2 = i * paso
			if not _es_curva(curva, largo, o2):
				tramos.append([inicio, o2 + largo])
				break
	if tramos.size() == 0:
		return

	# Cual es la ultima curva: la que termina justo antes de la meta.
	# Se busca la meta por su lugar en la grama (sirve tambien en carreras de arena).
	var meta_off = -1.0
	var m = get_node_or_null(meta_path)
	if m and m is Spatial:
		meta_off = curva.get_closest_offset(tp.to_local(m.global_transform.origin))
	var i_ultima = 0
	var mejor = INF
	for i in range(tramos.size()):
		var d = fposmod(meta_off - tramos[i][1], largo) if meta_off >= 0.0 else 0.0
		if meta_off < 0.0:
			# sin meta: la del oeste (x menor)
			d = tp.to_global(curva.interpolate_baked(fposmod((tramos[i][0] + tramos[i][1]) * 0.5, largo))).x
		if d < mejor:
			mejor = d
			i_ultima = i

	var cajas = _cajas_a_respetar()
	var imagenes = []
	for ruta in [imagen_valla_1, imagen_valla_2, imagen_valla_3, imagen_valla_4,
			imagen_valla_5, imagen_valla_6, imagen_valla_7, imagen_valla_8]:
		var t = _cargar_textura(ruta)
		if t:
			imagenes.append(t)
	var imagen_entrada = _cargar_textura(imagen_entrada_ultima_curva)
	_n_img = 0

	for i in range(tramos.size()):
		var es_ultima = (i == i_ultima)
		if es_ultima and not poner_en_ultima_curva:
			continue
		if not es_ultima and not poner_en_primera_curva:
			continue
		_vestir_curva(tp, curva, largo, centro, tramos[i], lateral_vallas, es_ultima, cajas, imagenes, imagen_entrada, i)


func _es_curva(curva, largo, o):
	var p = curva.interpolate_baked(fposmod(o, largo))
	var p2 = curva.interpolate_baked(fposmod(o + 1.0, largo))
	var dir = (p2 - p)
	dir.y = 0.0
	if dir.length() < 0.0001:
		return false
	dir = dir.normalized()
	return abs(dir.x) < 0.9997


func _cargar_textura(ruta):
	if ruta == "" or not ResourceLoader.exists(ruta):
		return null
	var t = load(ruta)
	if t is Texture:
		return t
	return null


# Punto de la orilla de afuera: posicion, direccion de carrera y "afuera"
func _punto(tp, curva, largo, centro, o, lateral):
	var p = tp.to_global(curva.interpolate_baked(fposmod(o, largo)))
	var p2 = tp.to_global(curva.interpolate_baked(fposmod(o + 1.0, largo)))
	var tang = p2 - p
	tang.y = 0.0
	tang = tang.normalized()
	var lat = Vector3(tang.z, 0, -tang.x)
	var plano = Vector3(p.x - centro.x, 0, p.z - centro.z)
	if lat.dot(plano) < 0:
		lat = -lat
	var q = p + lat * lateral
	q.y = altura_suelo
	return [q, tang, lat]


func _vestir_curva(tp, curva, largo, centro, tramo, lateral, es_ultima, cajas, imagenes, imagen_entrada, indice):
	var desde = tramo[0] - empezar_antes_de_curva
	var hasta = tramo[1] + terminar_despues_de_curva
	# Recorro la orilla de afuera midiendo el largo real ahi
	var muestras = []
	var acumulado = []
	var total = 0.0
	var o = desde
	var anterior = null
	while o <= hasta:
		var dato = _punto(tp, curva, largo, centro, o, lateral)
		if anterior != null:
			total += dato[0].distance_to(anterior)
		muestras.append(o)
		acumulado.append(total)
		anterior = dato[0]
		o += 2.0
	if total <= 1.0:
		return
	var cantidad = int(max(1, round(total / max(10.0, separacion_vallas))))
	var tramo_vallas = total / cantidad

	var s = {}
	var rng = RandomNumberGenerator.new()
	rng.seed = semilla + indice * 101
	var marco = color_marco_ultima if es_ultima else color_marco_primera
	var borde = color_borde_ultima if es_ultima else color_borde_primera
	var raiz = MeshInstance.new()
	raiz.name = "_Vestido_" + ("UltimaCurva" if es_ultima else "PrimeraCurva")
	add_child(raiz)
	# Todo se calcula en coordenadas del mundo: el dibujo va sin corrimiento.
	raiz.global_transform = Transform()

	for k in range(cantidad + 1):
		var dist = k * tramo_vallas
		var dato = _punto(tp, curva, largo, centro, _offset_en(muestras, acumulado, dist), lateral)
		var pos = dato[0]
		var tang = dato[1]
		var lat = dato[2]
		var g = deg2rad(giro_hacia_caballos)
		var normal = (-lat * cos(g) - tang * sin(g)).normalized()
		if not _choca_con_caja(pos, cajas, ancho_valla * 0.5):
			if k == 0 and es_ultima and imagen_entrada:
				_valla(s, pos, normal, marco, borde, imagen_entrada)
			elif imagenes.size() > 0:
				_valla(s, pos, normal, marco, borde, imagenes[_n_img % imagenes.size()])
				_n_img += 1
			else:
				_valla(s, pos, normal, marco, borde, null)
		# Cocoteros entre esta valla y la siguiente
		if poner_cocoteros and k < cantidad:
			for j in range(cocoteros_entre_vallas):
				var dj = dist + tramo_vallas * float(j + 1) / float(cocoteros_entre_vallas + 1)
				var dp = _punto(tp, curva, largo, centro, _offset_en(muestras, acumulado, dj), lateral - 4.0)
				if not _choca_con_caja(dp[0], cajas, 4.0):
					_cocotero(s, dp[0], alto_cocotero * rng.randf_range(0.85, 1.1), rng)
			if fila_detras:
				var dd = dist + tramo_vallas * 0.5
				var dp2 = _punto(tp, curva, largo, centro, _offset_en(muestras, acumulado, dd), lateral + distancia_fila_detras)
				if not _choca_con_caja(dp2[0], cajas, 4.0):
					_cocotero(s, dp2[0], alto_cocotero * rng.randf_range(1.0, 1.25), rng)

	var mesh = ArrayMesh.new()
	var mats = _materiales()
	for clave in s.keys():
		var st = s[clave]
		var antes = mesh.get_surface_count()
		st.commit(mesh)
		if mesh.get_surface_count() > antes:
			if typeof(clave) == TYPE_STRING:
				mesh.surface_set_material(antes, mats[clave])
			else:
				mesh.surface_set_material(antes, _mat_imagen(clave))
	raiz.mesh = mesh
	raiz.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_ON if proyectar_sombra else GeometryInstance.SHADOW_CASTING_SETTING_OFF


func _offset_en(muestras, acumulado, dist):
	for i in range(1, acumulado.size()):
		if acumulado[i] >= dist:
			var a = acumulado[i - 1]
			var t = 0.0 if acumulado[i] - a < 0.0001 else (dist - a) / (acumulado[i] - a)
			return lerp(muestras[i - 1], muestras[i], t)
	return muestras[muestras.size() - 1]


# ---------- Valla ----------

func _valla(s, base, normal, marco, borde, textura):
	var arriba = Vector3.UP
	var der = (-normal).cross(arriba).normalized()
	var bas = Basis(der, arriba, normal)
	var cy = altura_patas + alto_valla * 0.5
	var centro = base + arriba * cy
	var st = _st(s, "solido")
	# Patas (por detras del panel, del color de la curva)
	_col = marco if patas_color_de_curva else color_patas
	var alto_pata = cy + alto_valla * 0.3
	for lado in [-0.32, 0.32]:
		var pb = base + der * ancho_valla * lado - normal * 0.95
		_caja_orientada(st, pb + arriba * (alto_pata * 0.5), Vector3(0.5, alto_pata * 0.5, 0.5), bas)
	# Panel (marco)
	_col = marco
	var g = grosor_marco
	_caja_orientada(st, centro, Vector3(ancho_valla * 0.5 + g, alto_valla * 0.5 + g, 0.4), bas)
	# Borde fino de color, por delante
	_col = borde
	var fr = centro + normal * 0.42
	var bw = g * 0.45
	_caja_orientada(st, fr + arriba * (alto_valla * 0.5 + bw), Vector3(ancho_valla * 0.5 + bw * 2.0, bw, 0.05), bas)
	_caja_orientada(st, fr - arriba * (alto_valla * 0.5 + bw), Vector3(ancho_valla * 0.5 + bw * 2.0, bw, 0.05), bas)
	_caja_orientada(st, fr + der * (ancho_valla * 0.5 + bw), Vector3(bw, alto_valla * 0.5, 0.05), bas)
	_caja_orientada(st, fr - der * (ancho_valla * 0.5 + bw), Vector3(bw, alto_valla * 0.5, 0.05), bas)
	# Imagen
	if textura:
		var sti = _st(s, textura)
		var c = centro + normal * 0.45
		var hx = der * ancho_valla * 0.5
		var hy = arriba * alto_valla * 0.5
		_col = Color(1, 1, 1)
		_quad_uv(sti, [c - hx + hy, c + hx + hy, c + hx - hy, c - hx - hy],
			[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)], normal)


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
	var nh = hojas_por_cocotero
	for h in range(nh):
		var a = TAU * h / nh + rng.randf_range(-0.15, 0.15)
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
	var hoja = SpatialMaterial.new()
	hoja.albedo_color = color_hoja
	hoja.albedo_texture = _textura_hoja()
	hoja.params_use_alpha_scissor = true
	hoja.params_alpha_scissor_threshold = 0.3
	hoja.params_cull_mode = SpatialMaterial.CULL_DISABLED
	m["hoja"] = hoja
	return m


func _mat_imagen(tex):
	var m = SpatialMaterial.new()
	m.albedo_texture = tex
	m.flags_unshaded = imagen_sin_sombra
	return m


func _textura_hoja():
	var ancho = 64
	var alto = 256
	var img = Image.new()
	img.create(ancho, alto, true, Image.FORMAT_RGBA8)
	img.lock()
	var p = 6.0
	for y in range(alto):
		for x in range(ancho):
			var dx = abs(x - ancho * 0.5 + 0.5)
			var c = Color(0, 0, 0, 0)
			if dx < 1.6:
				c = Color(0.78, 0.82, 0.55, 1.0)
			else:
				var fase = fmod(y - dx * 0.55 + p * 10.0, p)
				var grueso = lerp(4.6, 3.0, dx / (ancho * 0.5))
				if fase < grueso and dx < ancho * 0.5 - 1.0:
					var tono = 1.0 - 0.25 * (dx / (ancho * 0.5))
					c = Color(tono, tono, tono * 0.92, 1.0)
			img.set_pixel(x, y, c)
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
