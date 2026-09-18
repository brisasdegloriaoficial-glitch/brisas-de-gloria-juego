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
export var offset_interior = 2.0 setget set_offset_interior
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

func _ready():
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

	var curve = trackpath.curve
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

	_construir_baranda_completa(puntos, centro_oval, offset_interior, "Baranda_Interior", 1.0)
	_construir_baranda_completa(puntos, centro_oval, offset_exterior, "Baranda_Exterior", -1.0)

	_construir_postes(centro_oval, largo_total, trackpath, curve, offset_interior, "Poste_Interior", 1.0)
	_construir_postes(centro_oval, largo_total, trackpath, curve, offset_exterior, "Poste_Exterior", -1.0)


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
