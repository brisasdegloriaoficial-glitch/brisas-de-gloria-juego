tool
extends Camera

# ============================================================
#  CamaraEnfocarTodo.gd   (Godot 3.5.3)   -- version 2
#
#  Camara de EDITOR. Encuadra todo lo que hay en la escena
#  desde arriba, mirando hacia abajo.
#
#  Se dispara tildando la casilla "Enfocar Ahora" en el Inspector.
#  La casilla se destilda sola: es un boton, no un estado.
#
#  CAMBIO DE ESTA VERSION: el script ahora FIJA el campo de vision
#  de la camara en vez de usar el que tenga el nodo. El nodo tenia
#  un FOV de ~4.5 grados (teleobjetivo extremo), y por eso la
#  camara se iba a 17000 unidades de distancia.
# ============================================================

# Nodo desde el cual medir. Si se deja vacio, mide toda la escena abierta.
export(NodePath) var raiz_a_enfocar = NodePath("")

# Campo de vision que usa la camara. 70 es el valor normal de Godot.
# Mas chico = mas lejos y mas plano. Mas grande = mas cerca y mas abierto.
export(float) var campo_de_vision = 70.0

# Aire extra alrededor del encuadre. 1.0 = justo, 1.15 = un 15% de aire.
export(float) var margen = 1.15

# Relacion de aspecto de la pantalla (16/9 = 1.777, 4/3 = 1.333).
export(float) var relacion_aspecto = 1.777

# Nombres de nodos a ignorar al medir, separados por coma.
# Ejemplo: "Terreno,Cielo"   (util si el piso es gigante y aleja todo)
export(String) var ignorar_por_nombre = ""

# Si esta tildado, no mide los nodos que estan ocultos.
export(bool) var ignorar_ocultos = true

# Casilla-boton. Tildarla ejecuta el encuadre una sola vez.
export(bool) var enfocar_ahora = false setget _set_enfocar_ahora


# ------------------------------------------------------------
#  DISPARADOR
# ------------------------------------------------------------
func _set_enfocar_ahora(valor):
	enfocar_ahora = false
	if not valor:
		return
	_enfocar()
	property_list_changed_notify()


# ------------------------------------------------------------
#  PROCESO PRINCIPAL
# ------------------------------------------------------------
func _enfocar():
	print("======================================")
	print("CamaraEnfocarTodo: EMPEZANDO")

	if not is_inside_tree():
		print("CamaraEnfocarTodo: ERROR - el nodo no esta dentro del arbol.")
		return

	var raiz = _obtener_raiz()
	if raiz == null:
		print("CamaraEnfocarTodo: ERROR - no encontre desde donde medir.")
		return
	print("CamaraEnfocarTodo: midiendo desde el nodo -> ", raiz.name)

	var lista = []
	_juntar_visuales(raiz, lista)
	print("CamaraEnfocarTodo: objetos visuales encontrados -> ", lista.size())

	if lista.size() == 0:
		print("CamaraEnfocarTodo: ERROR - no hay nada visual para medir ahi.")
		print("======================================")
		return

	var minimo = Vector3(INF, INF, INF)
	var maximo = Vector3(-INF, -INF, -INF)
	var medidos = 0

	for visual in lista:
		var caja = visual.get_aabb()
		if caja.size.x <= 0.0 and caja.size.y <= 0.0 and caja.size.z <= 0.0:
			continue
		var t = visual.global_transform
		for i in range(8):
			var punto = t.xform(caja.get_endpoint(i))
			minimo.x = min(minimo.x, punto.x)
			minimo.y = min(minimo.y, punto.y)
			minimo.z = min(minimo.z, punto.z)
			maximo.x = max(maximo.x, punto.x)
			maximo.y = max(maximo.y, punto.y)
			maximo.z = max(maximo.z, punto.z)
		medidos += 1

	print("CamaraEnfocarTodo: objetos realmente medidos -> ", medidos)

	if medidos == 0:
		print("CamaraEnfocarTodo: ERROR - todos los objetos tenian tamano cero.")
		print("======================================")
		return

	var centro = (minimo + maximo) * 0.5
	var tam = maximo - minimo
	print("CamaraEnfocarTodo: centro -> ", centro)
	print("CamaraEnfocarTodo: tamano -> ", tam)

	# --- AQUI ESTA EL ARREGLO: fijamos el campo de vision ---
	var fov_viejo = fov
	projection = Camera.PROJECTION_PERSPECTIVE
	keep_aspect = Camera.KEEP_HEIGHT

	var fov_usado = campo_de_vision
	if fov_usado < 5.0:
		fov_usado = 70.0
	if fov_usado > 170.0:
		fov_usado = 170.0
	fov = fov_usado

	print("CamaraEnfocarTodo: FOV que tenia el nodo -> ", fov_viejo)
	print("CamaraEnfocarTodo: FOV que voy a usar -> ", fov_usado)

	# --- calculo de la distancia necesaria ---
	var mitad_fov = tan(deg2rad(fov_usado) * 0.5)
	if mitad_fov <= 0.0:
		mitad_fov = 0.7

	var distancia_por_z = (tam.z * 0.5) / mitad_fov
	var distancia_por_x = (tam.x * 0.5) / (mitad_fov * max(relacion_aspecto, 0.1))
	var distancia = max(distancia_por_z, distancia_por_x) * max(margen, 1.0)

	if distancia < 1.0:
		distancia = 1.0

	var altura = centro.y + (tam.y * 0.5) + distancia
	var posicion = Vector3(centro.x, altura, centro.z)

	# --- mover la camara ---
	global_transform = Transform(Basis(), posicion)
	look_at(centro, Vector3(0, 0, -1))

	near = 0.5
	far = (distancia + tam.y) * 2.5

	print("CamaraEnfocarTodo: camara movida a -> ", posicion)
	print("CamaraEnfocarTodo: distancia calculada -> ", distancia)
	print("CamaraEnfocarTodo: plano lejano (far) -> ", far)
	print("CamaraEnfocarTodo: LISTO")
	print("======================================")


# ------------------------------------------------------------
#  AYUDANTES
# ------------------------------------------------------------
func _obtener_raiz():
	if raiz_a_enfocar != NodePath("") and has_node(raiz_a_enfocar):
		return get_node(raiz_a_enfocar)

	if Engine.editor_hint:
		var editada = get_tree().edited_scene_root
		if editada != null:
			return editada

	if get_tree().current_scene != null:
		return get_tree().current_scene

	return get_parent()


func _juntar_visuales(nodo, lista):
	if nodo == self:
		return

	if _esta_ignorado(nodo.name):
		return

	if ignorar_ocultos and nodo is Spatial and not nodo.visible:
		return

	if nodo is VisualInstance:
		lista.append(nodo)

	for hijo in nodo.get_children():
		_juntar_visuales(hijo, lista)


func _esta_ignorado(nombre):
	if ignorar_por_nombre.strip_edges() == "":
		return false
	for pedazo in ignorar_por_nombre.split(","):
		var limpio = pedazo.strip_edges()
		if limpio != "" and limpio == nombre:
			return true
	return false
