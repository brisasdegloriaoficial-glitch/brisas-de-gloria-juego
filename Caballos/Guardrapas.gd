extends Spatial
# Guardrapas.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Va en un nodo Spatial llamado Guardrapas, hijo del nodo raiz de PistaDeCarrera.
# Pone el numero de cada caballo en el espacio que queda DETRAS de la silla,
# a cada costado: un pano de un color con la bola blanca y el numero.
# Va pegado a la silla, asi se mueve con el caballo.
# Si le pones una imagen en "Imagen Pano" (por ejemplo la de ChatGPT, blanca y con
# fondo transparente), el pano toma esa forma y se pinta del color de cada numero.
# Las medidas van en "veces el largo de la silla" (1.0 = lo que mide la silla).
# El pano va pegado al cuerpo, por debajo del faldon de la silla. Como cada raza
# tiene el cuerpo distinto, el arabe, el Cuarto de Milla y el Ingles tienen su
# propio separar / inclinar / girar (separar, inclinar y girar solos = americano).
# Cada caballo lleva su juego: sudadera, riendas y brida del mismo color.
# En la brida solo se pinta el cuero; el bocado de metal queda igual.
# VERSION: juegos de colores con marrones (oct 2026)

export var activo := true
export(Texture) var imagen_pano
export var usar_colores_oficiales := true
export var color_pano := Color("e3001b")          # si apagas los colores oficiales
# Colores de los juegos (sudadera + riendas + brida). Se pueden agregar o quitar.
# Mientras mas veces este un color en la lista, mas sale (el cuero va 7 veces).
export var colores := PoolColorArray([Color("704a2b"), Color("704a2b"), Color("704a2b"),
	Color("704a2b"), Color("704a2b"), Color("704a2b"), Color("704a2b"),
	Color("3b2416"), Color("5a3820"), Color("8b5a2b"), Color("6b2f1c"),
	Color("1a1a1a"), Color("3c3c3c"), Color("6e6e6e"), Color("9b0030"), Color("5e0020"),
	Color("1f2f5a"), Color("0f3d2a"), Color("0047ff"), Color("5533ff"), Color("7a00e6"),
	Color("00b140"), Color("ff6a00")])
# Encendido: en cada carrera cada caballo saca un color al azar (se pueden repetir).
# Apagado: el color va por numero (1 = el primero de la lista, 2 = el segundo...).
export var juegos_al_azar := true
export var pintar_riendas := true    # las riendas del mismo color de la sudadera
export var pintar_brida := true      # el cuero de la brida del mismo color de la sudadera
export var ancho := 1.45           # largo del pano a lo largo del caballo
export var alto := 1.0
export var correr_atras := -0.425  # + lo lleva hacia la cola, - hacia la cabeza
export var altura := 0.15          # 0 = abajo de la silla, 1 = arriba de la silla
export var separar := 0.95         # distancia al centro del caballo (1 = ancho de la silla)
export var inclinar := 20.0        # grados: + mete la parte de arriba hacia el caballo
export var girar := 11.0           # grados: + mete la punta de atras (la de la cola) hacia el caballo
# Lo mismo para cada raza (el cuerpo de cada una es distinto)
export var separar_arabe := 0.79
export var inclinar_arabe := -6.0
export var girar_arabe := -17.0
export var separar_cuartomilla := 0.79
export var inclinar_cuartomilla := 3.0
export var girar_cuartomilla := 2.0
export var separar_ingles := 0.88
export var inclinar_ingles := 4.0
export var girar_ingles := 9.0
export var radio_bola := 0.22
export var bola_atras := 0.475     # corre la bola: + hacia la cola, - hacia la cabeza
export var bola_abajo := 0.14      # baja la bola dentro del pano
export var tamano_numero := 1.3    # alto del numero comparado con el radio de la bola
export var ruta_fuente := "res://Oswald.ttf/static/Oswald-Bold.ttf"
export var mostrar_diagnostico := true

const MATERIAL_SILLA := "Silla_Americano_Cuero.material"

var _fuente = null


func _ready():
	if not activo:
		return
	get_tree().create_timer(0.3).connect("timeout", self, "_poner_todas")


func _poner_todas():
	var raiz = get_tree().current_scene
	if raiz == null:
		return
	if ruta_fuente != "" and ResourceLoader.exists(ruta_fuente):
		var datos = load(ruta_fuente)
		if datos is DynamicFontData:
			_fuente = DynamicFont.new()
			_fuente.font_data = datos
			_fuente.size = 96
	var azar = RandomNumberGenerator.new()
	azar.randomize()
	var cuantas = 0
	for e in _enrutadores(raiz):
		var n = GestorNivel.obtener_puesto(e) if GestorNivel else int(e.name.substr(17))
		if n > 0:
			var c = color_pano
			if usar_colores_oficiales and colores.size() > 0:
				if juegos_al_azar:
					c = colores[azar.randi_range(0, colores.size() - 1)]
				else:
					c = colores[(n - 1) % colores.size()]
			if _poner(e, n, c):
				cuantas += 1
	if mostrar_diagnostico:
		print("[BDG-Guardrapas] puestas: ", cuantas)


func _enrutadores(n) -> Array:
	var r = []
	for c in n.get_children():
		if c is PathFollow and c.name.begins_with("Enrutador_Caballo"):
			r.append(c)
		else:
			r += _enrutadores(c)
	return r


func _poner(enrutador, numero, c_pano : Color) -> bool:
	var silla = _buscar_silla(enrutador)
	if silla == null:
		if mostrar_diagnostico:
			print("[BDG-Guardrapas] ", enrutador.name, ": no encontre la silla")
		return false
	var hueso = silla.get_parent()
	while hueso != null and not (hueso is BoneAttachment):
		hueso = hueso.get_parent()
	if hueso == null:
		return false
	var vieja = hueso.get_node_or_null("Guardrapa")
	if vieja:
		vieja.free()
	var modelo = silla
	while modelo.get_parent() != null and modelo.get_parent() != enrutador:
		modelo = modelo.get_parent()

	# Marco: arriba = arriba de la pista, adelante = hacia la cabeza, lado = costado
	var caja_s = silla.get_transformed_aabb()
	var centro = caja_s.position + caja_s.size * 0.5
	var arriba = Vector3.UP
	var cabeza = modelo.find_node("BoneAttachment_Cabeza", true, false)
	var hacia = Vector3.FORWARD
	if cabeza:
		hacia = cabeza.global_transform.origin - centro
	# El largo de la silla dice hacia donde mira el cuerpo (la cabeza puede venir
	# girada hacia un lado); la cabeza solo dice cual de las dos puntas es la de adelante
	var eje : Vector3 = silla.global_transform.basis.x
	eje = eje - arriba * eje.dot(arriba)
	if eje.length() > 0.0001:
		if eje.dot(hacia) < 0.0:
			eje = -eje
		hacia = eje
	hacia = (hacia - arriba * hacia.dot(arriba)).normalized()
	var lado = arriba.cross(hacia).normalized()
	var marco = Transform(Basis(lado, arriba, hacia), centro)
	var al_marco = marco.affine_inverse()

	# Medidas de la silla en ese marco
	var caja = silla.get_aabb()
	var mn = Vector3(1e20, 1e20, 1e20)
	var mx = -mn
	for i in 8:
		var q = al_marco.xform(silla.global_transform.xform(caja.get_endpoint(i)))
		mn = Vector3(min(mn.x, q.x), min(mn.y, q.y), min(mn.z, q.z))
		mx = Vector3(max(mx.x, q.x), max(mx.y, q.y), max(mx.z, q.z))
	var L = mx.z - mn.z
	var medio_ancho = max(abs(mn.x), abs(mx.x))
	var H = mx.y - mn.y
	if L <= 0.0:
		return false

	var c_num = c_pano
	var c_bola = Color("ffffff")
	if c_pano.v > 0.9 and c_pano.s < 0.15:
		c_bola = Color("111111")
		c_num = Color("ffffff")

	var g = Spatial.new()
	g.name = "Guardrapa"
	hueso.add_child(g)
	g.global_transform = marco

	# Cada raza con sus medidas
	var raza = _raza(modelo)
	var sep = separar
	var inc = inclinar
	var gir = girar
	if raza == "arabe":
		sep = separar_arabe
		inc = inclinar_arabe
		gir = girar_arabe
	elif raza == "cuartomilla":
		sep = separar_cuartomilla
		inc = inclinar_cuartomilla
		gir = girar_cuartomilla
	elif raza == "ingles":
		sep = separar_ingles
		inc = inclinar_ingles
		gir = girar_ingles

	var w = L * ancho
	var h = L * alto
	var z_c = mn.z - L * correr_atras
	var y_c = mn.y + H * altura
	for signo in [1.0, -1.0]:
		var t = deg2rad(inc)
		var n3 = Vector3(signo * cos(t), sin(t), 0).normalized()
		var y_l = (Vector3.UP - n3 * n3.y).normalized()
		var x_l = y_l.cross(n3).normalized()
		# girar: la punta de atras del pano se mete hacia el caballo (en espejo a cada lado)
		var giro = Basis(Vector3.UP, deg2rad(signo * gir))
		var bas = giro * Basis(x_l, y_l, n3)
		n3 = bas.z.normalized()
		y_l = bas.y.normalized()
		var pos = Vector3(signo * medio_ancho * sep, y_c, z_c)
		var pano = _malla_pano(w, h, c_pano)
		pano.transform = Transform(bas, pos)
		g.add_child(pano)
		# la bola, corrida a lo largo del pano (hacia la cola = -z del caballo)
		var corrida = giro.xform(Vector3(0, 0, -L * bola_atras)) - y_l * (L * bola_abajo)
		var r_bola = L * radio_bola
		var bola = _malla_bola(r_bola, c_bola)
		bola.transform = Transform(bas, pos + corrida + n3 * (L * 0.004))
		g.add_child(bola)
		var etiqueta = _numero(numero, c_num, r_bola)
		if etiqueta:
			etiqueta.transform = Transform(bas, pos + corrida + n3 * (L * 0.008))
			g.add_child(etiqueta)
	_pintar_arreos(modelo, c_pano)
	if mostrar_diagnostico:
		print("[BDG-Guardrapas] ", enrutador.name, ": puesta (", raza, ") color ", c_pano.to_html(false))
	return true


# Riendas y brida del mismo color de la sudadera. En la brida solo cambia
# el cuero (la primera parte de la malla); el bocado de metal queda igual.
func _pintar_arreos(modelo, color : Color):
	if pintar_riendas:
		for r in _con_propiedad(modelo, "color_rienda"):
			r.color_rienda = color
	if pintar_brida:
		var cabeza = modelo.find_node("BoneAttachment_Cabeza", true, false)
		if cabeza:
			var mat = SpatialMaterial.new()
			mat.albedo_color = color
			mat.roughness = 0.85
			for mi in _mallas(cabeza):
				if mi.mesh != null and mi.mesh.get_surface_count() > 0:
					mi.set_surface_material(0, mat)


func _con_propiedad(n, propiedad : String) -> Array:
	var r = []
	if propiedad in n:
		r.append(n)
	for c in n.get_children():
		r += _con_propiedad(c, propiedad)
	return r


func _mallas(n) -> Array:
	var r = []
	if n is MeshInstance:
		r.append(n)
	for c in n.get_children():
		r += _mallas(c)
	return r


# La raza sale del nombre del modelo o de sus hijos (Caballo_Arabe_01, etc.)
func _raza(modelo) -> String:
	var nombres : String = modelo.name
	for c in modelo.get_children():
		nombres += " " + c.name
	if nombres.find("Arabe") >= 0:
		return "arabe"
	if nombres.find("CuartoMilla") >= 0:
		return "cuartomilla"
	if nombres.find("Ingles") >= 0:
		return "ingles"
	return "americano"


func _buscar_silla(n):
	if n is MeshInstance and n.is_visible_in_tree() and n.material_override != null:
		if n.material_override.resource_path.ends_with(MATERIAL_SILLA):
			return n
	for c in n.get_children():
		var r = _buscar_silla(c)
		if r != null:
			return r
	return null


# Pano: rectangulo con las esquinas redondeadas (o la forma de la imagen)
func _malla_pano(w, h, color):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var borde = []
	if imagen_pano != null:
		borde = [Vector2(-w, -h) * 0.5, Vector2(w, -h) * 0.5, Vector2(w, h) * 0.5, Vector2(-w, h) * 0.5]
	else:
		var r = min(w, h) * 0.18
		var esquinas = [[Vector2(w * 0.5 - r, -h * 0.5 + r), -PI * 0.5], [Vector2(w * 0.5 - r, h * 0.5 - r), 0.0],
			[Vector2(-w * 0.5 + r, h * 0.5 - r), PI * 0.5], [Vector2(-w * 0.5 + r, -h * 0.5 + r), PI]]
		for e in esquinas:
			for k in 7:
				var a = e[1] + (PI * 0.5) * k / 6.0
				borde.append(e[0] + Vector2(cos(a), sin(a)) * r)
	for i in borde.size():
		var a = borde[i]
		var b = borde[(i + 1) % borde.size()]
		for p in [Vector2.ZERO, b, a]:
			st.add_normal(Vector3(0, 0, 1))
			st.add_uv(Vector2(p.x / w + 0.5, 0.5 - p.y / h))
			st.add_vertex(Vector3(p.x, p.y, 0))
	var mi = MeshInstance.new()
	mi.name = "Pano"
	mi.mesh = st.commit()
	var mat = SpatialMaterial.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	if imagen_pano != null:
		mat.albedo_texture = imagen_pano
		mat.params_use_alpha_scissor = true
		mat.params_alpha_scissor_threshold = 0.5
	mi.material_override = mat
	return mi


func _malla_bola(radio, color):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lados = 32
	for i in lados:
		var a0 = TAU * i / lados
		var a1 = TAU * (i + 1) / lados
		for p in [Vector3.ZERO, Vector3(cos(a1), sin(a1), 0) * radio, Vector3(cos(a0), sin(a0), 0) * radio]:
			st.add_normal(Vector3(0, 0, 1))
			st.add_vertex(p)
	var mi = MeshInstance.new()
	mi.name = "Bola"
	mi.mesh = st.commit()
	var mat = SpatialMaterial.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mat.params_cull_mode = SpatialMaterial.CULL_DISABLED
	mi.material_override = mat
	return mi


func _numero(numero, color, radio):
	if not ClassDB.class_exists("Label3D"):
		return null
	var lb = ClassDB.instance("Label3D")
	lb.name = "Numero"
	lb.text = str(numero)
	lb.modulate = color
	if _fuente:
		lb.font = _fuente
	if "outline_size" in lb:
		lb.outline_size = 0
	if "double_sided" in lb:
		lb.double_sided = false
	var alto_px = 96.0
	if _fuente:
		alto_px = _fuente.get_height()
	lb.pixel_size = (radio * tamano_numero) / alto_px
	return lb
