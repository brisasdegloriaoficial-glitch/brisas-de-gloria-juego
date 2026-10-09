tool
extends Spatial

# Jardines.gd — Viste la caja CSGBox cuyo nombre empiece con "Prefijo Cajas" (el jardin central).
# NO mueve nada: toma posicion, giro y medidas de la caja que tu ubicas a mano.
# Deja libre el espacio de la caja "Caja Libre" (el paddock de vencedores) y lo rodea con un sendero.

export var prefijo_cajas = "Jardin"
export var caja_libre = "Paddock_de_Vencedores"
export var margen_libre = 6.0
export var ocultar_cajas = true
export var sin_sombreado = false
export var semilla = 7

# --- Cesped y bordes ---
export var altura_cesped = 0.5
export var ancho_franja_cesped = 12.0
export var poner_bordes = true
export var ancho_bordillo = 1.2
export var alto_bordillo = 0.4
export var ancho_seto = 1.6
export var alto_seto = 1.4

# --- Senderos ---
export var poner_senderos = true
export var ancho_sendero = 7.0
export var radio_plaza = 24.0

# --- Fuente con estatua de caballo ---
export var poner_fuente = true
export var fuente_x = -140.0
export var radio_fuente = 14.0
export var alto_borde_fuente = 1.2
export var altura_pedestal = 5.0
export var radio_taza = 7.5
export var escala_estatua = 5.0
export var giro_estatua = 30.0
# NUEVO - Monumento con el logo BDG (una moneda grande de pie sobre la fuente).
# Desmarcar = vuelve el caballo de antes.
export var monumento_logo = true
# Radio de la moneda del monumento.
export var tamano_monumento = 5.0
# Grosor del canto dorado de la moneda.
export var grosor_monumento = 0.8

# --- Laguna (espejo de agua) ---
export var poner_laguna = true
export var laguna_x = 140.0
export var radio_laguna_largo = 34.0
export var radio_laguna_corto = 20.0
export var ancho_borde_laguna = 1.5

# --- Palmeras, arboles y macizos de flores ---
export var poner_palmeras = true
export var separacion_palmeras = 18.0
export var alto_palmera = 12.0
export var poner_arboles = true
export var separacion_arboles = 20.0
export var tamano_arbol = 1.0
export var poner_macizos = true
export var radio_macizo = 4.0
export var separacion_macizos = 24.0
export var densidad_flores = 1.0
export var colores_flores = "c62828,f9a825,fafafa,8e24aa"

# --- Logo BDG grabado en el cesped ---
export var poner_logo = true
export var ruta_logo = "res://Caballos/Logo_Moneda_BDG_transparente.png"
export var logo_x = 0.0
export var logo_z = -45.0
export var tamano_logo = 50.0
export var giro_logo = 0.0
export var poner_aro_logo = true
export var color_aro_logo = Color("d4af37")
# NUEVO - Inclina el logo sobre un talud de cesped, de frente a la recta
# de la meta, para que se lea desde la pista. 0 = plano como antes.
export var inclinar_logo = 20.0
# NUEVO - Brillo del logo BDG (cesped y monumento). 1 = como la imagen,
# mas alto = mas luminoso (1.3 recomendado).
export var brillo_logo = 1.3

# --- Colores ---
export var color_cesped_a = Color("4f8a3a")
export var color_cesped_b = Color("5a9944")
export var color_bordillo = Color("e8e2d0")
export var color_seto = Color("2f5d2a")
export var color_sendero = Color("d8c7a3")
export var color_plaza = Color("e8dcc0")
export var color_piedra = Color("efe9dc")
export var color_agua = Color("3b8fc4")
export var opacidad_agua = 0.85
export var color_estatua = Color("b08d57")
export var metal_estatua = 0.6
export var aspereza_estatua = 0.35
export var color_tronco_palma = Color("8d6e4f")
export var color_hoja_palma = Color("2e7d32")
# NUEVO - palmeras mejoradas
export var color_coco = Color("6b4a2b")
export var hojas_por_palmera = 12
export var curva_tronco_palma = 0.10
export var color_tronco_arbol = Color("6d4c41")
export var color_copa_a = Color("3f7f3a")
export var color_copa_b = Color("4c8c3f")
export var color_tierra = Color("5d4037")

var _firma = ""
var _reloj = 0.0
var _ocupados = []


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


func _caja_libre():
	var padre = get_parent()
	if padre == null or caja_libre.strip_edges() == "":
		return null
	var n = padre.get_node_or_null(caja_libre)
	if n is CSGBox:
		return n
	return null


func _calcular_firma():
	var s = ""
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_EDITOR:
			s += str(get(p.name))
	for c in _cajas():
		s += c.name + str(c.global_transform) + str(c.width) + str(c.depth)
	var l = _caja_libre()
	if l != null:
		s += str(l.global_transform) + str(l.width) + str(l.depth)
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
	var libre_caja = _caja_libre()
	for caja in _cajas():
		caja.visible = not ocultar_cajas
		var t = caja.global_transform
		var esc = t.basis.get_scale()
		t.basis = t.basis.orthonormalized()
		var raiz = Spatial.new()
		raiz.name = "_Vestido_" + caja.name
		add_child(raiz)
		raiz.transform = global_transform.affine_inverse() * t
		var libre = null
		if libre_caja != null:
			libre = _rect_local(libre_caja, t)
		_construir(raiz, caja.width * esc.x, caja.depth * esc.z, libre, mats)


# Rectangulo [x0, x1, z0, z1] que ocupa la caja libre, medido dentro del jardin
func _rect_local(caja, t_jardin):
	var inv = t_jardin.affine_inverse()
	var g = caja.global_transform
	var hx = caja.width * 0.5
	var hz = caja.depth * 0.5
	var r = [INF, -INF, INF, -INF]
	for v in [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(-hx, 0, hz), Vector3(hx, 0, hz)]:
		var p = inv.xform(g.xform(v))
		r[0] = min(r[0], p.x)
		r[1] = max(r[1], p.x)
		r[2] = min(r[2], p.z)
		r[3] = max(r[3], p.z)
	r[0] -= margen_libre
	r[1] += margen_libre
	r[2] -= margen_libre
	r[3] += margen_libre
	return r


func _construir(raiz, W, D, libre, mats):
	var s = {}
	_ocupados = []
	var rng = RandomNumberGenerator.new()
	rng.seed = semilla
	var mx = W * 0.5
	var mz = D * 0.5
	var yc = altura_cesped
	var w = ancho_sendero
	var hw = w * 0.5
	var borde = (ancho_bordillo + ancho_seto) if poner_bordes else 0.0
	var eje = 0.0
	if libre != null:
		eje = (libre[2] + libre[3]) * 0.5
	var hay_fuente = poner_fuente
	var hay_laguna = poner_laguna and radio_laguna_largo > ancho_borde_laguna + 1.0 and radio_laguna_corto > ancho_borde_laguna + 1.0
	var transversales = []
	if hay_fuente:
		transversales.append(fuente_x)
	if hay_laguna:
		transversales.append(laguna_x)

	# 1. Cesped en franjas de corte
	var nf = int(max(1, round(W / ancho_franja_cesped)))
	var af = W / nf
	for i in range(nf):
		var clave = "cesped_a" if i % 2 == 0 else "cesped_b"
		_caja(_st(s, clave), Vector3(-mx + i * af, 0, -mz), Vector3(-mx + (i + 1) * af, yc, mz))

	# 2. Bordillo de piedra y seto, con aberturas donde salen los senderos
	if poner_bordes:
		var cortes_largos = []
		var cortes_cortos = []
		if poner_senderos:
			for x in transversales:
				cortes_largos.append([x, hw + 0.5])
			cortes_cortos.append([eje, hw + 0.5])
		var b = ancho_bordillo
		var yb = yc + alto_bordillo
		for tr in _tramos(-mx - 0.05, mx + 0.05, cortes_largos):
			_caja(_st(s, "bordillo"), Vector3(tr[0], 0, -mz - 0.05), Vector3(tr[1], yb, -mz + b))
			_caja(_st(s, "bordillo"), Vector3(tr[0], 0, mz - b), Vector3(tr[1], yb, mz + 0.05))
		for tr in _tramos(-mz + b, mz - b, cortes_cortos):
			_caja(_st(s, "bordillo"), Vector3(-mx - 0.05, 0, tr[0]), Vector3(-mx + b, yb, tr[1]))
			_caja(_st(s, "bordillo"), Vector3(mx - b, 0, tr[0]), Vector3(mx + 0.05, yb, tr[1]))
		var ys = yc + alto_seto
		var e = ancho_seto
		for tr in _tramos(-mx + b, mx - b, cortes_largos):
			_caja(_st(s, "seto"), Vector3(tr[0], yc, -mz + b), Vector3(tr[1], ys, -mz + b + e))
			_caja(_st(s, "seto"), Vector3(tr[0], yc, mz - b - e), Vector3(tr[1], ys, mz - b))
		for tr in _tramos(-mz + b + e, mz - b - e, cortes_cortos):
			_caja(_st(s, "seto"), Vector3(-mx + b, yc, tr[0]), Vector3(-mx + b + e, ys, tr[1]))
			_caja(_st(s, "seto"), Vector3(mx - b - e, yc, tr[0]), Vector3(mx - b, ys, tr[1]))

	# 3. Senderos: eje largo, transversales, anillo alrededor del paddock y plaza de la fuente
	var ysd = yc + 0.15
	if poner_senderos:
		var cortes_eje = []
		if libre != null:
			cortes_eje.append([(libre[0] + libre[1]) * 0.5, (libre[1] - libre[0]) * 0.5 + w])
		if hay_fuente:
			cortes_eje.append([fuente_x, radio_plaza - 1.0])
		if hay_laguna:
			cortes_eje.append([laguna_x, radio_laguna_largo - 1.0])
		for tr in _tramos(-mx + borde - 0.5, mx - borde + 0.5, cortes_eje):
			_caja(_st(s, "sendero"), Vector3(tr[0], yc, eje - hw), Vector3(tr[1], ysd, eje + hw))
		if hay_fuente:
			for tr in _tramos(-mz + borde - 0.5, mz - borde + 0.5, [[eje, radio_plaza - 1.0]]):
				_caja(_st(s, "sendero"), Vector3(fuente_x - hw, yc, tr[0]), Vector3(fuente_x + hw, ysd, tr[1]))
		if hay_laguna:
			for tr in _tramos(-mz + borde - 0.5, mz - borde + 0.5, [[eje, radio_laguna_corto - 1.0]]):
				_caja(_st(s, "sendero"), Vector3(laguna_x - hw, yc, tr[0]), Vector3(laguna_x + hw, ysd, tr[1]))
		if libre != null:
			var x0 = libre[0]
			var x1 = libre[1]
			var z0 = libre[2]
			var z1 = libre[3]
			_caja(_st(s, "sendero"), Vector3(x0 - w, yc, z0 - w), Vector3(x1 + w, ysd, z0))
			_caja(_st(s, "sendero"), Vector3(x0 - w, yc, z1), Vector3(x1 + w, ysd, z1 + w))
			_caja(_st(s, "sendero"), Vector3(x0 - w, yc, z0), Vector3(x0, ysd, z1))
			_caja(_st(s, "sendero"), Vector3(x1, yc, z0), Vector3(x1 + w, ysd, z1))
		if hay_fuente:
			_cono(_st(s, "plaza"), Vector3(fuente_x, yc, eje), Vector3.UP, radio_plaza, radio_plaza, 0.25, 40, false, true)

	# 4. Fuente central con estatua de caballo
	if hay_fuente:
		var yp = yc + 0.25
		var cf = Vector3(fuente_x, yp, eje)
		var r_in = max(1.0, radio_fuente - 1.0)
		_anillo(_st(s, "piedra"), cf, radio_fuente, radio_fuente, radio_fuente - r_in, alto_borde_fuente, 40)
		_disco(_st(s, "agua"), cf + Vector3(0, alto_borde_fuente * 0.75, 0), r_in, r_in, 40)
		_cono(_st(s, "piedra"), cf, Vector3.UP, 2.2, 1.6, altura_pedestal, 16, false, false)
		var yt = yp + altura_pedestal
		_cono(_st(s, "piedra"), Vector3(fuente_x, yt, eje), Vector3.UP, radio_taza * 0.6, radio_taza, 0.3, 32, true, true)
		_anillo(_st(s, "piedra"), Vector3(fuente_x, yt + 0.3, eje), radio_taza, radio_taza, 0.6, 0.7, 32)
		_disco(_st(s, "agua"), Vector3(fuente_x, yt + 0.8, eje), radio_taza - 0.6, radio_taza - 0.6, 32)
		var giro = Basis(Vector3.UP, deg2rad(giro_estatua))
		var ep = escala_estatua
		var alto_plinto = 0.45 * ep
		_caja_orientada(_st(s, "piedra"), Vector3(fuente_x, yt + 0.3 + alto_plinto * 0.5, eje), Vector3(1.05 * ep, alto_plinto * 0.5, 0.4 * ep), giro)
		var base_estatua = Vector3(fuente_x, yt + 0.3 + alto_plinto, eje)
		# NUEVO - en vez del caballo, el logo BDG como una moneda grande de pie.
		if monumento_logo and mats.has("logo_monumento"):
			_monumento_logo(s, base_estatua, giro, tamano_monumento)
		else:
			_caballo(_st(s, "estatua"), base_estatua, ep, giro)
		_ocupados.append([Vector2(fuente_x, eje), radio_plaza])

	# 5. Laguna o espejo de agua
	if hay_laguna:
		var cl = Vector3(laguna_x, yc, eje)
		_anillo(_st(s, "piedra"), cl, radio_laguna_largo, radio_laguna_corto, ancho_borde_laguna, 0.8, 48)
		_disco(_st(s, "agua"), cl + Vector3(0, 0.55, 0), radio_laguna_largo - ancho_borde_laguna, radio_laguna_corto - ancho_borde_laguna, 48)

	# 5b. Logo BDG grabado en el cesped (arriba de la imagen = hacia -Z, como lo ve la camara aerea)
	if poner_logo and inclinar_logo > 0.0:
		_logo_inclinado(s, mats, yc)
	elif poner_logo:
		var h = tamano_logo * 0.5
		if mats.has("logo"):
			var cg = Vector3(logo_x, yc + 0.2, logo_z)
			var gb = Basis(Vector3.UP, deg2rad(giro_logo))
			var pts = [cg + gb.xform(Vector3(-h, 0, -h)), cg + gb.xform(Vector3(h, 0, -h)), cg + gb.xform(Vector3(h, 0, h)), cg + gb.xform(Vector3(-h, 0, h))]
			var uvs = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
			_quad_uv(_st(s, "logo"), pts, uvs, Vector3.UP)
		if poner_aro_logo:
			_anillo(_st(s, "aro_logo"), Vector3(logo_x, yc, logo_z), h + 1.5, h + 1.5, 1.2, 0.35, 64)
		_ocupados.append([Vector2(logo_x, logo_z), h + 3.0])

	var limites = [mx - borde, mz - borde, libre, eje, transversales, hay_fuente, hay_laguna]

	# 6. Macizos de flores: alrededor de la plaza y a los lados de los senderos transversales
	if poner_macizos:
		var lista = colores_flores.split(",", false)
		var rm = radio_macizo
		var puntos = []
		if hay_fuente:
			for k in range(4):
				var a = PI * 0.25 + PI * 0.5 * k
				var d = radio_plaza + rm + 2.5
				puntos.append(Vector2(fuente_x + cos(a) * d, eje + sin(a) * d))
		for x in transversales:
			var inicio = (radio_plaza + rm * 3.0) if (x == fuente_x and hay_fuente) else (radio_laguna_corto + rm + 3.0)
			for lado in [-1, 1]:
				var dz = inicio
				while dz < mz:
					for lx in [-1, 1]:
						puntos.append(Vector2(x + lx * (hw + 1.5 + rm), eje + lado * dz))
					dz += separacion_macizos
		for p in puntos:
			if _libre(p, rm, limites):
				_macizo(s, p, rm, yc, rng, lista)
				_ocupados.append([p, rm])

	# 7. Palmeras: alameda a los lados del eje y en las esquinas del paddock
	if poner_palmeras:
		var puntos_p = []
		var off = hw + 3.0
		var x = -mx + borde + 4.0
		while x < mx - borde - 4.0:
			puntos_p.append(Vector2(x, eje - off))
			puntos_p.append(Vector2(x, eje + off))
			x += separacion_palmeras
		if libre != null:
			var g = w + 4.0
			for q in [Vector2(libre[0] - g, libre[2] - g), Vector2(libre[1] + g, libre[2] - g), Vector2(libre[0] - g, libre[3] + g), Vector2(libre[1] + g, libre[3] + g)]:
				puntos_p.append(q)
		for p in puntos_p:
			if _libre(p, 1.5, limites):
				_palmera(s, Vector3(p.x, yc, p.y), alto_palmera * rng.randf_range(0.9, 1.1), rng)
				_ocupados.append([p, 2.5])

	# 8. Arboles de copa redonda a lo largo del borde
	if poner_arboles:
		var ra = 3.4 * tamano_arbol
		var ix = mx - borde - ra - 1.0
		var iz = mz - borde - ra - 1.0
		var puntos_a = []
		var x = -ix
		while x <= ix:
			puntos_a.append(Vector2(x, -iz))
			puntos_a.append(Vector2(x, iz))
			x += separacion_arboles
		var z = -iz + separacion_arboles
		while z < iz:
			puntos_a.append(Vector2(-ix, z))
			puntos_a.append(Vector2(ix, z))
			z += separacion_arboles
		var alterna = 0
		for p in puntos_a:
			if _libre(p, ra * 0.5, limites):
				var clave = "copa_a" if alterna % 2 == 0 else "copa_b"
				alterna += 1
			_palmera(s, Vector3(p.x, yc, p.y), alto_palmera * rng.randf_range(0.9, 1.1), rng)
			

	for clave in s.keys():
		if not mats.has(clave):
			continue
		var mi = MeshInstance.new()
		mi.name = clave
		mi.mesh = s[clave].commit()
		mi.material_override = mats[clave]
		raiz.add_child(mi)


# Revisa si un punto (x, z) con radio r cae en un lugar libre del jardin
func _libre(p, r, lim):
	var mx = lim[0]
	var mz = lim[1]
	var libre = lim[2]
	var eje = lim[3]
	var hw = ancho_sendero * 0.5
	if abs(p.x) > mx - r or abs(p.y) > mz - r:
		return false
	if libre != null:
		var g = r + (ancho_sendero if poner_senderos else 0.0)
		if p.x > libre[0] - g and p.x < libre[1] + g and p.y > libre[2] - g and p.y < libre[3] + g:
			return false
	if poner_senderos:
		if abs(p.y - eje) < hw + r:
			return false
		for x in lim[4]:
			if abs(p.x - x) < hw + r:
				return false
	if lim[5] and Vector2(fuente_x, eje).distance_to(p) < radio_plaza + r:
		return false
	if lim[6]:
		var ex = (p.x - laguna_x) / (radio_laguna_largo + r + 2.0)
		var ez = (p.y - eje) / (radio_laguna_corto + r + 2.0)
		if ex * ex + ez * ez < 1.0:
			return false
	for o in _ocupados:
		if o[0].distance_to(p) < o[1] + r:
			return false
	return true


func _tramos(a, b, cortes):
	var res = [[a, b]]
	for c in cortes:
		var c0 = c[0] - c[1]
		var c1 = c[0] + c[1]
		var nuevo = []
		for t in res:
			if c1 <= t[0] or c0 >= t[1]:
				nuevo.append(t)
			else:
				if c0 > t[0]:
					nuevo.append([t[0], c0])
				if c1 < t[1]:
					nuevo.append([c1, t[1]])
		res = nuevo
	return res


# ---------- Piezas del jardin ----------

func _caballo(st, base, esc, giro):
	# Caballo en pose de estatua: cabeza alta y una mano levantada. Mira hacia +X antes del giro.
	var cuerpo = [
		[Vector3(0, 1.32, 0), Vector3(0.78, 0.36, 0.3)],
		[Vector3(0.62, 1.36, 0), Vector3(0.36, 0.4, 0.29)],
		[Vector3(-0.62, 1.42, 0), Vector3(0.42, 0.39, 0.32)],
		[Vector3(1.2, 2.08, 0), Vector3(0.17, 0.16, 0.12)],
	]
	for c in cuerpo:
		_elipsoide(st, base + giro.xform(c[0] * esc), c[1] * esc, giro, 12, 8)
	# Cabeza, alargada en la direccion de la frente al hocico
	var nuca = Vector3(1.15, 2.2, 0)
	var hocico = Vector3(1.52, 1.88, 0)
	var d = (hocico - nuca).normalized()
	var arriba = Vector3(-d.y, d.x, 0)
	var bc = giro * Basis(d, arriba, Vector3(0, 0, 1))
	_elipsoide(st, base + giro.xform((nuca + hocico) * 0.5 * esc), Vector3(0.3, 0.13, 0.11) * esc, bc, 12, 8)
	var huesos = [
		# cuello y crin
		[Vector3(0.78, 1.55, 0), Vector3(1.18, 2.12, 0), 0.3, 0.18],
		[Vector3(0.62, 1.7, 0), Vector3(1.08, 2.24, 0), 0.08, 0.06],
		# orejas
		[Vector3(1.13, 2.28, 0.06), Vector3(1.1, 2.46, 0.07), 0.045, 0.012],
		[Vector3(1.13, 2.28, -0.06), Vector3(1.1, 2.46, -0.07), 0.045, 0.012],
		# mano izquierda (apoyada)
		[Vector3(0.66, 1.12, 0.17), Vector3(0.7, 0.6, 0.17), 0.16, 0.1],
		[Vector3(0.7, 0.6, 0.17), Vector3(0.7, 0.12, 0.17), 0.09, 0.075],
		[Vector3(0.7, 0.12, 0.17), Vector3(0.72, 0.0, 0.17), 0.09, 0.1],
		# mano derecha (levantada)
		[Vector3(0.66, 1.12, -0.17), Vector3(0.92, 0.78, -0.17), 0.16, 0.1],
		[Vector3(0.92, 0.78, -0.17), Vector3(0.82, 0.4, -0.17), 0.09, 0.075],
		[Vector3(0.82, 0.4, -0.17), Vector3(0.8, 0.3, -0.17), 0.09, 0.1],
		# patas traseras
		[Vector3(-0.72, 1.25, 0.18), Vector3(-0.55, 0.82, 0.18), 0.21, 0.13],
		[Vector3(-0.55, 0.82, 0.18), Vector3(-0.82, 0.52, 0.18), 0.12, 0.095],
		[Vector3(-0.82, 0.52, 0.18), Vector3(-0.76, 0.12, 0.18), 0.085, 0.075],
		[Vector3(-0.76, 0.12, 0.18), Vector3(-0.75, 0.0, 0.18), 0.09, 0.1],
		[Vector3(-0.72, 1.25, -0.18), Vector3(-0.55, 0.82, -0.18), 0.21, 0.13],
		[Vector3(-0.55, 0.82, -0.18), Vector3(-0.82, 0.52, -0.18), 0.12, 0.095],
		[Vector3(-0.82, 0.52, -0.18), Vector3(-0.76, 0.12, -0.18), 0.085, 0.075],
		[Vector3(-0.76, 0.12, -0.18), Vector3(-0.75, 0.0, -0.18), 0.09, 0.1],
		# cola
		[Vector3(-1.02, 1.58, 0), Vector3(-1.2, 1.25, 0), 0.09, 0.11],
		[Vector3(-1.2, 1.25, 0), Vector3(-1.18, 0.75, 0), 0.11, 0.05],
	]
	for h in huesos:
		_hueso(st, base + giro.xform(h[0] * esc), base + giro.xform(h[1] * esc), h[2] * esc, h[3] * esc)


func _palmera(s, base, alto, rng):
	var k = alto / 12.0
	# Tronco un poco curvo, con anillos (dos tonos que se alternan).
	var inclina = Vector3(rng.randf_range(-1.0, 1.0), 0, rng.randf_range(-1.0, 1.0)).normalized() * alto * curva_tronco_palma
	var tramos = 8
	var prev = base
	for i in range(tramos):
		var t = float(i + 1) / tramos
		var p = base + Vector3(0, alto * t, 0) + inclina * t * t
		var r0 = lerp(0.6, 0.32, float(i) / tramos) * k
		var r1 = lerp(0.6, 0.32, t) * k
		var clave = "tronco_palma" if i % 2 == 0 else "tronco_palma_b"
		_cono(_st(s, clave), prev, p - prev, r0, r1, (p - prev).length(), 7, false, i == tramos - 1)
		prev = p
	# Cocos debajo de las hojas.
	for c in range(3):
		var ac = TAU * c / 3.0 + rng.randf_range(0.0, 1.0)
		_esfera(_st(s, "coco"), prev + Vector3(cos(ac) * 0.45, -0.55, sin(ac) * 0.45) * k, 0.3 * k, 5, 3, false)
	# Hojas: arcos que suben y caen, con hojitas (textura con huecos).
	var nh = hojas_por_palmera
	for h in range(nh):
		var a = TAU * h / nh + rng.randf_range(-0.15, 0.15)
		var dir = Vector3(cos(a), 0, sin(a))
		var lado = Vector3(-dir.z, 0, dir.x)
		var largo = alto * rng.randf_range(0.42, 0.52)
		var sube = rng.randf_range(0.15, 0.45)
		var segs = 5
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
			var arriba = (a1 - a0).cross(lado).normalized()
			if arriba.y < 0:
				arriba = -arriba
			# Mitad izquierda y mitad derecha, un poco caidas (forma de V).
			_quad_uv(_st(s, "hoja_palma"), [a0, a1, a1 + lado * w1 + caida1, a0 + lado * w0 + caida0],
				[Vector2(0.5, u0), Vector2(0.5, u1), Vector2(1.0, u1), Vector2(1.0, u0)], arriba)
			_quad_uv(_st(s, "hoja_palma"), [a0, a1, a1 - lado * w1 + caida1, a0 - lado * w0 + caida0],
				[Vector2(0.5, u0), Vector2(0.5, u1), Vector2(0.0, u1), Vector2(0.0, u0)], arriba)


# Textura de la hoja de palma: nervio en el centro y hojitas en diagonal,
# con huecos entre ellas (se recortan, no pesan como una transparencia).
func _textura_hoja_palma():
	var ancho = 64
	var alto = 256
	var img = Image.new()
	img.create(ancho, alto, true, Image.FORMAT_RGBA8)
	img.lock()
	var paso = 6.0
	for y in range(alto):
		for x in range(ancho):
			var dx = abs(x - ancho * 0.5 + 0.5)
			var c = Color(0, 0, 0, 0)
			if dx < 1.6:
				c = Color(0.78, 0.82, 0.55, 1.0)
			else:
				# Las hojitas salen del nervio hacia la punta de la hoja.
				var fase = fmod(y - dx * 0.55 + paso * 10.0, paso)
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


# NUEVO - Moneda grande con el logo BDG en las dos caras y canto dorado.
func _monumento_logo(s, base, giro, radio):
	var centro = base + Vector3(0, radio + 0.1, 0)
	var normal = giro.z.normalized()
	var grosor = grosor_monumento
	_cono(_st(s, "aro_logo"), centro - normal * grosor * 0.5, normal, radio, radio, grosor, 48, true, true)
	var st = _st(s, "logo_monumento")
	var r = radio * 0.97
	for lado in [1.0, -1.0]:
		var n = normal * lado
		var c = centro + n * (grosor * 0.5 + 0.05)
		# "derecha" de quien mira esa cara, para que el logo se lea al derecho.
		var der = Vector3.UP.cross(n).normalized()
		var lados = 48
		for i in range(lados):
			var a0 = TAU * i / lados
			var a1 = TAU * (i + 1) / lados
			var p0 = c + (der * cos(a0) + Vector3.UP * sin(a0)) * r
			var p1 = c + (der * cos(a1) + Vector3.UP * sin(a1)) * r
			var puntos = [c, p1, p0]
			var uvs = [Vector2(0.5, 0.5), Vector2(0.5 + cos(a1) * 0.5, 0.5 - sin(a1) * 0.5), Vector2(0.5 + cos(a0) * 0.5, 0.5 - sin(a0) * 0.5)]
			if (puntos[1] - puntos[0]).cross(puntos[2] - puntos[0]).dot(n) > 0:
				puntos = [c, p0, p1]
				uvs = [uvs[0], uvs[2], uvs[1]]
			for k in range(3):
				st.add_normal(n)
				st.add_uv(uvs[k])
				st.add_vertex(puntos[k])


# NUEVO - Logo BDG sobre un talud de cesped inclinado hacia la recta de la meta.
func _logo_inclinado(s, mats, yc):
	var h = tamano_logo * 0.5
	var inc = deg2rad(inclinar_logo)
	var gb = Basis(Vector3.UP, deg2rad(giro_logo))
	var ex = gb.xform(Vector3(1, 0, 0))
	var ez = gb.xform(Vector3(0, sin(inc), -cos(inc)))
	var n = ex.cross(ez).normalized()
	var hb = h + 4.0
	var piso = Vector3(logo_x, yc, logo_z) + gb.xform(Vector3(0, 0, hb * cos(inc)))
	var cb = piso + ez * hb
	# Talud: cara inclinada, espalda y costados.
	var tl = cb - ex * hb + ez * hb
	var tr = cb + ex * hb + ez * hb
	var br = cb + ex * hb - ez * hb
	var bl = cb - ex * hb - ez * hb
	# La espalda baja en loma suave (no en pared), para que desde la recta
	# de enfrente se vea como un cerrito de cesped.
	var atras = gb.xform(Vector3(0, 0, -1))
	var alto_t = tl.y - yc
	var fondo = alto_t / tan(deg2rad(40.0))
	var tl0 = Vector3(tl.x, yc, tl.z) + atras * fondo
	var tr0 = Vector3(tr.x, yc, tr.z) + atras * fondo
	var n_atras = (tr0 - tl0).cross(tl - tl0).normalized()
	if n_atras.y < 0:
		n_atras = -n_atras
	var st_c = _st(s, "cesped_b")
	_quad(st_c, bl, br, tr, tl, n)
	_quad(_st(s, "cesped_a"), tl, tr, tr0, tl0, n_atras)
	_tri(st_c, bl, tl, tl0, -ex, -ex, -ex)
	_tri(st_c, br, tr, tr0, ex, ex, ex)
	# Logo encima del talud, apenas despegado.
	var c = cb + n * 0.6
	if mats.has("logo"):
		var pts = [c - ex * h + ez * h, c + ex * h + ez * h, c + ex * h - ez * h, c - ex * h - ez * h]
		var uvs = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		_quad_uv(_st(s, "logo_monumento"), pts, uvs, n)
	# Aro dorado alrededor, en el mismo plano.
	if poner_aro_logo:
		var st_a = _st(s, "aro_logo")
		var r0 = h + 0.3
		var r1 = h + 1.5
		var ca = cb + n * 0.7
		var lados = 64
		for i in range(lados):
			var a0 = TAU * i / lados
			var a1 = TAU * (i + 1) / lados
			var d0 = ex * cos(a0) + ez * sin(a0)
			var d1 = ex * cos(a1) + ez * sin(a1)
			_quad(st_a, ca + d0 * r0, ca + d1 * r0, ca + d1 * r1, ca + d0 * r1, n)
	_ocupados.append([Vector2(logo_x, logo_z), hb + 3.0])
	_ocupados.append([Vector2(logo_x, logo_z) + Vector2(atras.x, atras.z) * (hb + fondo * 0.5), hb])


func _arbol(s, base, tam, clave_copa):
	var alto_tr = 4.0 * tam
	_cono(_st(s, "tronco_arbol"), base, Vector3.UP, 0.55 * tam, 0.4 * tam, alto_tr, 7, false, false)
	var c = base + Vector3(0, alto_tr + 2.2 * tam, 0)
	_esfera(_st(s, clave_copa), c, 3.4 * tam, 8, 5, false)
	_esfera(_st(s, clave_copa), c + Vector3(1.8, 0.9, 0.6) * tam, 2.5 * tam, 7, 4, false)
	_esfera(_st(s, clave_copa), c + Vector3(-1.4, 1.3, -1.2) * tam, 2.4 * tam, 7, 4, false)


func _macizo(s, p, r, yc, rng, lista):
	var c = Vector3(p.x, yc, p.y)
	_anillo(_st(s, "bordillo"), c, r, r, 0.4, 0.35, 20)
	_cono(_st(s, "tierra"), c, Vector3.UP, r - 0.35, r - 0.35, 0.4, 20, false, true)
	if lista.size() == 0:
		return
	var cantidad = int(PI * r * r * densidad_flores)
	for i in range(cantidad):
		var ang = rng.randf() * TAU
		var dist = sqrt(rng.randf()) * (r - 0.8)
		var q = c + Vector3(cos(ang) * dist, 0.4, sin(ang) * dist)
		var t = rng.randf_range(0.2, 0.3)
		var h = rng.randf_range(0.35, 0.75)
		var clave = "flor_" + str(rng.randi() % lista.size())
		_caja(_st(s, clave), q + Vector3(-t, 0, -t), q + Vector3(t, h, t))


# ---------- Materiales ----------

func _materiales():
	var m = {}
	m["cesped_a"] = _mat(color_cesped_a)
	m["cesped_b"] = _mat(color_cesped_b)
	m["bordillo"] = _mat(color_bordillo)
	m["seto"] = _mat(color_seto)
	m["sendero"] = _mat(color_sendero)
	m["plaza"] = _mat(color_plaza)
	m["piedra"] = _mat(color_piedra)
	m["tronco_palma"] = _mat(color_tronco_palma)
	var hoja = _mat(color_hoja_palma)
	hoja.albedo_texture = _textura_hoja_palma()
	hoja.params_use_alpha_scissor = true
	hoja.params_alpha_scissor_threshold = 0.3
	hoja.params_cull_mode = SpatialMaterial.CULL_DISABLED
	m["hoja_palma"] = hoja
	m["tronco_palma_b"] = _mat(color_tronco_palma.darkened(0.12))
	m["coco"] = _mat(color_coco)
	m["tronco_arbol"] = _mat(color_tronco_arbol)
	m["copa_a"] = _mat(color_copa_a)
	m["copa_b"] = _mat(color_copa_b)
	m["tierra"] = _mat(color_tierra)
	var ca = color_agua
	ca.a = opacidad_agua
	var agua = _mat(ca)
	agua.flags_transparent = true
	agua.params_cull_mode = SpatialMaterial.CULL_DISABLED
	agua.metallic = 0.2
	agua.roughness = 0.1
	m["agua"] = agua
	var est = _mat(color_estatua)
	est.metallic = metal_estatua
	est.roughness = aspereza_estatua
	m["estatua"] = est
	var lista = colores_flores.split(",", false)
	for i in range(lista.size()):
		m["flor_" + str(i)] = _mat(Color(lista[i].strip_edges()))
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
			# NUEVO - el del monumento va sin sombra: se lee igual por las dos caras.
			var lm = ml.duplicate()
			lm.flags_unshaded = true
			lm.albedo_color = Color(brillo_logo, brillo_logo, brillo_logo)
			m["logo_monumento"] = lm
	var aro = _mat(color_aro_logo)
	aro.metallic = 0.4
	aro.roughness = 0.35
	m["aro_logo"] = aro
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


func _hueso(st, a, b, ra, rb):
	var d = b - a
	if d.length() < 0.001:
		return
	_cono(st, a, d, ra, rb, d.length(), 8, false, false)
	_esfera(st, a, ra, 8, 5, false)
	_esfera(st, b, rb, 8, 5, false)


func _esfera(st, centro, radio, segs, anillos, media):
	_elipsoide_parcial(st, centro, Vector3(radio, radio, radio), Basis(), segs, anillos, PI * 0.5 if media else PI)


func _elipsoide(st, centro, radios, b, segs, anillos):
	_elipsoide_parcial(st, centro, radios, b, segs, anillos, PI)


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
		_tri(st, i0, i1, i1 + up, -n0, -n1, -n1)
		_tri(st, i0, i1 + up, i0 + up, -n0, -n1, -n0)


func _disco(st, c, rx, rz, segs):
	for i in range(segs):
		var a0 = TAU * i / segs
		var a1 = TAU * (i + 1) / segs
		var p0 = c + Vector3(cos(a0) * rx, 0, sin(a0) * rz)
		var p1 = c + Vector3(cos(a1) * rx, 0, sin(a1) * rz)
		_tri(st, c, p0, p1, Vector3.UP, Vector3.UP, Vector3.UP)
