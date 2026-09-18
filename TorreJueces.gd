tool
extends Spatial

# ============================================================
# TORRE DE JUECES
# ============================================================
# Estructura elevada junto a la meta, desde donde los jueces
# miran la llegada: patas de apoyo, piso, cabina cerrada con una
# banda de "ventanas" (vidrio oscuro sin brillo), ribete vino
# tinto a la base de la cabina, y techo.
#
# ------------------------------------------------------------
# VERSION TOOL - QUE CAMBIO Y POR QUE
# ------------------------------------------------------------
# 1) La palabra "tool" de la primera linea hace que el script
#    corra DENTRO del editor. Antes _ready() solo se ejecutaba al
#    apretar Play, y en el editor este nodo era un cascaron vacio:
#    la torre existia en la carrera pero era invisible mientras
#    editabas.
#
# 2) En el editor el script NO MUEVE NUNCA el nodo. Solo construye
#    la torre y la deja donde vos la pongas.
#    OJO: la posicion guardada de este nodo es (0,0,0), asi que la
#    primera vez va a aparecer en el centro del ovalo. Arrastrala
#    a su lugar y listo.
#
# 3) Casilla "Ubicacion Automatica":
#    TILDADA (como viene): al arrancar el juego el script calcula
#    la posicion a partir de la meta y de Alejar De Pista, y pisa
#    la posicion que le hayas dado a mano. Es el comportamiento
#    de siempre, por eso viene asi.
#    DESTILDADA: el script no toca la posicion nunca, ni en el
#    editor ni en el juego. La torre se queda donde vos la
#    pusiste, igual que el Paddock. Destildala en cuanto la
#    ubiques a mano.
#
# 4) El reenganche automatico de padre (cuando el padre esta
#    oculto) solo corre en el juego: mover nodos de lugar en el
#    arbol mientras editas puede romper la escena.
#
# 5) Ajuste en vivo: al cambiar un valor del Inspector, la torre
#    se rearma al instante.
#
# Las piezas se crean sin "owner" a proposito: NO se guardan en el
# archivo de la escena, se regeneran cada vez. Por eso no ensucian
# el .tscn ni se acumulan.
#
# offset_sobre_pista permite correrla un poco antes o despues de
# la linea de meta exacta, sin tocar la ubicacion de la meta en
# si - por ejemplo, si la cabina llega a tapar la vista de la
# camara de llegada, se corrige con este valor.
#
# Esta es la torre de JUECES; la de transmision es una estructura
# aparte (CasetaTransmision.gd).
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

# --- Colores ---
export var color_estructura = Color(1.0, 1.0, 1.0) setget _set_color_estructura
export var color_cabina = Color(0.95, 0.95, 0.95) setget _set_color_cabina
export var color_ventanas = Color(0.15, 0.18, 0.22) setget _set_color_ventanas
export var color_ribete = Color(0.48, 0.08, 0.17) setget _set_color_ribete

export var sin_sombreado = true setget _set_sin_sombreado

# --- Ubicacion ---
# TILDADA: el juego calcula la posicion solo (comportamiento viejo).
# DESTILDADA: la torre se queda donde vos la pongas a mano.
export var ubicacion_automatica = true setget _set_ubicacion_automatica

export var alejar_de_pista = 60.0 setget _set_alejar_de_pista
export var offset_sobre_pista = 0.0 setget _set_offset_sobre_pista
export var invertir_lado = false setget _set_invertir_lado
export(NodePath) var camino_pista_path setget _set_camino_pista_path
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
	_construir_torre()
	_reubicar_junto_a_la_meta()


func _borrar_lo_construido():
	for hijo in get_children():
		if hijo.name.begins_with("Torre_"):
			remove_child(hijo)
			hijo.queue_free()


# ------------------------------------------------------------
# CONSTRUCCION VISUAL
# ------------------------------------------------------------
func _construir_torre():
	_crear_patas()
	_crear_piso()
	_crear_cabina()
	_crear_ventanas()
	_crear_ribete_base()
	_crear_techo()


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
	_crear_caja("Torre_PataFrenteDer", Vector3(ancho_pata, altura_patas, fondo_pata), Vector3(x, y, z), color_estructura)
	_crear_caja("Torre_PataFrenteIzq", Vector3(ancho_pata, altura_patas, fondo_pata), Vector3(-x, y, z), color_estructura)
	_crear_caja("Torre_PataFondoDer", Vector3(ancho_pata, altura_patas, fondo_pata), Vector3(x, y, -z), color_estructura)
	_crear_caja("Torre_PataFondoIzq", Vector3(ancho_pata, altura_patas, fondo_pata), Vector3(-x, y, -z), color_estructura)


func _crear_piso():
	_crear_caja("Torre_Piso", Vector3(ancho_cabina, grosor_piso, fondo_cabina), Vector3(0, altura_patas + grosor_piso / 2.0, 0), color_estructura)


func _crear_cabina():
	var y = altura_patas + grosor_piso + alto_cabina / 2.0
	_crear_caja("Torre_Cabina", Vector3(ancho_cabina, alto_cabina, fondo_cabina), Vector3(0, y, 0), color_cabina)


func _crear_ventanas():
	var y = altura_patas + grosor_piso + alto_cabina - alto_ventanas / 2.0 - 0.15
	_crear_caja("Torre_Ventanas", Vector3(ancho_cabina * 1.02, alto_ventanas, fondo_cabina * 1.02), Vector3(0, y, 0), color_ventanas)


func _crear_ribete_base():
	var y = altura_patas + grosor_piso + alto_ribete / 2.0
	_crear_caja("Torre_RibeteBase", Vector3(ancho_cabina * 1.05, alto_ribete, fondo_cabina * 1.05), Vector3(0, y, 0), color_ribete)


func _crear_techo():
	var y = altura_patas + grosor_piso + alto_cabina + alto_techo / 2.0
	_crear_caja("Torre_Techo", Vector3(ancho_cabina * 1.15, alto_techo, fondo_cabina * 1.15), Vector3(0, y, 0), color_estructura)


# ------------------------------------------------------------
# UBICACION JUNTO A LA META REAL DE ESTA CARRERA
# ------------------------------------------------------------
func _obtener_camino_pista():
	var camino = null
	if camino_pista_path != NodePath(""):
		camino = get_node_or_null(camino_pista_path)
	if camino == null:
		camino = get_node_or_null("/root/PistaDeCarrera/TrackPath")
	return camino


func _obtener_offset_meta_real() -> float:
	# Se busca el autoload por ruta y no por su nombre global: asi
	# el script no da error al compilarse dentro del editor, donde
	# GestorNivel todavia no existe.
	var gestor = get_node_or_null("/root/GestorNivel")
	if gestor == null:
		return -1.0
	if "modo_recta" in gestor and gestor.modo_recta and gestor._meta_recta:
		return gestor._meta_recta.offset
	elif "_meta_ovalo" in gestor and gestor._meta_ovalo:
		return gestor._meta_ovalo.offset
	return -1.0


func _reubicar_junto_a_la_meta():
	# En el editor nunca movemos el nodo.
	if Engine.editor_hint:
		visible = true
		if mostrar_diagnostico:
			print("[BDG-TorreJueces] (editor) torre construida. NO muevo el nodo: queda donde vos la pusiste.")
		return

	# Ubicacion manual: tampoco la movemos en el juego.
	if not ubicacion_automatica:
		visible = true
		if mostrar_diagnostico:
			print("[BDG-TorreJueces] Ubicacion manual activada: respeto la posicion del editor.")
		return

	var camino = _obtener_camino_pista()
	var offset_meta_real = _obtener_offset_meta_real()

	if camino == null or offset_meta_real < 0.0:
		visible = false
		if mostrar_diagnostico:
			print("[BDG-TorreJueces] AVISO: no se pudo calcular la meta real, torre oculta.")
		return

	var offset_torre = offset_meta_real + offset_sobre_pista
	if offset_torre < 0.0:
		offset_torre = 0.0

	var rastreador = PathFollow.new()
	camino.add_child(rastreador)
	rastreador.offset = offset_torre
	var punto_torre = rastreador.global_transform.origin
	rastreador.offset = offset_torre + 1.0
	var punto_adelante = rastreador.global_transform.origin
	camino.remove_child(rastreador)
	rastreador.queue_free()

	var avance = punto_adelante - punto_torre
	avance.y = 0.0
	if avance.length() < 0.001:
		avance = Vector3(0, 0, -1)
	avance = avance.normalized()

	var lateral = avance.cross(Vector3.UP).normalized()
	if invertir_lado:
		lateral = -lateral
	var pos_mundial = punto_torre - lateral * alejar_de_pista

	var transformacion = Transform()
	transformacion = transformacion.looking_at(avance, Vector3.UP)
	transformacion.origin = pos_mundial

	# Si el padre actual esta oculto (por ejemplo Meta_LLegada, que
	# tiene Visible = false a proposito), la torre hereda esa
	# invisibilidad sin importar su propio "visible". Se desengancha
	# un nivel hacia arriba.
	var padre_actual = get_parent()
	if padre_actual and "visible" in padre_actual and not padre_actual.visible:
		var abuelo = padre_actual.get_parent()
		if abuelo:
			padre_actual.remove_child(self)
			abuelo.add_child(self)
			if mostrar_diagnostico:
				print("[BDG-TorreJueces] Padre oculto detectado (", padre_actual.name, "), reubicada bajo ", abuelo.name)

	global_transform = transformacion
	visible = true

	if mostrar_diagnostico:
		print("[BDG-TorreJueces] Ubicada en offset=", offset_torre, " | posicion=", pos_mundial, " | mirando hacia=", avance)


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


func _set_sin_sombreado(valor):
	sin_sombreado = valor
	_pedir_reconstruccion()


func _set_ubicacion_automatica(valor):
	ubicacion_automatica = valor
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


func _set_mostrar_diagnostico(valor):
	mostrar_diagnostico = valor
