tool
extends Spatial

# ============================================================
# BARANDAS DE LA PISTA
# ============================================================
# Construye la baranda interior y la exterior siguiendo TrackPath,
# con sus postes de franjas y el cabezal de color.
#
# ------------------------------------------------------------
# CAMBIO: las mallas ya no se guardan en el archivo de la escena
# ------------------------------------------------------------
# Antes, cada malla generada recibia "owner = edited_scene_root".
# Eso hace que Godot la escriba dentro de PistaDeCarrera.tscn.
# Con 200 segmentos de baranda y un poste cada 10 unidades, eran
# miles de nodos guardados: el .tscn habia llegado a casi 45.000
# lineas, y Godot tiene que leerlo y escribirlo entero cada vez
# que abris o guardas la escena.
#
# Ahora las mallas se crean sin owner. Se ven igual en el editor y
# en el juego, porque el script las rehace en cada arranque, pero
# NO se guardan. La escena se achica muchisimo.
#
# Al abrir la escena por primera vez con este script, las mallas
# viejas que ya estaban guardadas se borran solas (las limpia
# _limpiar_barandas_anteriores) y se rearman sin owner. Guardá la
# escena despues de eso para que el archivo quede liviano.
#
# Si la maquina sigue sufriendo, los dos valores que mas pesan son
# "Segmentos" (200) y "Distancia Entre Postes" (10). Subir la
# distancia entre postes a 20 corta a la mitad la cantidad de
# postes sin que casi se note.
# ============================================================

export(NodePath) var trackpath_path = NodePath("../TrackPath")
export var offset_interior = 0.0 setget set_offset_interior
export var offset_exterior = 165.0 setget set_offset_exterior
export var altura_baranda = 3.0 setget set_altura_baranda
export var num_barras = 3 setget set_num_barras
export var ancho_barra = 0.12 setget set_ancho_barra
export var alto_barra = 0.12 setget set_alto_barra
export var voladizo_cuello_ganso = 0.85 setget set_voladizo_cuello_ganso
export var segmentos = 200
export var color_baranda = Color(0.95, 0.95, 0.95)

export var distancia_entre_postes = 10.0 setget set_distancia_entre_postes
export var grosor_poste = 0.18 setget set_grosor_poste
export var franjas_por_poste = 6 setget set_franjas_por_poste
export var color_franja_a = Color(0.95, 0.95, 0.95)
export var color_franja_b = Color(0.75, 0.05, 0.05)
export var color_cabezal = Color(0.0, 0.45, 1.0)
export var alto_cabezal = 0.3 setget set_alto_cabezal

# --- ESTILO DE BARANDA ---
# 0 = Tubos: adentro cuello de ganso (un tubo grueso sobre postes curvos), afuera
#     dos tubos con malla de rombos. Es lo que se ve en la mayoria de los hipodromos.
# 1 = Doble con malla arriba (el estilo moderno que hicimos antes).
export(int, "Tubos (cuello de ganso + malla)", "Doble con malla arriba") var estilo_baranda = 0 setget set_estilo_baranda
export var separacion_postes_tubo = 8.0 setget set_separacion_postes_tubo
export var radio_tubo = 0.3 setget set_radio_tubo
export var radio_poste_tubo = 0.17 setget set_radio_poste_tubo
export var voladizo_tubo = 1.0 setget set_voladizo_tubo
export var tamano_rombo = 0.7 setget set_tamano_rombo
export var color_tubo = Color("f7f7f4") setget set_color_tubo
export var color_base_tubo = Color("c9c9c4") setget set_color_base_tubo
export var tubo_sin_sombreado = false setget set_tubo_sin_sombreado

# --- BARANDA DOBLE CON MALLA DE SEGURIDAD ---
# Una segunda baranda paralela, del lado de afuera de la pista (hacia
# el jardin en la interior, hacia las tribunas en la exterior), con
# una malla tendida entre las dos por si se cae un jinete.
export var baranda_doble = true setget set_baranda_doble
export var doble_en_interior = true setget set_doble_en_interior
export var doble_en_exterior = true setget set_doble_en_exterior
export var separacion_doble_interior = 3.0 setget set_separacion_doble_interior
export var separacion_doble_exterior = 3.0 setget set_separacion_doble_exterior
export var poner_malla = true setget set_poner_malla
export var altura_malla = 3.0 setget set_altura_malla
export var caida_malla = 0.3 setget set_caida_malla
export var tamano_cuadro_malla = 0.9 setget set_tamano_cuadro_malla
export var color_malla = Color("f2f2f2") setget set_color_malla
# Grosor del hilo de la malla: de 1 (fino) a 7 (muy grueso)
export var grosor_hilo_malla = 4 setget set_grosor_hilo_malla

func _ready():
	_reconstruir()

func set_estilo_baranda(valor):
	estilo_baranda = valor
	_reconstruir()

func set_separacion_postes_tubo(valor):
	separacion_postes_tubo = valor
	_reconstruir()

func set_radio_tubo(valor):
	radio_tubo = valor
	_reconstruir()

func set_radio_poste_tubo(valor):
	radio_poste_tubo = valor
	_reconstruir()

func set_voladizo_tubo(valor):
	voladizo_tubo = valor
	_reconstruir()

func set_tamano_rombo(valor):
	tamano_rombo = valor
	_reconstruir()

func set_color_tubo(valor):
	color_tubo = valor
	_reconstruir()

func set_color_base_tubo(valor):
	color_base_tubo = valor
	_reconstruir()

func set_tubo_sin_sombreado(valor):
	tubo_sin_sombreado = valor
	_reconstruir()

func set_baranda_doble(valor):
	baranda_doble = valor
	_reconstruir()

func set_doble_en_interior(valor):
	doble_en_interior = valor
	_reconstruir()

func set_doble_en_exterior(valor):
	doble_en_exterior = valor
	_reconstruir()

func set_separacion_doble_interior(valor):
	separacion_doble_interior = valor
	_reconstruir()

func set_separacion_doble_exterior(valor):
	separacion_doble_exterior = valor
	_reconstruir()

func set_poner_malla(valor):
	poner_malla = valor
	_reconstruir()

func set_altura_malla(valor):
	altura_malla = valor
	_reconstruir()

func set_caida_malla(valor):
	caida_malla = valor
	_reconstruir()

func set_tamano_cuadro_malla(valor):
	tamano_cuadro_malla = valor
	_reconstruir()

func set_color_malla(valor):
	color_malla = valor
	_reconstruir()

func set_grosor_hilo_malla(valor):
	grosor_hilo_malla = valor
	_reconstruir()

func set_offset_interior(valor):
	offset_interior = valor
	_reconstruir()

func set_offset_exterior(valor):
	offset_exterior = valor
	_reconstruir()

func set_altura_baranda(valor):
	altura_baranda = valor
	_reconstruir()

func set_num_barras(valor):
	num_barras = valor
	_reconstruir()

func set_ancho_barra(valor):
	ancho_barra = valor
	_reconstruir()

func set_alto_barra(valor):
	alto_barra = valor
	_reconstruir()

func set_voladizo_cuello_ganso(valor):
	voladizo_cuello_ganso = valor
	_reconstruir()

func set_distancia_entre_postes(valor):
	distancia_entre_postes = valor
	_reconstruir()

func set_grosor_poste(valor):
	grosor_poste = valor
	_reconstruir()

func set_franjas_por_poste(valor):
	franjas_por_poste = valor
	_reconstruir()

func set_alto_cabezal(valor):
	alto_cabezal = valor
	_reconstruir()


func _reconstruir():
	var trackpath = get_node_or_null(trackpath_path)
	if trackpath == null or trackpath.curve == null:
		return

	var curve = trackpath.curva_grama if trackpath.get("curva_grama") else trackpath.curve
	var largo_total = curve.get_baked_length()
	if largo_total <= 0:
		return

	_limpiar_barandas_anteriores()

	var puntos = []
	for i in range(segmentos):
		var dist = largo_total * float(i) / float(segmentos)
		var punto_local = curve.interpolate_baked(dist)
		puntos.append(trackpath.to_global(punto_local))

	var centro_oval = Vector3.ZERO
	for p in puntos:
		centro_oval += p
	centro_oval /= puntos.size()

	if estilo_baranda == 0:
		_construir_tubos(trackpath, curve, largo_total, centro_oval)
		return

	_construir_baranda_completa(puntos, centro_oval, offset_interior, "Baranda_Interior", 1.0)
	_construir_baranda_completa(puntos, centro_oval, offset_exterior, "Baranda_Exterior", -1.0)

	_construir_postes(centro_oval, largo_total, trackpath, curve, offset_interior, "Poste_Interior", 1.0)
	_construir_postes(centro_oval, largo_total, trackpath, curve, offset_exterior, "Poste_Exterior", -1.0)

	# Baranda doble: la segunda va sin cuello de ganso, con sus postes
	# juntos en un solo dibujo (para no cargar el telefono), y la malla
	# tendida entre las dos.
	if baranda_doble:
		if doble_en_interior:
			var off_i2 = offset_interior - separacion_doble_interior
			_construir_baranda_completa(puntos, centro_oval, off_i2, "Baranda_Interior_Doble", 0.0)
			_construir_postes_juntos(centro_oval, largo_total, trackpath, curve, off_i2, "Poste_Interior_Doble")
			if poner_malla:
				_construir_malla(puntos, centro_oval, offset_interior, off_i2, "Baranda_Interior_Malla")
		if doble_en_exterior:
			var off_e2 = offset_exterior + separacion_doble_exterior
			_construir_baranda_completa(puntos, centro_oval, off_e2, "Baranda_Exterior_Doble", 0.0)
			_construir_postes_juntos(centro_oval, largo_total, trackpath, curve, off_e2, "Poste_Exterior_Doble")
			if poner_malla:
				_construir_malla(puntos, centro_oval, offset_exterior, off_e2, "Baranda_Exterior_Malla")


func _limpiar_barandas_anteriores():
	for hijo in get_children():
		if hijo.name.begins_with("Baranda_Interior") or hijo.name.begins_with("Baranda_Exterior") or hijo.name.begins_with("Poste_Interior") or hijo.name.begins_with("Poste_Exterior"):
			remove_child(hijo)
			hijo.free()


func _construir_baranda_completa(puntos, centro_oval, offset_lateral, nombre_base, signo_volado):
	for i in range(num_barras):
		var altura_barra = altura_baranda * float(i + 1) / float(num_barras)
		var es_barra_superior = (i == num_barras - 1)

		var offset_esta_barra = offset_lateral
		var ancho_esta_barra = ancho_barra
		var alto_esta_barra = alto_barra

		if es_barra_superior:
			offset_esta_barra += voladizo_cuello_ganso * signo_volado
			ancho_esta_barra *= 1.4
			alto_esta_barra *= 1.4

		var nombre = nombre_base + "_Barra" + str(i + 1)
		_construir_una_barra(puntos, centro_oval, offset_esta_barra, altura_barra, ancho_esta_barra, alto_esta_barra, nombre)


func _construir_una_barra(puntos, centro_oval, offset_base, altura_centro, ancho, alto, nombre_base):
	var medio_ancho = ancho * 0.5
	var medio_alto = alto * 0.5
	var offset_int = offset_base - medio_ancho
	var offset_ext = offset_base + medio_ancho
	var y_abajo = altura_centro - medio_alto
	var y_arriba = altura_centro + medio_alto

	_tira(puntos, centro_oval, offset_int, y_abajo, offset_int, y_arriba, nombre_base + "_CaraInt")
	_tira(puntos, centro_oval, offset_ext, y_abajo, offset_ext, y_arriba, nombre_base + "_CaraExt")
	_tira(puntos, centro_oval, offset_int, y_arriba, offset_ext, y_arriba, nombre_base + "_Arriba")
	_tira(puntos, centro_oval, offset_int, y_abajo, offset_ext, y_abajo, nombre_base + "_Abajo")


func _tira(puntos, centro_oval, offset_a, y_a, offset_b, y_b, nombre):
	var n = puntos.size()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	for i in range(n + 1):
		var idx = i % n
		var idx_sig = (i + 1) % n
		var punto = puntos[idx]
		var punto_sig = puntos[idx_sig]

		var tangente = (punto_sig - punto).normalized()
		var lateral = Vector3(tangente.z, 0, -tangente.x)

		var hacia_afuera = punto - centro_oval
		hacia_afuera.y = 0
		if lateral.dot(hacia_afuera) < 0:
			lateral = -lateral

		var v1 = to_local(punto + lateral * offset_a) + Vector3(0, y_a, 0)
		var v2 = to_local(punto + lateral * offset_b) + Vector3(0, y_b, 0)

		st.add_normal(Vector3(0, 1, 0))
		st.add_vertex(v1)
		st.add_normal(Vector3(0, 1, 0))
		st.add_vertex(v2)

	var mesh = st.commit()

	var mi = MeshInstance.new()
	mi.name = nombre
	mi.mesh = mesh

	var mat = SpatialMaterial.new()
	mat.albedo_color = color_baranda
	mat.flags_unshaded = true
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	mi.material_override = mat

	add_child(mi)
	# NO se le asigna "owner" a proposito. Una malla con owner queda
	# guardada dentro del archivo .tscn; sin owner, se genera al vuelo
	# en cada arranque y no ensucia la escena.


func _construir_postes(centro_oval, largo_total, trackpath, curve, offset_lateral, nombre_base, signo_volado):
	var num_postes = int(largo_total / distancia_entre_postes)
	if num_postes < 1:
		return

	for i in range(num_postes):
		var dist = i * distancia_entre_postes
		var dist_sig = fmod(dist + 1.0, largo_total)
		var punto = trackpath.to_global(curve.interpolate_baked(dist))
		var punto_sig = trackpath.to_global(curve.interpolate_baked(dist_sig))

		var tangente = (punto_sig - punto).normalized()
		var lateral = Vector3(tangente.z, 0, -tangente.x)

		var hacia_afuera = punto - centro_oval
		hacia_afuera.y = 0
		if lateral.dot(hacia_afuera) < 0:
			lateral = -lateral

		var borde = punto + lateral * offset_lateral
		var local = to_local(borde)
		var base_y = local.y

		var borde_volado = punto + lateral * (offset_lateral + voladizo_cuello_ganso * signo_volado)
		var local_volado = to_local(borde_volado)

		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		var medio = grosor_poste * 0.5
		var alto_franja = altura_baranda / float(max(franjas_por_poste, 1))

		for f in range(franjas_por_poste):
			var y0 = base_y + f * alto_franja
			var y1 = y0 + alto_franja
			var color = color_franja_a if f % 2 == 0 else color_franja_b
			_agregar_caja(st, local.x, local.z, medio, y0, y1, color)

		var y_codo_inicio = base_y + altura_baranda - alto_franja
		var y_codo_fin = base_y + altura_baranda
		_agregar_caja_entre(st, local.x, local.z, local_volado.x, local_volado.z, medio * 0.8, y_codo_inicio, y_codo_fin, color_baranda)

		_agregar_caja(st, local_volado.x, local_volado.z, medio * 1.8, base_y + altura_baranda, base_y + altura_baranda + alto_cabezal, color_cabezal)

		var mesh = st.commit()

		var mi = MeshInstance.new()
		mi.name = nombre_base + "_" + str(i)
		mi.mesh = mesh

		var mat = SpatialMaterial.new()
		mat.flags_unshaded = true
		mat.vertex_color_use_as_albedo = true
		mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
		mi.material_override = mat

		add_child(mi)
		# Sin owner, igual que las barras: no se guarda en el .tscn.


func _agregar_caja(st, cx, cz, medio, y0, y1, color):
	var x0 = cx - medio
	var x1 = cx + medio
	var z0 = cz - medio
	var z1 = cz + medio

	var p = [
		Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0),
		Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1)
	]

	var caras = [
		[0, 1, 2, 0, 2, 3],
		[5, 4, 7, 5, 7, 6],
		[4, 0, 3, 4, 3, 7],
		[1, 5, 6, 1, 6, 2],
		[3, 2, 6, 3, 6, 7],
		[4, 5, 1, 4, 1, 0]
	]

	for cara in caras:
		for idx in cara:
			st.add_color(color)
			st.add_vertex(p[idx])


func _agregar_caja_entre(st, xa, za, xb, zb, medio, y0, y1, color):
	var dx = xb - xa
	var dz = zb - za
	var largo = sqrt(dx * dx + dz * dz)
	if largo < 0.001:
		return
	var dirx = dx / largo
	var dirz = dz / largo
	var perpx = -dirz * medio
	var perpz = dirx * medio

	var p = [
		Vector3(xa + perpx, y0, za + perpz), Vector3(xa - perpx, y0, za - perpz),
		Vector3(xb - perpx, y0, zb - perpz), Vector3(xb + perpx, y0, zb + perpz),
		Vector3(xa + perpx, y1, za + perpz), Vector3(xa - perpx, y1, za - perpz),
		Vector3(xb - perpx, y1, zb - perpz), Vector3(xb + perpx, y1, zb + perpz)
	]

	var caras = [
		[0, 1, 2, 0, 2, 3],
		[4, 7, 6, 4, 6, 5],
		[0, 4, 5, 0, 5, 1],
		[1, 5, 6, 1, 6, 2],
		[2, 6, 7, 2, 7, 3],
		[3, 7, 4, 3, 4, 0]
	]

	for cara in caras:
		for idx in cara:
			st.add_color(color)
			st.add_vertex(p[idx])


# ------------------------------------------------------------
# Postes de la segunda baranda: todos en un solo dibujo.
# ------------------------------------------------------------
func _construir_postes_juntos(centro_oval, largo_total, trackpath, curve, offset_lateral, nombre):
	var num_postes = int(largo_total / distancia_entre_postes)
	if num_postes < 1:
		return
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var medio = grosor_poste * 0.5
	var alto_franja = altura_baranda / float(max(franjas_por_poste, 1))
	for i in range(num_postes):
		var dist = i * distancia_entre_postes
		var punto = trackpath.to_global(curve.interpolate_baked(dist))
		var punto_sig = trackpath.to_global(curve.interpolate_baked(fmod(dist + 1.0, largo_total)))
		var tangente = (punto_sig - punto).normalized()
		var lateral = Vector3(tangente.z, 0, -tangente.x)
		var hacia_afuera = punto - centro_oval
		hacia_afuera.y = 0
		if lateral.dot(hacia_afuera) < 0:
			lateral = -lateral
		var local = to_local(punto + lateral * offset_lateral)
		for f in range(franjas_por_poste):
			var y0 = local.y + f * alto_franja
			var color = color_franja_a if f % 2 == 0 else color_franja_b
			_agregar_caja(st, local.x, local.z, medio, y0, y0 + alto_franja, color)
		_agregar_caja(st, local.x, local.z, medio * 1.8, local.y + altura_baranda, local.y + altura_baranda + alto_cabezal, color_cabezal)
	var mi = MeshInstance.new()
	mi.name = nombre
	mi.mesh = st.commit()
	var mat = SpatialMaterial.new()
	mat.flags_unshaded = true
	mat.vertex_color_use_as_albedo = true
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	mi.material_override = mat
	add_child(mi)


# ------------------------------------------------------------
# Malla de seguridad tendida entre las dos barandas, con una caida
# en el medio como una red. Los cuadritos se dibujan con una
# textura hecha aqui mismo (no hace falta ningun archivo).
# ------------------------------------------------------------
func _construir_malla(puntos, centro_oval, offset_a, offset_b, nombre):
	var n = puntos.size()
	var partes = 4
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cuadro = max(tamano_cuadro_malla, 0.05)
	var ancho = abs(offset_b - offset_a)
	var recorrido = 0.0
	var filas = []
	for i in range(n + 1):
		var idx = i % n
		var punto = puntos[idx]
		var punto_sig = puntos[(i + 1) % n]
		if i > 0:
			recorrido += puntos[(i - 1) % n].distance_to(punto)
		var tangente = (punto_sig - punto).normalized()
		var lateral = Vector3(tangente.z, 0, -tangente.x)
		var hacia_afuera = punto - centro_oval
		hacia_afuera.y = 0
		if lateral.dot(hacia_afuera) < 0:
			lateral = -lateral
		var fila = []
		for k in range(partes + 1):
			var f = float(k) / partes
			var off = lerp(offset_a, offset_b, f)
			var y = altura_malla - caida_malla * sin(PI * f)
			var v = to_local(punto + lateral * off) + Vector3(0, y, 0)
			fila.append([v, Vector2(recorrido / cuadro, f * ancho / cuadro)])
		filas.append(fila)
	for i in range(n):
		for k in range(partes):
			var a = filas[i][k]
			var b = filas[i][k + 1]
			var c = filas[i + 1][k + 1]
			var d = filas[i + 1][k]
			for vtx in [a, b, c, a, c, d]:
				st.add_normal(Vector3.UP)
				st.add_uv(vtx[1])
				st.add_vertex(vtx[0])
	var mi = MeshInstance.new()
	mi.name = nombre
	mi.mesh = st.commit()
	var mat = SpatialMaterial.new()
	mat.albedo_color = color_malla
	mat.albedo_texture = _textura_malla()
	mat.flags_unshaded = true
	mat.flags_transparent = true
	mat.params_use_alpha_scissor = true
	mat.params_alpha_scissor_threshold = 0.5
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	mi.material_override = mat
	add_child(mi)


func _textura_malla():
	var tam = 16
	var g = int(clamp(grosor_hilo_malla, 1, 7))
	var img = Image.new()
	img.create(tam, tam, true, Image.FORMAT_RGBA8)
	img.lock()
	for x in range(tam):
		for y in range(tam):
			var hilo = x < g or y < g
			img.set_pixel(x, y, Color(1, 1, 1, 1) if hilo else Color(1, 1, 1, 0))
	img.unlock()
	img.generate_mipmaps()
	var tex = ImageTexture.new()
	tex.create_from_image(img, Texture.FLAG_REPEAT | Texture.FLAG_MIPMAPS)
	return tex


# ------------------------------------------------------------
# ESTILO TUBOS: adentro cuello de ganso, afuera dos tubos con malla.
# ------------------------------------------------------------
func _construir_tubos(trackpath, curve, largo_total, centro_oval):
	var mats = _materiales_tubo()
	var inv = global_transform.basis.inverse()
	for conf in [[offset_interior, 1.0, "cuello", "Baranda_Interior_Tubo"], [offset_exterior, -1.0, "tubos", "Baranda_Exterior_Tubo"]]:
		var pts = []
		var dirs = []
		var d = 0.0
		var paso = max(separacion_postes_tubo, 1.0)
		while d < largo_total - 0.5:
			var p = trackpath.to_global(curve.interpolate_baked(d))
			var p2 = trackpath.to_global(curve.interpolate_baked(fmod(d + 1.0, largo_total)))
			var tg = p2 - p
			tg.y = 0
			tg = tg.normalized()
			var lat = Vector3(tg.z, 0, -tg.x)
			var af = p - centro_oval
			af.y = 0
			if lat.dot(af) < 0:
				lat = -lat
			pts.append(to_local(p + lat * conf[0]))
			dirs.append(inv.xform(lat * conf[1]).normalized())
			d += paso
		_armar_tubos(pts, dirs, altura_baranda, conf[2], mats, conf[3])


func _armar_tubos(puntos, hacia_pista, h, estilo, mats, nombre):
	var s = {}
	var n = puntos.size()
	for i in range(n):
		var p = puntos[i]
		var d = hacia_pista[i]
		var q = puntos[(i + 1) % n]
		var dq = hacia_pista[(i + 1) % n]
		_caja(_st(s, "base"), p + Vector3(-0.35, 0, -0.35), p + Vector3(0.35, 0.08, 0.35))
		if estilo == "cuello":
			var vol = voladizo_tubo
			var r = radio_poste_tubo
			var a = p + Vector3(0, h - 0.9, 0)
			_cono(_st(s, "tubo"), p, Vector3.UP, r, r, h - 0.9, 6, false, false)
			var b = p + Vector3(0, h - 0.25, 0) + d * vol * 0.35
			var c = p + Vector3(0, h, 0) + d * vol
			_cono(_st(s, "tubo"), a, b - a, r, r, (b - a).length(), 6, false, false)
			_esfera(_st(s, "tubo"), b, r, 6, 3, false)
			_cono(_st(s, "tubo"), b, c - b, r, r, (c - b).length(), 6, false, false)
			var c2 = q + Vector3(0, h, 0) + dq * vol
			_cono(_st(s, "tubo"), c, c2 - c, radio_tubo, radio_tubo, (c2 - c).length(), 6, false, false)
			_cono(_st(s, "tubo"), c - (c2 - c).normalized() * 0.2, (c2 - c), radio_tubo * 1.13, radio_tubo * 1.13, 0.4, 6, false, false)
		else:
			var r = radio_poste_tubo * 1.1
			_cono(_st(s, "tubo"), p, Vector3.UP, r, r, h + 0.1, 6, false, true)
			for yb in [h * 0.33, h]:
				var a2 = p + Vector3(0, yb, 0)
				var b2 = q + Vector3(0, yb, 0)
				var rr = radio_tubo * 0.8 if yb == h else radio_tubo * 0.65
				_cono(_st(s, "tubo"), a2, b2 - a2, rr, rr, (b2 - a2).length(), 6, false, false)
				_cono(_st(s, "tubo"), a2 - (b2 - a2).normalized() * 0.2, (b2 - a2), radio_tubo * 0.95, radio_tubo * 0.95, 0.4, 6, false, false)
			var y0 = h * 0.33
			var largo = p.distance_to(q)
			var pts = [p + Vector3(0, h, 0), q + Vector3(0, h, 0), q + Vector3(0, y0, 0), p + Vector3(0, y0, 0)]
			var uvs = [Vector2(0, 0), Vector2(largo / tamano_rombo, 0), Vector2(largo / tamano_rombo, (h - y0) / tamano_rombo), Vector2(0, (h - y0) / tamano_rombo)]
			_quad_uv(_st(s, "malla"), pts, uvs, d)
	for clave in s.keys():
		var mi = MeshInstance.new()
		mi.name = nombre + "_" + clave
		mi.mesh = s[clave].commit()
		mi.material_override = mats[clave]
		add_child(mi)


func _hueso2(st, a, b, r):
	var d = b - a
	if d.length() < 0.001:
		return
	_cono(st, a, d, r, r, d.length(), 7, false, false)
	_esfera(st, b, r, 7, 4, false)


func _materiales_tubo():
	var m = {}
	for par in [["tubo", color_tubo], ["base", color_base_tubo]]:
		var x = SpatialMaterial.new()
		x.albedo_color = par[1]
		x.roughness = 0.35
		x.flags_unshaded = tubo_sin_sombreado
		m[par[0]] = x
	var malla = SpatialMaterial.new()
	malla.albedo_color = color_malla
	malla.flags_unshaded = tubo_sin_sombreado
	malla.albedo_texture = _textura_rombos()
	malla.flags_transparent = true
	malla.params_use_alpha_scissor = true
	malla.params_alpha_scissor_threshold = 0.5
	malla.params_cull_mode = SpatialMaterial.CULL_DISABLED
	m["malla"] = malla
	return m


func _textura_rombos():
	var tam = 32
	var img = Image.new()
	img.create(tam, tam, true, Image.FORMAT_RGBA8)
	img.lock()
	for x in range(tam):
		for y in range(tam):
			var a = abs(((x + y) % tam) - tam / 2)
			var b = abs(((x - y + tam) % tam) - tam / 2)
			var hilo = a > tam / 2 - 2 or b > tam / 2 - 2
			img.set_pixel(x, y, Color(1, 1, 1, 1) if hilo else Color(1, 1, 1, 0))
	img.unlock()
	img.generate_mipmaps()
	var t = ImageTexture.new()
	t.create_from_image(img, Texture.FLAG_REPEAT | Texture.FLAG_MIPMAPS | Texture.FLAG_FILTER)
	return t


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
