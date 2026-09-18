tool
extends Spatial

# ============================================================
# CASETA DE TRANSMISION
# ============================================================
# Misma base que la torre de jueces (patas, piso, cabina cerrada
# con banda de "ventanas", ribete vino tinto, techo), pero con
# una antena en el techo (mastil + cruceta + luz roja) para
# diferenciarla a simple vista de la torre de jueces.
#
# UBICACION: se le pregunta a GestorNivel la meta activa de esta
# carrera (SOLO LECTURA, GestorNivel.gd no se toca) y se calcula
# el punto sobre TrackPath. Tambien gira para mirar hacia la
# pista, y se desengancha sola si el padre esta oculto.
#
# NOTA: en la practica esta caseta suele terminar bien arriba de
# la tribuna principal (vista panoramica de toda la pista, como
# necesita una camara de transmision) - se ubica ahi ajustando
# Alejar De Pista e Invertir Lado.
#
# ------------------------------------------------------------
# VERSION TOOL - QUE CAMBIO Y POR QUE
# ------------------------------------------------------------
# 1) La palabra "tool" hace que el script corra DENTRO del editor.
#    Antes _ready() solo se ejecutaba al apretar Play, y en el
#    editor este nodo era un cascaron vacio.
#
# 2) En el editor la caseta NUNCA se esconde. Antes, si no podia
#    calcular la meta, hacia visible = false. Y en el editor nunca
#    podia calcularla, porque GestorNivel es un autoload que solo
#    existe cuando corre el juego. Resultado: se construia y
#    desaparecia. Ahora siempre se ve.
#
# 3) IMPORTANTE: en el editor el script NO MUEVE NUNCA el nodo.
#    Solo construye la caseta y la deja exactamente donde vos la
#    pusiste.
#
# 3b) Casilla nueva "Ubicacion Automatica":
#     TILDADA (como venia): al arrancar el juego el script calcula
#     la posicion a partir de la meta y de Alejar De Pista, y pisa
#     la posicion que vos le hayas dado a mano. Es el comportamiento
#     de siempre.
#     DESTILDADA: el script no toca la posicion nunca. La caseta se
#     queda donde vos la pusiste, en el editor y en el juego, igual
#     que el Paddock. Es la opcion recomendada ahora que se puede
#     ver en el editor mientras la ubicas.
#
# 4) Ajuste en vivo: al cambiar cualquier valor del Inspector, la
#    caseta se rearma al instante.
#
# 5) El reenganche automatico de padre NO corre en el editor: mover
#    nodos de lugar en el arbol mientras editas es peligroso.
#
# Las piezas se crean sin "owner" a proposito: NO se guardan en el
# archivo de la escena, se regeneran cada vez.
# ============================================================

# --- Patas de apoyo ---
export var altura_patas = 7.0 setget _set_altura_patas
export var ancho_pata = 0.4 setget _set_ancho_pata
export var fondo_pata = 0.4 setget _set_fondo_pata
export var ancho_patas = 4.0 setget _set_ancho_patas
export var fondo_patas = 3.0 setget _set_fondo_patas

# --- Piso de la plataforma ---
export var grosor_piso = 0.3 setget _set_grosor_piso

# --- Cabina cerrada ---
export var ancho_cabina = 4.6 setget _set_ancho_cabina
export var fondo_cabina = 3.2 setget _set_fondo_cabina
export var alto_cabina = 2.6 setget _set_alto_cabina

# --- Banda de ventanas (vidrio oscuro simulado) ---
export var alto_ventanas = 1.3 setget _set_alto_ventanas

# --- Ribete vino tinto en la base de la cabina ---
export var alto_ribete = 0.3 setget _set_alto_ribete

# --- Techo ---
export var alto_techo = 0.35 setget _set_alto_techo

# --- Antena (lo que la distingue de la torre de jueces) ---
export var altura_antena = 4.0 setget _set_altura_antena
export var ancho_antena = 0.25 setget _set_ancho_antena
export var ancho_cruceta = 1.6 setget _set_ancho_cruceta
export var alto_cruceta = 0.15 setget _set_alto_cruceta
export var radio_luz = 0.25 setget _set_radio_luz

# --- Colores ---
export var color_estructura = Color(1.0, 1.0, 1.0) setget _set_color_estructura
export var color_cabina = Color(0.95, 0.95, 0.95) setget _set_color_cabina
export var color_ventanas = Color(0.15, 0.18, 0.22) setget _set_color_ventanas
export var color_ribete = Color(0.48, 0.08, 0.17) setget _set_color_ribete
export var color_antena = Color(0.48, 0.08, 0.17) setget _set_color_antena
export var color_luz = Color(0.85, 0.1, 0.1) setget _set_color_luz

export var sin_sombreado = true setget _set_sin_sombreado

# --- Ubicacion ---
export var alejar_de_pista = 60.0 setget _set_alejar_de_pista
export var offset_sobre_pista = 0.0 setget _set_offset_sobre_pista
export var invertir_lado = false setget _set_invertir_lado
export(NodePath) var camino_pista_path setget _set_camino_pista_path

# Opcional: si el buscador automatico no encuentra la meta en el
# editor, podes asignar aca el nodo de meta a mano.
export(NodePath) var nodo_meta_path setget _set_nodo_meta_path

# TILDADA: el juego calcula la posicion solo (comportamiento viejo).
# DESTILDADA: la caseta se queda donde vos la pongas a mano.
export var ubicacion_automatica = true setget _set_ubicacion_automatica

export var mostrar_diagnostico = true setget _set_mostrar_diagnostico

var _reconstruccion_pedida = false


# ------------------------------------------------------------
# ARRANQUE
# ------------------------------------------------------------
func _ready():
	if not Engine.editor_hint:
		visible = false
	call_deferred("_reconstruir")


# ------------------------------------------------------------
# RECONSTRUCCION
# ------------------------------------------------------------
func _pedir_reconstruccion():
	if not is_inside_tree():
		return
	if _reconstruccion_pedida:
		return
	_reconstruccion_pedida = true
	call_deferred("_reconstruir")


func _reconstruir():
	_reconstruccion_pedida = false
	if not is_inside_tree():
		return
	_borrar_lo_construido()
	_construir_caseta()
	_reubicar_junto_a_la_meta()


func _borrar_lo_construido():
	for hijo in get_children():
		if hijo.name.begins_with("Caseta_"):
			remove_child(hijo)
			hijo.queue_free()


# ------------------------------------------------------------
# CONSTRUCCION VISUAL
# ------------------------------------------------------------
func _construir_caseta():
	_crear_patas()
	_crear_piso()
	_crear_cabina()
	_crear_ventanas()
	_crear_ribete_base()
	_crear_techo()
	_crear_antena()


func _hacer_material(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	material.flags_unshaded = sin_sombreado
	return material


func _crear_caja(nombre, tamano, posicion, color):
	var caja = MeshInstance.new()
	var malla = CubeMesh.new()
	malla.size = tamano
	caja.mesh = malla
	caja.material_override = _hacer_material(color)
	caja.translation = posicion
	caja.name = nombre
	add_child(caja)
	return caja


func _crear_patas():
	var x = ancho_patas / 2.0
	var z = fondo_patas / 2.0
	var y = altura_patas / 2.0
	_crear_caja("Caseta_PataFrenteDer", Vector3(ancho_pata, altura_patas, fondo_pata), Vector3(x, y, z), color_estructura)
	_crear_caja("Caseta_PataFrenteIzq", Vector3(ancho_pata, altura_patas, fondo_pata), Vector3(-x, y, z), color_estructura)
	_crear_caja("Caseta_PataFondoDer", Vector3(ancho_pata, altura_patas, fondo_pata), Vector3(x, y, -z), color_estructura)
	_crear_caja("Caseta_PataFondoIzq", Vector3(ancho_pata, altura_patas, fondo_pata), Vector3(-x, y, -z), color_estructura)


func _crear_piso():
	_crear_caja("Caseta_Piso", Vector3(ancho_cabina, grosor_piso, fondo_cabina), Vector3(0, altura_patas + grosor_piso / 2.0, 0), color_estructura)


func _crear_cabina():
	var y = altura_patas + grosor_piso + alto_cabina / 2.0
	_crear_caja("Caseta_Cabina", Vector3(ancho_cabina, alto_cabina, fondo_cabina), Vector3(0, y, 0), color_cabina)


func _crear_ventanas():
	var y = altura_patas + grosor_piso + alto_cabina - alto_ventanas / 2.0 - 0.15
	_crear_caja("Caseta_Ventanas", Vector3(ancho_cabina * 1.02, alto_ventanas, fondo_cabina * 1.02), Vector3(0, y, 0), color_ventanas)


func _crear_ribete_base():
	var y = altura_patas + grosor_piso + alto_ribete / 2.0
	_crear_caja("Caseta_RibeteBase", Vector3(ancho_cabina * 1.05, alto_ribete, fondo_cabina * 1.05), Vector3(0, y, 0), color_ribete)


func _crear_techo():
	var y = altura_patas + grosor_piso + alto_cabina + alto_techo / 2.0
	_crear_caja("Caseta_Techo", Vector3(ancho_cabina * 1.15, alto_techo, fondo_cabina * 1.15), Vector3(0, y, 0), color_estructura)


func _crear_antena():
	var y_base_techo = altura_patas + grosor_piso + alto_cabina + alto_techo
	var y_mastil = y_base_techo + altura_antena / 2.0
	_crear_caja("Caseta_Antena_Mastil", Vector3(ancho_antena, altura_antena, ancho_antena), Vector3(0, y_mastil, 0), color_antena)

	var y_cruceta = y_base_techo + altura_antena * 0.65
	_crear_caja("Caseta_Antena_Cruceta", Vector3(ancho_cruceta, alto_cruceta, ancho_antena), Vector3(0, y_cruceta, 0), color_antena)

	var esfera = MeshInstance.new()
	var malla_esfera = SphereMesh.new()
	malla_esfera.radius = radio_luz
	malla_esfera.height = radio_luz * 2.0
	esfera.mesh = malla_esfera
	esfera.material_override = _hacer_material(color_luz)
	esfera.translation = Vector3(0, y_base_techo + altura_antena, 0)
	esfera.name = "Caseta_Antena_Luz"
	add_child(esfera)


# ------------------------------------------------------------
# BUSQUEDA DE LA PISTA Y DE LA META
# ------------------------------------------------------------
func _obtener_camino_pista():
	var camino = null

	if camino_pista_path != NodePath(""):
		camino = get_node_or_null(camino_pista_path)
	if camino != null:
		return camino

	camino = get_node_or_null("/root/PistaDeCarrera/TrackPath")
	if camino != null:
		return camino

	# En el editor la escena no cuelga de /root, hay que buscarla.
	var raiz = null
	if Engine.editor_hint:
		raiz = get_tree().edited_scene_root
	if raiz == null:
		raiz = get_tree().current_scene
	if raiz != null:
		camino = raiz.find_node("TrackPath", true, false)

	return camino


# Busca el nodo de meta entre los hijos de TrackPath.
# Sirve en el editor, donde GestorNivel todavia no existe.
func _buscar_nodo_meta():
	if nodo_meta_path != NodePath(""):
		var asignado = get_node_or_null(nodo_meta_path)
		if asignado != null:
			return asignado

	var camino = _obtener_camino_pista()
	if camino == null:
		return null

	for hijo in camino.get_children():
		if "Meta" in hijo.name and "offset" in hijo:
			return hijo

	return null


func _obtener_offset_meta_real() -> float:
	# Camino normal del juego: preguntarle al autoload.
	var gestor = get_node_or_null("/root/GestorNivel")
	if gestor != null:
		if "modo_recta" in gestor and gestor.modo_recta and gestor._meta_recta:
			return gestor._meta_recta.offset
		elif "_meta_ovalo" in gestor and gestor._meta_ovalo:
			return gestor._meta_ovalo.offset

	# Camino del editor: leer el nodo de meta directamente.
	var meta = _buscar_nodo_meta()
	if meta != null:
		if mostrar_diagnostico and Engine.editor_hint:
			print("[BDG-CasetaTransmision] (editor) usando la meta del nodo '", meta.name, "', offset=", meta.offset)
		return meta.offset

	return -1.0


# ------------------------------------------------------------
# UBICACION
# ------------------------------------------------------------
func _reubicar_junto_a_la_meta():
	# En el editor nunca movemos el nodo.
	if Engine.editor_hint:
		visible = true
		if mostrar_diagnostico:
			print("[BDG-CasetaTransmision] (editor) caseta construida. NO muevo el nodo: queda donde vos la pusiste.")
		return

	# Ubicacion manual: el script no toca la posicion tampoco en el juego.
	if not ubicacion_automatica:
		visible = true
		if mostrar_diagnostico:
			print("[BDG-CasetaTransmision] Ubicacion manual activada: respeto la posicion del editor.")
		return

	var camino = _obtener_camino_pista()
	var offset_meta_real = _obtener_offset_meta_real()

	if camino == null or offset_meta_real < 0.0:
		# En el editor NO la escondemos: preferimos verla donde
		# este el nodo antes que no verla en absoluto.
		if Engine.editor_hint:
			visible = true
			if mostrar_diagnostico:
				print("[BDG-CasetaTransmision] (editor) no encontre la pista o la meta. La dejo visible en la posicion del nodo para que la puedas ubicar a mano.")
		else:
			visible = false
			if mostrar_diagnostico:
				print("[BDG-CasetaTransmision] AVISO: no se pudo calcular la meta real, caseta oculta.")
		return

	var offset_caseta = offset_meta_real + offset_sobre_pista
	if offset_caseta < 0.0:
		offset_caseta = 0.0

	var rastreador = PathFollow.new()
	camino.add_child(rastreador)
	rastreador.offset = offset_caseta
	var punto_caseta = rastreador.global_transform.origin
	rastreador.offset = offset_caseta + 1.0
	var punto_adelante = rastreador.global_transform.origin
	camino.remove_child(rastreador)
	rastreador.queue_free()

	var avance = punto_adelante - punto_caseta
	avance.y = 0.0
	if avance.length() < 0.001:
		avance = Vector3(0, 0, -1)
	avance = avance.normalized()

	var lateral = avance.cross(Vector3.UP).normalized()
	if invertir_lado:
		lateral = -lateral
	var pos_mundial = punto_caseta - lateral * alejar_de_pista

	var transformacion = Transform()
	transformacion = transformacion.looking_at(avance, Vector3.UP)
	transformacion.origin = pos_mundial

	# El reenganche de padre solo corre en el juego, nunca en el
	# editor: mover nodos de lugar en el arbol mientras editas
	# puede romper la escena.
	if not Engine.editor_hint:
		var padre_actual = get_parent()
		if padre_actual and "visible" in padre_actual and not padre_actual.visible:
			var abuelo = padre_actual.get_parent()
			if abuelo:
				padre_actual.remove_child(self)
				abuelo.add_child(self)
				if mostrar_diagnostico:
					print("[BDG-CasetaTransmision] Padre oculto detectado (", padre_actual.name, "), reubicada bajo ", abuelo.name)

	global_transform = transformacion
	visible = true

	if mostrar_diagnostico:
		print("[BDG-CasetaTransmision] Ubicada en offset=", offset_caseta, " | posicion=", pos_mundial, " | mirando hacia=", avance)


# ------------------------------------------------------------
# SETTERS
# ------------------------------------------------------------
func _set_altura_patas(valor):
	altura_patas = valor
	_pedir_reconstruccion()


func _set_ancho_pata(valor):
	ancho_pata = valor
	_pedir_reconstruccion()


func _set_fondo_pata(valor):
	fondo_pata = valor
	_pedir_reconstruccion()


func _set_ancho_patas(valor):
	ancho_patas = valor
	_pedir_reconstruccion()


func _set_fondo_patas(valor):
	fondo_patas = valor
	_pedir_reconstruccion()


func _set_grosor_piso(valor):
	grosor_piso = valor
	_pedir_reconstruccion()


func _set_ancho_cabina(valor):
	ancho_cabina = valor
	_pedir_reconstruccion()


func _set_fondo_cabina(valor):
	fondo_cabina = valor
	_pedir_reconstruccion()


func _set_alto_cabina(valor):
	alto_cabina = valor
	_pedir_reconstruccion()


func _set_alto_ventanas(valor):
	alto_ventanas = valor
	_pedir_reconstruccion()


func _set_alto_ribete(valor):
	alto_ribete = valor
	_pedir_reconstruccion()


func _set_alto_techo(valor):
	alto_techo = valor
	_pedir_reconstruccion()


func _set_altura_antena(valor):
	altura_antena = valor
	_pedir_reconstruccion()


func _set_ancho_antena(valor):
	ancho_antena = valor
	_pedir_reconstruccion()


func _set_ancho_cruceta(valor):
	ancho_cruceta = valor
	_pedir_reconstruccion()


func _set_alto_cruceta(valor):
	alto_cruceta = valor
	_pedir_reconstruccion()


func _set_radio_luz(valor):
	radio_luz = valor
	_pedir_reconstruccion()


func _set_color_estructura(valor):
	color_estructura = valor
	_pedir_reconstruccion()


func _set_color_cabina(valor):
	color_cabina = valor
	_pedir_reconstruccion()


func _set_color_ventanas(valor):
	color_ventanas = valor
	_pedir_reconstruccion()


func _set_color_ribete(valor):
	color_ribete = valor
	_pedir_reconstruccion()


func _set_color_antena(valor):
	color_antena = valor
	_pedir_reconstruccion()


func _set_color_luz(valor):
	color_luz = valor
	_pedir_reconstruccion()


func _set_sin_sombreado(valor):
	sin_sombreado = valor
	_pedir_reconstruccion()


func _set_alejar_de_pista(valor):
	alejar_de_pista = valor
	_pedir_reconstruccion()


func _set_offset_sobre_pista(valor):
	offset_sobre_pista = valor
	_pedir_reconstruccion()


func _set_invertir_lado(valor):
	invertir_lado = valor
	_pedir_reconstruccion()


func _set_camino_pista_path(valor):
	camino_pista_path = valor
	_pedir_reconstruccion()


func _set_nodo_meta_path(valor):
	nodo_meta_path = valor
	_pedir_reconstruccion()


func _set_ubicacion_automatica(valor):
	ubicacion_automatica = valor
	_pedir_reconstruccion()


func _set_mostrar_diagnostico(valor):
	mostrar_diagnostico = valor
