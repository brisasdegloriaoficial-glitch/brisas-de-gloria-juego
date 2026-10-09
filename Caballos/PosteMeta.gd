extends Spatial

# ============================================================
# POSTE DE META (identidad propia Brisas de Gloria)
# ============================================================
# Columna BLANCA con ribetes vino tinto, la palabra "FINISH"
# escrita en VERTICAL sobre la cara del poste, y en la punta la
# MONEDA BDG con el LOGO REAL del proyecto pegado como textura.
#
# NOTA (sesion "vestir el hipodromo"): se probo sacar el logo y
# dejar solo la moneda de anillos, por si el estilo fotorrealista
# chocaba con las formas planas del resto del juego. Se probo
# en pantalla y quedo PEOR: sin el logo la moneda se lee como un
# circulo generico, sin identidad. Se volvio al logo real. NO
# repetir esa prueba.
#
# TRANSPARENCIA DEL LOGO: el logo se cargaba bien pero se veia un
# CUADRADO NEGRO alrededor de la moneda. Causa: en Godot no
# alcanza con usar un PNG con fondo transparente - hay que
# activarle la transparencia AL MATERIAL, si no el motor ignora
# el canal transparente y lo pinta de negro. Se agregaron
# flags_transparent, alpha_scissor y cull_disabled. (Antes de
# esto se probo tapar el fondo con el disco dorado por detras: no
# funciono, el fondo esta incrustado en la imagen.) La imagen
# usada es la version recortada con fondo transparente, NO el
# .jpeg original.
#
# LETRAS: el poste salia liso porque se usaba TextMesh, que NO
# existe en Godot 3.5.3 (es de Godot 4) - fallaba en silencio.
# Ahora cada letra se dibuja con cajitas 3D. Pendiente menor: la
# "N" se ve algo distorsionada; afinar su patron en
# _mapa_letras() cuando se retome.
#
# COLOR: el poste se veia celeste apagado porque la luz de la
# escena lo oscurecia. Los materiales van en modo "unshaded".
# Destildar "sin_sombreado" para volver atras.
#
# HISTORIAL (para no repetir el camino):
# ARREGLO 1: colgaba de Meta_LLegada, que tiene "Visible"
# apagado a proposito; la visibilidad se hereda, asi que nunca
# aparecia. Se desengancha solo al arrancar.
# ARREGLO 2: Meta_LLegada se re-centra en su propio _ready(), y
# los hijos corren antes que el padre, asi que capturaba la
# posicion VIEJA. Se resolvio con call_deferred.
# ARREGLO 3: no era visibilidad, era POSICION - Meta_LLegada es
# un punto fijo del modo ovalo, pero en modo recta la meta esta
# en otro lado. Ahora se le pregunta a GestorNivel la meta
# activa de ESTA carrera (SOLO LECTURA - GestorNivel.gd sigue
# intocable) y se calcula el punto sobre TrackPath.
# ARREGLO 4: quedaba en el MEDIO de la pista; ahora va al borde
# INTERIOR, ajustable con "alejar_de_pista".
# ============================================================

# --- Medidas de la columna principal ---
export var altura_poste = 14.0
export var ancho_poste = 2.6
export var fondo_poste = 2.6

# --- Base / pedestal de abajo ---
export var altura_base = 3.0
export var ancho_base = 3.8
export var fondo_base = 3.8

# --- Ribetes vino tinto de la columna ---
export var alto_ribete = 0.6
export var cantidad_ribetes = 4

# --- Texto vertical sobre el poste ---
export var texto = "FINISH"
export var grosor_trazo = 0.12
export var alto_letra = 1.4
export var separacion_letras = 1.8

# --- Moneda BDG de la punta ---
export var mostrar_moneda = true
export var tamano_moneda = 4.0
# Grosor del canto dorado de la moneda.
export var grosor_canto = 0.7
# Cuanto del dibujo redondo se usa (1 = hasta el borde de la imagen).
export var recorte_logo = 0.98
# Altura del centro de la moneda desde el piso del poste. Queda justo
# debajo de la cabina de la torre de jueces, sin tapar las letras.
export var altura_moneda = 21.6
# Cuanto se adelanta la moneda hacia la pista, para que quede delante
# de las patas y la cabina de la torre de jueces y se vea entera.
export var adelantar_moneda = 4.5
# Ruta de la imagen del logo dentro del proyecto. Tiene que ser
# la version con FONDO TRANSPARENTE (.png), no el .jpeg.
export var ruta_logo = "res://Caballos/Logo_Moneda_BDG_transparente.png"
# NUEVO - Logo de la moneda en las carreras de ARENA. Si queda vacio,
# la arena usa el mismo logo de la grama.
export var ruta_logo_arena = "res://Caballos/Logo_Moneda_IAPowerTech.png"

# --- Colores ---
export var color_poste = Color(1.0, 1.0, 1.0)
export var color_base = Color(0.95, 0.95, 0.95)
export var color_ribete = Color(0.48, 0.08, 0.17)
export var color_letra = Color(0.48, 0.08, 0.17)
export var color_moneda_dorado = Color(0.91, 0.75, 0.35)
export var color_moneda_vino = Color(0.48, 0.08, 0.17)

export var sin_sombreado = true

# --- Ubicacion ---
export var alejar_de_pista = 20.0
export var invertir_lado = false
export(NodePath) var camino_pista_path
export var mostrar_diagnostico = true


func _ready():
	if mostrar_diagnostico:
		print("[BDG-PosteMeta] _ready() arranco. Padre actual=", get_parent().name)
	_construir_poste()
	call_deferred("_reubicar_en_meta_real")


# ------------------------------------------------------------
# CONSTRUCCION VISUAL
# ------------------------------------------------------------
func _construir_poste():
	_crear_base()
	_crear_columna()
	_crear_ribetes()
	_crear_texto_vertical()
	if mostrar_moneda:
		_crear_moneda_bdg()


func _hacer_material(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	material.flags_unshaded = sin_sombreado
	return material


func _crear_caja(nombre, tamano, posicion_y, color):
	var caja = MeshInstance.new()
	var malla = CubeMesh.new()
	malla.size = tamano
	caja.mesh = malla
	caja.material_override = _hacer_material(color)
	caja.translation = Vector3(0, posicion_y, 0)
	caja.name = nombre
	add_child(caja)
	return caja


func _crear_base():
	_crear_caja("PosteMeta_Base", Vector3(ancho_base, altura_base, fondo_base), altura_base / 2.0, color_base)
	_crear_caja("PosteMeta_BasePie", Vector3(ancho_base * 1.08, alto_ribete, fondo_base * 1.08), alto_ribete / 2.0, color_ribete)
	_crear_caja("PosteMeta_BaseTapa", Vector3(ancho_base * 1.08, alto_ribete, fondo_base * 1.08), altura_base + alto_ribete / 2.0, color_ribete)


func _crear_columna():
	_crear_caja("PosteMeta_Columna", Vector3(ancho_poste, altura_poste, fondo_poste), altura_base + altura_poste / 2.0, color_poste)


func _crear_ribetes():
	var ancho_ribete = ancho_poste * 1.15
	var fondo_ribete = fondo_poste * 1.15
	_crear_caja("PosteMeta_RibeteAbajo", Vector3(ancho_ribete, alto_ribete, fondo_ribete), altura_base + alto_ribete * 1.5, color_ribete)
	_crear_caja("PosteMeta_RibeteArriba", Vector3(ancho_ribete, alto_ribete, fondo_ribete), altura_base + altura_poste - alto_ribete / 2.0, color_ribete)


# ------------------------------------------------------------
# TEXTO VERTICAL (letras dibujadas con bloques 3D)
# ------------------------------------------------------------
func _mapa_letras():
	return {
		"F": ["111", "100", "111", "100", "100"],
		"I": ["111", "010", "010", "010", "111"],
		"N": ["10001", "11001", "10101", "10011", "10001"],
		"S": ["111", "100", "111", "001", "111"],
		"H": ["101", "101", "111", "101", "101"],
		"A": ["111", "101", "111", "101", "101"],
		"L": ["100", "100", "100", "100", "111"],
		"M": ["101", "111", "111", "101", "101"],
		"E": ["111", "100", "111", "100", "111"],
		"T": ["111", "010", "010", "010", "010"],
		"O": ["111", "101", "101", "101", "111"],
		"G": ["111", "100", "101", "101", "111"],
		"R": ["111", "101", "111", "110", "101"],
		"B": ["110", "101", "110", "101", "110"],
		"D": ["110", "101", "101", "101", "110"],
		"C": ["111", "100", "100", "100", "111"],
		"P": ["111", "101", "111", "100", "100"],
		"X": ["101", "101", "010", "101", "101"],
		" ": ["000", "000", "000", "000", "000"]
	}


func _crear_texto_vertical():
	var contenedor = Spatial.new()
	contenedor.name = "PosteMeta_Texto"
	add_child(contenedor)

	var cantidad = texto.length()
	if cantidad == 0:
		return

	# PESO: antes cada cuadrito de cada letra era un objeto aparte (unos
	# 120 dibujos). Ahora todos los cuadritos se juntan en UNA sola pieza:
	# se ve igual y se dibuja una sola vez.
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hubo = false
	var y_arranque = altura_base + altura_poste - 2.0

	for i in range(cantidad):
		var caracter = texto[i].to_upper()
		var y_letra = y_arranque - (i * separacion_letras)
		if _dibujar_letra(st, caracter, y_letra, fondo_poste / 2.0 + grosor_trazo / 2.0, false):
			hubo = true
		if _dibujar_letra(st, caracter, y_letra, -(fondo_poste / 2.0 + grosor_trazo / 2.0), true):
			hubo = true

	if not hubo:
		return
	var letras = MeshInstance.new()
	letras.name = "PosteMeta_Letras"
	letras.mesh = st.commit()
	letras.material_override = _hacer_material(color_letra)
	contenedor.add_child(letras)


func _dibujar_letra(st, caracter, y_centro, z, espejada) -> bool:
	var mapa = _mapa_letras()
	if not mapa.has(caracter):
		return false
	var filas = mapa[caracter]

	var alto_celda = alto_letra / 5.0
	var ancho_celda = alto_celda
	var cubo = CubeMesh.new()
	cubo.size = Vector3(ancho_celda, alto_celda, grosor_trazo)
	var hubo = false

	for fila in range(5):
		var patron = filas[fila]
		for columna in range(patron.length()):
			if patron[columna] != "1":
				continue
			var x = (columna - (patron.length() - 1) / 2.0) * ancho_celda
			if espejada:
				x = -x
			var y = y_centro + (2 - fila) * alto_celda
			st.append_from(cubo, 0, Transform(Basis(), Vector3(x, y, z)))
			hubo = true
	return hubo


# ------------------------------------------------------------
# MONEDA BDG con el LOGO REAL pegado como textura
# ------------------------------------------------------------
func _crear_moneda_bdg():
	var moneda = Spatial.new()
	moneda.name = "PosteMeta_MonedaBDG"
	moneda.translation = Vector3(0, altura_moneda, 0)
	add_child(moneda)

	var grosor = tamano_moneda * 0.18

	var textura = _cargar_logo()
	if textura == null:
		# Respaldo: la moneda de anillos, por si la imagen no carga.
		var disco = MeshInstance.new()
		var malla_disco = CylinderMesh.new()
		malla_disco.height = grosor
		malla_disco.top_radius = tamano_moneda
		malla_disco.bottom_radius = tamano_moneda
		malla_disco.radial_segments = 48
		disco.mesh = malla_disco
		disco.material_override = _hacer_material(color_moneda_dorado)
		disco.rotation_degrees = Vector3(90, 0, 0)
		disco.name = "Moneda_DiscoDorado"
		moneda.add_child(disco)
		_crear_moneda_anillos(moneda, grosor)
		return

	var material_logo = SpatialMaterial.new()
	material_logo.albedo_texture = textura
	material_logo.flags_unshaded = sin_sombreado
	material_logo.params_billboard_mode = SpatialMaterial.BILLBOARD_DISABLED
	# NECESARIO para que se respete el fondo transparente del PNG.
	# Sin esto, Godot ignora el canal transparente y pinta el fondo
	# de negro (se veia un cuadrado oscuro alrededor de la moneda).
	material_logo.flags_transparent = true
	material_logo.params_use_alpha_scissor = true
	material_logo.params_alpha_scissor_threshold = 0.5
	material_logo.params_cull_mode = SpatialMaterial.CULL_DISABLED

	# Cada cara muestra solo su frente, asi el logo se lee al derecho
	# desde la pista y desde el jardin (antes salia espejado).
	material_logo.params_cull_mode = SpatialMaterial.CULL_BACK

	# MONEDA DE VERDAD: un disco redondo (bordes lisos, sin recorte de
	# transparencia) con canto dorado y grosor. La imagen de la cara se
	# cambia en "Ruta Logo" (ahi va el aviso del patrocinante).
	material_logo.flags_transparent = false
	material_logo.params_use_alpha_scissor = false
	# La cara de atras de cada disco queda escondida dentro del canto.
	material_logo.params_cull_mode = SpatialMaterial.CULL_DISABLED

	var canto = MeshInstance.new()
	var malla_canto = CylinderMesh.new()
	malla_canto.top_radius = tamano_moneda
	malla_canto.bottom_radius = tamano_moneda
	malla_canto.height = grosor_canto
	malla_canto.radial_segments = 48
	malla_canto.rings = 1
	canto.mesh = malla_canto
	canto.material_override = _hacer_material(color_moneda_dorado)
	canto.rotation_degrees = Vector3(90, 0, 0)
	canto.name = "Moneda_Canto"
	moneda.add_child(canto)

	var disco = _malla_disco(tamano_moneda * 0.97, 48)
	for i in range(2):
		var cara = MeshInstance.new()
		cara.mesh = disco
		cara.material_override = material_logo
		if i == 0:
			cara.translation = Vector3(0, 0, grosor_canto / 2.0 + 0.2)
			cara.name = "Moneda_Logo"
		else:
			cara.rotation_degrees = Vector3(0, 180, 0)
			cara.translation = Vector3(0, 0, -(grosor_canto / 2.0 + 0.2))
			cara.name = "Moneda_Logo_Atras"
		moneda.add_child(cara)

	if mostrar_diagnostico:
		print("[BDG-PosteMeta] Logo de la moneda cargado desde: ", _ruta_usada)


# Disco plano mirando hacia +Z, con la imagen redonda pegada encima.
func _malla_disco(radio, lados):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r_uv = 0.5 * clamp(recorte_logo, 0.1, 1.0)
	for i in range(lados):
		var a0 = TAU * i / lados
		var a1 = TAU * (i + 1) / lados
		for punto in [[0.0, 0.0], [cos(a0), sin(a0)], [cos(a1), sin(a1)]]:
			st.add_normal(Vector3(0, 0, 1))
			st.add_uv(Vector2(0.5 + punto[0] * r_uv, 0.5 - punto[1] * r_uv))
			st.add_vertex(Vector3(punto[0] * radio, punto[1] * radio, 0))
	return st.commit()


var _ruta_usada = ""

func _cargar_logo():
	var ruta = ruta_logo
	# NUEVO - en la arena va el logo de la arena (si hay uno puesto).
	var config = get_node_or_null("/root/ConfiguracionCarrera")
	if config != null and config.get("pista_arena") == true and ruta_logo_arena != "":
		ruta = ruta_logo_arena
	if ruta == "":
		return null
	_ruta_usada = ruta
	var recurso = load(ruta) if ResourceLoader.exists(ruta) else null
	# Respaldo: el logo oficial, por si la ruta del Inspector esta mal escrita.
	if recurso == null and ResourceLoader.exists("res://Caballos/Logo_BDG.png"):
		recurso = load("res://Caballos/Logo_BDG.png")
	if recurso == null:
		if mostrar_diagnostico:
			print("[BDG-PosteMeta] AVISO: no se pudo cargar el logo en ", ruta,
				". Se usa la moneda de anillos como respaldo.")
		return null
	return recurso


func _crear_moneda_anillos(moneda, grosor):
	var aro = MeshInstance.new()
	var malla_aro = CylinderMesh.new()
	malla_aro.height = grosor * 1.2
	malla_aro.top_radius = tamano_moneda * 0.82
	malla_aro.bottom_radius = tamano_moneda * 0.82
	malla_aro.radial_segments = 48
	aro.mesh = malla_aro
	aro.material_override = _hacer_material(color_moneda_vino)
	aro.rotation_degrees = Vector3(90, 0, 0)
	aro.name = "Moneda_AroVino"
	moneda.add_child(aro)

	var centro = MeshInstance.new()
	var malla_centro = CylinderMesh.new()
	malla_centro.height = grosor * 1.3
	malla_centro.top_radius = tamano_moneda * 0.72
	malla_centro.bottom_radius = tamano_moneda * 0.72
	malla_centro.radial_segments = 48
	centro.mesh = malla_centro
	centro.material_override = _hacer_material(color_moneda_dorado)
	centro.rotation_degrees = Vector3(90, 0, 0)
	centro.name = "Moneda_CentroDorado"
	moneda.add_child(centro)


# ------------------------------------------------------------
# UBICACION SOBRE LA META REAL DE ESTA CARRERA
# ------------------------------------------------------------
func _obtener_camino_pista():
	var camino = null
	if camino_pista_path:
		camino = get_node_or_null(camino_pista_path)
	if not camino:
		camino = get_node_or_null("/root/PistaDeCarrera/TrackPath")
	return camino


func _obtener_offset_meta_real() -> float:
	if not GestorNivel:
		return -1.0
	if GestorNivel.modo_recta and GestorNivel._meta_recta:
		return GestorNivel._meta_recta.offset
	elif GestorNivel._meta_ovalo:
		return GestorNivel._meta_ovalo.offset
	return -1.0


func _reubicar_en_meta_real():
	var padre_original = get_parent()
	if padre_original == null:
		if mostrar_diagnostico:
			print("[BDG-PosteMeta] ERROR: no tiene padre, no se puede reubicar.")
		return

	var camino = _obtener_camino_pista()
	var offset_meta_real = _obtener_offset_meta_real()

	var pos_mundial: Vector3
	var hacia_pista = null
	if camino and offset_meta_real >= 0.0:
		var rastreador = PathFollow.new()
		camino.add_child(rastreador)
		rastreador.offset = offset_meta_real
		var punto_meta = rastreador.global_transform.origin
		rastreador.offset = offset_meta_real + 1.0
		var punto_adelante = rastreador.global_transform.origin
		rastreador.queue_free()

		var avance = punto_adelante - punto_meta
		avance.y = 0.0
		if avance.length() < 0.001:
			avance = Vector3(0, 0, -1)
		avance = avance.normalized()

		var lateral = avance.cross(Vector3.UP).normalized()
		if invertir_lado:
			lateral = -lateral
		pos_mundial = punto_meta - lateral * alejar_de_pista
		hacia_pista = lateral

		if mostrar_diagnostico:
			print("[BDG-PosteMeta] Meta real calculada -> modo_recta=", GestorNivel.modo_recta,
				" | offset_meta_real=", offset_meta_real, " | posicion=", pos_mundial)
	else:
		pos_mundial = global_transform.origin
		if mostrar_diagnostico:
			print("[BDG-PosteMeta] AVISO: no se pudo calcular la meta real (camino encontrado=",
				camino != null, ", offset=", offset_meta_real, "). Se usa la posicion heredada como respaldo.")

	var nuevo_padre = padre_original.get_parent()
	if nuevo_padre:
		padre_original.remove_child(self)
		nuevo_padre.add_child(self)
		global_transform.origin = pos_mundial
		visible = true
		if hacia_pista != null:
			_adelantar_moneda_hacia(hacia_pista)
		if mostrar_diagnostico:
			print("[BDG-PosteMeta] Reubicado -> nuevo padre=", nuevo_padre.name,
				" | posicion final=", global_transform.origin, " | visible=", visible)
	else:
		if mostrar_diagnostico:
			print("[BDG-PosteMeta] ERROR: Meta_LLegada no tiene abuelo, no se pudo reubicar.")


# ------------------------------------------------------------
# Pone la moneda delante de la torre de jueces, mirando a la pista,
# con un brazo vino tinto que la sujeta a la punta de la columna.
# ------------------------------------------------------------
func _adelantar_moneda_hacia(hacia_pista: Vector3):
	var moneda = get_node_or_null("PosteMeta_MonedaBDG")
	if moneda == null:
		return
	var z = hacia_pista.normalized()
	var x = Vector3.UP.cross(z).normalized()
	var base_global = Basis(x, Vector3.UP, z)
	var base_local = global_transform.basis.orthonormalized().inverse() * base_global
	moneda.transform.basis = base_local
	var y_moneda = moneda.translation.y
	var adelante_local = global_transform.basis.orthonormalized().inverse().xform(z)
	moneda.translation = Vector3(0, y_moneda, 0) + adelante_local * adelantar_moneda
	if adelantar_moneda > 0.5:
		var brazo = MeshInstance.new()
		var malla = CubeMesh.new()
		var grosor_brazo = max(tamano_moneda * 0.12, 0.3)
		malla.size = Vector3(grosor_brazo, grosor_brazo, adelantar_moneda)
		brazo.mesh = malla
		brazo.material_override = _hacer_material(color_ribete)
		brazo.name = "PosteMeta_BrazoMoneda"
		add_child(brazo)
		var y_brazo = altura_base + altura_poste - grosor_brazo * 0.5
		brazo.transform.basis = base_local
		brazo.translation = Vector3(0, y_brazo, 0) + adelante_local * (adelantar_moneda * 0.5)
