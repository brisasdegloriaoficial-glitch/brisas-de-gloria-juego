extends Spatial
# RepartidorCaballos.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Va en un nodo Spatial llamado RepartidorCaballos, hijo del nodo raíz de PistaDeCarrera.
# Al empezar cada carrera reparte los caballos de los rivales:
#   - elige al azar cuáles salen árabes, cuáles Cuarto de Milla y cuáles americanos,
#   - nunca pone dos árabes en carriles vecinos (quedan mezclados),
#   - los Cuarto de Milla reemplazan americanos (no se suman caballos: por el peso),
#   - los Cuarto de Milla salen como punteros velocistas (rapidos al arrancar),
#   - los Ingleses reemplazan americanos y salen como rematadores (atropellan al final),
#   - cada carrera sale una mezcla distinta.
# El caballo del jugador: sale de la RAZA que el jugador escogio en el panel
# UNIFORME (americano si no escogio nada).
# Toma como molde el Caballo_Americano_Completo del jugador (misma altura y giro),
# y esconde el caballo viejo de cada rival.

export(PackedScene) var escena_americano     # arrastra aquí Caballo_Americano_Completo.tscn
export(PackedScene) var escena_arabe         # arrastra aquí Caballo_Arabe_Completo.tscn
export(PackedScene) var escena_cuartomilla   # arrastra aquí Caballo_CuartoMilla.tscn (vacío = no salen)
export(PackedScene) var escena_ingles        # arrastra aquí Caballo_Ingles.tscn (vacío = no salen)
export var cantidad_arabes := 4
export var separar_arabes := true            # nunca dos árabes en carriles vecinos
export var tamano_rival_min := 0.97          # tamaño de los rivales comparado con el jugador (1 = igual)
export var tamano_rival_max := 0.97
export var tamano_arabe := 1.03               # ajuste extra del tamaño de los árabes (1 = como en Prueba_Jockey)
export var girar_arabe := 0.0                # grados, por si el árabe sale mirando para otro lado
export var altura_extra_arabe := -7.5         # + sube, - baja a los árabes (afinar a ojo)
export var cantidad_cuartomilla := 2
export var tamano_cuartomilla := 1.0         # 1 = su tamaño natural (ya viene en su escena)
export var altura_extra_cuartomilla := -1.0  # + sube, - baja a los Cuarto de Milla (afinar a ojo)
export var cuartomilla_punteros := true      # los Cuarto de Milla salen como punteros (rapidos al arrancar)
export var cantidad_ingles := 1
export var tamano_ingles := 1.0              # 1 = su tamaño natural (ya viene en su escena)
export var altura_extra_ingles := -1.0       # + sube, - baja a los Ingleses (afinar a ojo)
export var ingles_rematadores := true        # los Ingleses salen tranquilos y atropellan al final
export var tamano_jugador := 0.8          # 1 = como está; menos de 1 achica al caballo del jugador
export var nombre_pista := "TrackPath"
export var nombre_jugador := "Enrutador_Caballo1"
export var nombre_modelo_jugador := "Caballo_Americano_Completo"
# Donde el panel UNIFORME guarda la raza que escogio el jugador
export var archivo_uniforme := "user://sedas_bdg_v2.cfg"

# ---- Estrategias al azar en cada carrera ----
# Los punteros (salen rapido y aflojan al final) y los rematadores
# (salen lento y atropellan al final) pueden cambiar de estilo cada
# carrera: asi no es siempre el mismo numero el que se va a la punta.
# Los de ritmo constante no cambian.
export var sortear_estilos := false
export var probabilidad_cambiar_estilo := 0.5   # 0.5 = la mitad de las veces cambia
export var velocidad_maxima_puntero := 32.0     # tope de salida para un rematador que pasa a puntero
export var sortear_en_800 := false              # la de 800 m no se toca


var _jinete_jugador = null
var _jockey_jugador = null


func _ready():
	set_process(false)
	randomize()
	call_deferred("_repartir")
	get_tree().create_timer(4.0).connect("timeout", self, "_medir_tamanos")


func _sortear_estilos(pista, jugador):
	if not sortear_estilos:
		return
	if ConfiguracionCarrera and ConfiguracionCarrera.modo_recta and not sortear_en_800:
		return
	for e in pista.get_children():
		if e == jugador or not (e is PathFollow) or not e.name.begins_with("Enrutador_Caballo"):
			continue
		if not ("velocidad_inicial" in e and "velocidad_final" in e):
			continue
		if randf() >= probabilidad_cambiar_estilo:
			continue
		# Se invierten la salida y el final: el puntero pasa a rematador
		# y el rematador pasa a puntero (con un tope para que no se escape).
		var salida : float = e.velocidad_final
		var llegada : float = e.velocidad_inicial
		if salida > velocidad_maxima_puntero:
			salida = velocidad_maxima_puntero
		e.velocidad_inicial = salida
		e.velocidad_final = llegada
		e.velocidad_actual = salida
		e.velocidad_objetivo = salida


func _repartir():
	var pista = get_parent().find_node(nombre_pista, true, false)
	if pista == null:
		push_warning("RepartidorCaballos: no encontré " + nombre_pista)
		return
	var jugador = pista.get_node_or_null(nombre_jugador)
	if jugador == null:
		push_warning("RepartidorCaballos: no encontré " + nombre_jugador)
		return
	_sortear_estilos(pista, jugador)
	# Si en el Inspector se vaciaron las escenas, se cargan solas.
	if escena_americano == null:
		escena_americano = _escena("res://Caballos/Caballo_Americano_Completo.tscn")
	if escena_arabe == null:
		escena_arabe = _escena("res://Caballo_Arabe_Completo.tscn")
	if escena_cuartomilla == null:
		escena_cuartomilla = _escena("res://Caballos/Caballo_CuartoMilla.tscn")
	if escena_ingles == null:
		escena_ingles = _escena("res://Caballos/Caballo_Ingles.tscn")
	var modelo_jugador = jugador.get_node_or_null(nombre_modelo_jugador)
	if modelo_jugador == null or escena_americano == null or escena_arabe == null:
		push_warning("RepartidorCaballos: faltan las escenas o el modelo del jugador.")
		return
	var molde : Transform = modelo_jugador.transform
	# Dónde queda el cuerpo del americano respecto a su propio punto de origen
	var caja = _cuerpo(modelo_jugador)
	var inv_j : Transform = modelo_jugador.global_transform.affine_inverse()
	var centro_local : Vector3 = inv_j.xform(caja.position + caja.size * 0.5)
	var piso_local : Vector3 = inv_j.xform(caja.position)
	var referencia = [centro_local, piso_local.y]

	# Achicar al caballo del jugador sin sacarlo de su sitio (cascos en el piso)
	if tamano_jugador != 1.0:
		var gj : Transform = modelo_jugador.global_transform
		gj.basis = gj.basis.scaled(Vector3(tamano_jugador, tamano_jugador, tamano_jugador))
		modelo_jugador.global_transform = gj
		var cj = _cuerpo(modelo_jugador)
		gj = modelo_jugador.global_transform
		gj.origin.x += (caja.position.x + caja.size.x * 0.5) - (cj.position.x + cj.size.x * 0.5)
		gj.origin.z += (caja.position.z + caja.size.z * 0.5) - (cj.position.z + cj.size.z * 0.5)
		gj.origin.y += caja.position.y - cj.position.y
		modelo_jugador.global_transform = gj

	# Giro y tamaño propios de cada escena (para respetar la proporción entre razas)
	var tmp = escena_americano.instance()
	var raiz_americano : Basis = tmp.transform.basis
	tmp.free()

	# Raza del caballo del jugador (la que escogio en UNIFORME)
	var raza_j := _raza_del_jugador()
	if raza_j != "americano":
		var escena_j = escena_de_raza(raza_j)
		if escena_j != null:
			# Mismo tamano que tendria el americano del jugador en carrera
			var f_j := tamano_jugador * _factor_americano_jugador(modelo_jugador)
			var m_j = _poner_modelo(jugador, escena_j, molde, raiz_americano, raza_j, referencia, f_j)
			_jinete_jugador = _jinete_de(m_j)
			if _jinete_jugador != null:
				_jinete_jugador.latigo_automatico = false
				_jockey_jugador = jugador.get_node_or_null("Jockey")
				set_process(true)

	# Todos los enrutadores, ordenados por carril
	var todos := []
	for c in pista.get_children():
		if c is PathFollow and c.name.begins_with("Enrutador_Caballo"):
			todos.append(c)
	todos.sort_custom(self, "_por_carril")

	var rivales := []
	for i in todos.size():
		if todos[i] != jugador:
			rivales.append(i)

	# Primero los Cuarto de Milla (en carriles de punteros), luego los Ingleses
	# (en carriles de rematadores) y despues los arabes en el resto
	var cuartos := _elegir_cuartomilla(todos, rivales)
	var resto := []
	for i in rivales:
		if not cuartos.has(i):
			resto.append(i)
	var ingleses := _elegir_ingles(todos, resto)
	var resto2 := []
	for i in resto:
		if not ingleses.has(i):
			resto2.append(i)
	var arabes := _elegir_arabes(resto2)
	if cuartomilla_punteros:
		for i in cuartos:
			_hacer_puntero(todos[i])
	if ingles_rematadores:
		for i in ingleses:
			_hacer_rematador(todos[i])
	for i in rivales:
		var raza := "americano"
		var escena = escena_americano
		if arabes.has(i):
			raza = "arabe"
			escena = escena_arabe
		elif cuartos.has(i):
			raza = "cuartomilla"
			escena = escena_cuartomilla
		elif ingleses.has(i):
			raza = "ingles"
			escena = escena_ingles
		_poner_modelo(todos[i], escena, molde, raiz_americano, raza, referencia)


func _por_carril(a, b):
	return a.h_offset < b.h_offset


# Los Cuarto de Milla se eligen primero entre los carriles de punteros
# (los que salen mas rapido de lo que llegan); si no alcanzan, entre los demas.
func _elegir_cuartomilla(todos : Array, rivales : Array) -> Array:
	var r := []
	if escena_cuartomilla == null or cantidad_cuartomilla <= 0:
		return r
	var punteros := []
	var otros := []
	for i in rivales:
		var e = todos[i]
		if "velocidad_inicial" in e and "velocidad_final" in e and e.velocidad_inicial >= e.velocidad_final:
			punteros.append(i)
		else:
			otros.append(i)
	punteros.shuffle()
	otros.shuffle()
	for i in punteros + otros:
		if r.size() >= cantidad_cuartomilla:
			break
		r.append(i)
	return r


# Los Ingleses se eligen primero entre los carriles de rematadores
# (los que llegan mas rapido de lo que salen); si no alcanzan, entre los demas.
func _elegir_ingles(todos : Array, rivales : Array) -> Array:
	var r := []
	if escena_ingles == null or cantidad_ingles <= 0:
		return r
	var rematadores := []
	var otros := []
	for i in rivales:
		var e = todos[i]
		if "velocidad_inicial" in e and "velocidad_final" in e and e.velocidad_inicial < e.velocidad_final:
			rematadores.append(i)
		else:
			otros.append(i)
	rematadores.shuffle()
	otros.shuffle()
	for i in rematadores + otros:
		if r.size() >= cantidad_ingles:
			break
		r.append(i)
	return r


# Si el carril era de puntero, se invierte: sale tranquilo y atropella al final
func _hacer_rematador(e):
	if not ("velocidad_inicial" in e and "velocidad_final" in e):
		return
	if e.velocidad_inicial < e.velocidad_final:
		return
	var salida : float = e.velocidad_final
	var llegada : float = e.velocidad_inicial
	e.velocidad_inicial = salida
	e.velocidad_final = llegada
	e.velocidad_actual = salida
	e.velocidad_objetivo = salida


# Si el carril era de rematador, se invierte: sale rapido y afloja al final
func _hacer_puntero(e):
	if not ("velocidad_inicial" in e and "velocidad_final" in e):
		return
	if e.velocidad_inicial >= e.velocidad_final:
		return
	var salida : float = min(e.velocidad_final, velocidad_maxima_puntero)
	var llegada : float = e.velocidad_inicial
	e.velocidad_inicial = salida
	e.velocidad_final = llegada
	e.velocidad_actual = salida
	e.velocidad_objetivo = salida


func _elegir_arabes(rivales : Array) -> Array:
	var n : int = min(cantidad_arabes, rivales.size())
	for intento in 300:
		var mezcla = rivales.duplicate()
		mezcla.shuffle()
		var elegidos := []
		for i in mezcla:
			if elegidos.size() >= n:
				break
			if separar_arabes and (elegidos.has(i - 1) or elegidos.has(i + 1)):
				continue
			elegidos.append(i)
		if elegidos.size() == n:
			return elegidos
	# Si no se pudieron separar (muy pocos rivales), se eligen sin separar
	var otra = rivales.duplicate()
	otra.shuffle()
	return otra.slice(0, n - 1) if n > 0 else []


func _poner_modelo(enrutador, escena : PackedScene, molde : Transform, raiz_americano : Basis, raza : String, referencia, tamano_fijo := -1.0):
	# Esconder el caballo viejo del rival
	for c in enrutador.get_children():
		if c is Spatial and c.name.begins_with("Caballo"):
			c.visible = false
			_apagar(c)
	var m = escena.instance()
	var t := Transform()
	t.origin = molde.origin
	t.basis = molde.basis * raiz_americano.inverse() * m.transform.basis
	var f := rand_range(tamano_rival_min, tamano_rival_max)
	var f_altura := 1.0
	if tamano_fijo > 0.0:
		f = tamano_fijo
		# la altura extra se afino con el tamano de los rivales
		f_altura = f / max(0.01, (tamano_rival_min + tamano_rival_max) * 0.5)
	if raza == "arabe":
		t.basis = t.basis.rotated(Vector3.UP, deg2rad(girar_arabe))
	t.basis = t.basis.scaled(Vector3(f, f, f))
	m.transform = t
	enrutador.add_child(m)
	if raza == "arabe":
		_ajustar(m, referencia, tamano_arabe, altura_extra_arabe * f_altura)
	elif raza == "cuartomilla":
		_ajustar(m, referencia, tamano_cuartomilla, altura_extra_cuartomilla * f_altura)
	elif raza == "ingles":
		_ajustar(m, referencia, tamano_ingles, altura_extra_ingles * f_altura)
	var med = _huesos(m)
	if med != null:
		print("[Repartidor] ", enrutador.name, " -> ", raza.to_upper() if raza != "americano" else raza, " | cascos en y=", stepify(med[1], 0.01))
	return m


# Pone al árabe o al Cuarto de Milla donde va el cuerpo del americano (versión que dio el tamaño correcto)
func _ajustar(m, referencia, tamano : float, altura_extra : float):
	var centro_local : Vector3 = referencia[0]
	var piso_y : float = referencia[1]
	var g : Transform = m.global_transform
	if tamano != 1.0:
		g.basis = g.basis.scaled(Vector3(tamano, tamano, tamano))
		m.global_transform = g
	var a = _cuerpo(m)
	if a.size == Vector3.ZERO:
		return
	g = m.global_transform
	var meta : Vector3 = g.xform(centro_local)
	var piso : float = g.xform(Vector3(centro_local.x, piso_y, centro_local.z)).y
	g.origin.x += meta.x - (a.position.x + a.size.x * 0.5)
	g.origin.z += meta.z - (a.position.z + a.size.z * 0.5)
	g.origin.y += piso - a.position.y + altura_extra
	m.global_transform = g


# Centro del caballo y altura de su casco más bajo, según los huesos de su esqueleto
func _huesos(n):
	var esq = _esqueleto(n)
	if esq == null or esq.get_bone_count() == 0:
		return null
	var suma = Vector3()
	var bajo = 1e20
	for i in esq.get_bone_count():
		var p = esq.global_transform.xform(esq.get_bone_global_pose(i).origin)
		suma += p
		bajo = min(bajo, p.y)
	return [suma / esq.get_bone_count(), bajo]


# El primer esqueleto que aparece (el del caballo; el del jinete está más adentro)
func _esqueleto(n):
	var cola = [n]
	while cola.size() > 0:
		var x = cola.pop_front()
		if x is Skeleton:
			return x
		for h in x.get_children():
			cola.append(h)
	return null


# La malla más grande de un modelo = el cuerpo del caballo
func _cuerpo(n):
	var mejor = AABB()
	var vol_mejor = 0.0
	for mi in _mallas(n):
		var b = mi.get_transformed_aabb()
		var vol = b.size.x * b.size.y * b.size.z
		if vol > vol_mejor:
			vol_mejor = vol
			mejor = b
	return mejor


func _mallas(n):
	var r = []
	if n is MeshInstance and n.is_visible_in_tree():
		r.append(n)
	for h in n.get_children():
		r += _mallas(h)
	return r
func _medir_tamanos():
	var pista = get_parent().find_node(nombre_pista, true, false)
	if pista == null:
		return
	for c in pista.get_children():
		if c is PathFollow and c.name.begins_with("Enrutador_Caballo"):
			for m in c.get_children():
				if m is Spatial and m.visible and m.name.begins_with("Caballo"):
					var b = _cuerpo(m)
					print("[Tamano] ", c.name, " ", m.name, " alto=", stepify(b.size.y, 0.01), " escala=", stepify(m.global_transform.basis.get_scale().y, 0.001))


# PESO: apaga todo lo que se mueve dentro del caballo escondido (caballo,
# jinete, estribos...), para que no siga trabajando en cada cuadro.
func _apagar(n):
	n.set_process(false)
	n.set_physics_process(false)
	if n is AnimationPlayer:
		n.stop()
	for h in n.get_children():
		_apagar(h)


# La raza que el jugador escogio en el panel UNIFORME.
func _raza_del_jugador() -> String:
	var cfg = ConfigFile.new()
	if cfg.load(archivo_uniforme) != OK:
		return "americano"
	var r = str(cfg.get_value("jugador", "raza", "americano"))
	if escena_de_raza(r) == null:
		return "americano"
	return r


# La escena de cada raza (la usa tambien el probador del panel UNIFORME).
func escena_de_raza(raza : String):
	if raza == "arabe":
		return escena_arabe
	elif raza == "cuartomilla":
		return escena_cuartomilla
	elif raza == "ingles":
		return escena_ingles
	return escena_americano


# El americano del jugador se agranda solo al correr (su perilla Tamano Jugador
# comparada con la de los rivales). Aqui se calcula cuanto, para que el
# caballo de otra raza salga del mismo tamano.
func _factor_americano_jugador(modelo) -> float:
	for n in _con_tamano(modelo):
		var medio : float = (n.tamano_rival_min + n.tamano_rival_max) * 0.5
		if medio > 0.0:
			return n.tamano_jugador / medio
	return 1.0


func _con_tamano(n) -> Array:
	var r = []
	if ("tamano_jugador" in n) and ("tamano_rival_min" in n) and ("tamano_rival_max" in n):
		r.append(n)
	for h in n.get_children():
		r += _con_tamano(h)
	return r


func _jinete_de(n):
	if n == null:
		return null
	if n.has_method("latigazo"):
		return n
	for h in n.get_children():
		var r = _jinete_de(h)
		if r != null:
			return r
	return null


# Latigazo del jugador con su boton, cuando su caballo no es el americano
# (el americano ya lo hace solo). En 800 m no hay latigo.
func _process(_delta):
	if _jinete_jugador == null or not is_instance_valid(_jinete_jugador):
		set_process(false)
		return
	if Input.is_action_just_pressed("latigazo_derecho"):
		var j = _jockey_jugador
		if j == null or not ("modo_arreo_ritmo" in j) or not j.modo_arreo_ritmo:
			_jinete_jugador.latigazo()


func _escena(ruta : String):
	if ResourceLoader.exists(ruta):
		return load(ruta)
	return null
