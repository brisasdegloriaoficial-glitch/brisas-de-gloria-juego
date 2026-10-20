extends Node
# GestorRed_1Vs1.gd  -  Godot 3.5.3  -  Brisas de Gloria
# VERSION 20-oct (noche, 3): el pelaje del otro jugador ya se pinta aunque
#   Pelajes ya haya pintado ese caballo (en el telefono salia alazan).
# (antes) 20-oct noche, 2: cada jugador se ve con su raza y su pelaje (antes
#   salia con el caballo y el color del rival que le tocaba). En Windows, al
#   crear la carrera, le pide permiso a Windows una sola vez para que los
#   demas puedan entrar (el firewall no los dejaba).
# (antes) 20-oct noche: hasta 12 jugadores en la misma wifi, CON IA o SIN IA,
#   y cada jugador se ve con su uniforme. PAUSAR se esconde (no se oscurece).
# (antes) 20-oct tarde: el boton 1 VS 1 va debajo de la lista de distancias.
# (antes) 20-oct: carrera 1 VS 1 en la misma wifi (primera parte).
#
# Va como AutoLoad con la escena GestorRed_1Vs1.tscn. Asi se ajusta todo
# desde el Inspector abriendo esa escena.
#
# COMO FUNCIONA
# - En la pantalla de inicio sale el boton "1 VS 1", debajo de la 1900.
# - El que pulsa CREAR CARRERA manda (el anfitrion): escoge la distancia,
#   la dificultad y si se corre CON IA o SIN IA. Los demas pulsan UNIRSE.
# - Pueden entrar hasta 12 jugadores. CON IA, los puestos que faltan los
#   llenan caballos de la maquina. SIN IA, corren solo los jugadores.
# - Cada uno corre su caballo con sus controles y ve a los demas con su
#   uniforme. Los caballos de la maquina los mueve el anfitrion.
# - En la carrera en grupo no se guarda el avance de niveles, y PAUSAR se
#   esconde (si uno pausa, se descuadra la carrera de los demas).
#
# SIN IA: los caballos de la maquina siguen corriendo escondidos fuera de
# la pista, sin chocar ni contar en la llegada. Hacen falta porque tu
# caballo toma su ritmo del ritmo del lote (asi esta graduada la dificultad).
#
# No cambia nada del juego normal: si nadie pulsa 1 VS 1, todo sigue igual.

# ============================================================
# CONEXION
# ============================================================
export var puerto_juego = 45100
export var puerto_busqueda = 45101
# Posiciones que se mandan por segundo. Mas = mas fino, pero carga mas.
export var envios_por_segundo = 20
# Cuantos jugadores pueden entrar, contando al que crea la carrera.
export var maximo_jugadores = 12
# En Windows, al crear la carrera la primera vez, le pide permiso a Windows
# (sale la ventanita de "Si / No") para que el firewall deje entrar a los
# demas jugadores. Solo se hace una vez por computadora.
export var abrir_firewall_en_windows = true

# ============================================================
# SUAVIDAD DE LOS CABALLOS QUE LLEGAN POR LA RED
# ============================================================
# Mas alto = sigue mas pegado a lo que llega; mas bajo = mas suave.
export var suavizado_posicion = 8.0
export var suavizado_carril = 12.0
# Segundos que puede adivinar hacia adelante si un dato llega tarde.
export var adelanto_maximo = 0.25
# Si se descuadra mas que esto, lo pone en su sitio de una vez.
export var salto_maximo = 40.0
# SIN IA: carril donde corren escondidos los caballos de la maquina
# (bien lejos de la pista, para que no choquen con nadie).
export var carril_fantasma = -1500.0

# ============================================================
# BOTONES Y AVISOS
# ============================================================
export var archivo_fuente = "res://FuenteBDG.tres"
export var texto_boton = "1 VS 1"
export var texto_con_ia = "CON IA"
export var texto_sin_ia = "SIN IA"
# El boton va debajo de la lista de distancias (debajo de la 1900),
# con el mismo ancho que esos botones. Desmarcado = va donde diga
# Posicion Boton.
export var boton_debajo_de_distancias = true
export var separacion_debajo = 6
# Separacion entre el boton 1 VS 1 y el de CON IA / SIN IA (a su derecha).
export var separacion_boton_ia = 8
# 0 = izquierda/arriba, 1 = derecha/abajo (solo si el de arriba esta desmarcado).
export var posicion_boton = Vector2(0.88, 0.55)
export var tamano_boton = Vector2(190, 48)
export var tamano_texto_boton = 26
export var tamano_texto_panel = 24
export var tamano_texto_aviso = 24
export var posicion_aviso = Vector2(0.5, 0.74)
export var color_texto = Color("ffd955")
export var color_fondo = Color("0f0f14")
export var color_borde = Color("ffd955")
export var color_aviso = Color("ffd955")
export var segundos_aviso_temporal = 4.0

const VERSION = 2
const NADA = 0
const ANFITRION = 1
const INVITADO = 2
const SEDAS = ["color_1", "color_2", "diseno_cuerpo", "diseno_mangas", "mangas_color_2", "cantidad_diseno", "color_casco"]

var _rol = NADA
var _conectado = false          # invitado: ya entro a la carrera del anfitrion
var _mi_numero = 1              # mi caballo en la pista del anfitrion (el anfitrion es el 1)
var _id_carrera = 0
var _con_ia = true
var _humanos = [1]              # caballos (del anfitrion) que manejan jugadores
var _numero_de_peer = {}        # anfitrion: conexion -> caballo
var _listos = {}                # anfitrion: conexion -> carrera que ya cargo
var _cfg = {}
var _puestos_invitado = {}
var _nivel_previo = 0
var _remotos = {}
var _nodos = {}                 # numero en esta pista -> Enrutador_CaballoN
var _fantasmas = []
var _apagados = {}
var _recorrido_previo = {}
var _sedas = {}                 # caballo (del anfitrion) -> uniforme
var _sedas_puestas = {}
var _t_revisar_sedas = 0.0
var _ultimas_sedas = {}
var _seguir_lote_original = null
var _rechazando = false
var _t_envio = 0.0
var _espera_escena = 0
var _escena_lista = false
var _id_escena = 0
var _udp_anuncio = null
var _udp_escucha = null
var _t_anuncio = 0.0
var _encontrados = []
var _ips_texto = ""

var _capa = null
var _boton_1vs1 = null
var _boton_ia = null
var _panel = null
var _label_estado = null
var _caja_unirse = null
var _lista_encontrados = null
var _campo_ip = null
var _aviso = null
var _mensaje_temporal = ""
var _t_temporal = 0.0
var _fuente_base = null


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	# Corre despues de que todos se movieron y del control de choques
	# (Jockey va en 90), y antes de dibujar caballos y jinetes (van en 100).
	process_priority = 95
	var arbol = get_tree()
	arbol.connect("node_added", self, "_al_entrar_nodo")
	arbol.connect("network_peer_connected", self, "_al_conectar_peer")
	arbol.connect("network_peer_disconnected", self, "_al_desconectar_peer")
	arbol.connect("connected_to_server", self, "_al_conectar_servidor")
	arbol.connect("connection_failed", self, "_al_fallar_conexion")
	arbol.connect("server_disconnected", self, "_al_perder_servidor")
	_crear_interfaz()


# ============================================================
# CADA CUADRO
# ============================================================
func _process(delta):
	_revisar_escena_nueva()
	if _espera_escena > 0:
		_espera_escena -= 1
		if _espera_escena == 0:
			_escena_lista = true
			_al_quedar_lista_la_escena()
	_buscar_anfitriones()
	_anunciar(delta)
	_actualizar_pantalla_inicio()
	_actualizar_interfaz(delta)
	if _rol == NADA or not _escena_lista:
		return
	_aplicar_remotos(delta)
	_mantener_fantasmas()
	_poner_sedas_pendientes()
	_revisar_mis_sedas(delta)
	if not _hay_red():
		return
	_t_envio += delta
	if envios_por_segundo > 0 and _t_envio >= 1.0 / float(envios_por_segundo):
		_t_envio = 0.0
		_enviar_estado()


func _hay_red():
	if _rol == ANFITRION:
		return not _numero_de_peer.empty()
	return _rol == INVITADO and _conectado and not _cfg.empty()


# ============================================================
# CARRERA NUEVA (al escoger distancia, REINICIAR, JUGAR OTRA VEZ...)
# ============================================================
# Esto corre justo cuando entra la carrera nueva, antes de que los
# caballos se armen.
func _al_entrar_nodo(nodo):
	if _rol == NADA or nodo != get_tree().current_scene:
		return
	# En la carrera en grupo siempre se pasa por la pantalla de CORRER:
	# JUGAR OTRA VEZ no arranca solo, porque hay que esperar a los demas.
	if get_tree().has_meta("jugar_otra_vez"):
		get_tree().remove_meta("jugar_otra_vez")
	if _rol == INVITADO and not _puestos_invitado.empty() and GestorNivel:
		# Las mismas casillas del anfitrion, antes de que los caballos las lean.
		GestorNivel._puesto_de = _puestos_invitado.duplicate()
		GestorNivel._escena_del_sorteo = nodo.get_instance_id()


# Cuando cambia la carrera, espera 3 cuadros a que se arme todo.
func _revisar_escena_nueva():
	var raiz = get_tree().current_scene
	var id = raiz.get_instance_id() if raiz else 0
	if id == _id_escena:
		return
	_id_escena = id
	_remotos.clear()
	_nodos.clear()
	_fantasmas.clear()
	_apagados.clear()
	_recorrido_previo.clear()
	_sedas_puestas.clear()
	_seguir_lote_original = null
	_escena_lista = false
	_espera_escena = 3
	if _rol == ANFITRION:
		_id_carrera += 1


func _al_quedar_lista_la_escena():
	var camino = _camino()
	if camino:
		for n in range(1, _contar_caballos(camino) + 1):
			_nodos[n] = camino.get_node_or_null("Enrutador_Caballo%d" % n)
	if _rol == NADA:
		return
	_aplicar_fantasmas()
	_ultimas_sedas = _sedas_propias()
	if _rol == ANFITRION:
		_sedas[1] = _ultimas_sedas
		_enviar_config_a_todos()
		_enviar_sedas_a_todos()
	elif _rol == INVITADO and _conectado and not _cfg.empty():
		rpc_id(1, "_r_listo", _id_carrera)
		rpc_id(1, "_r_mis_sedas", _ultimas_sedas)


# ============================================================
# ANFITRION -> INVITADOS: la carrera que se va a correr
# ============================================================
func _config_para(numero):
	var puestos = {}
	if GestorNivel:
		var c1 = _nodos.get(1)
		if c1 and is_instance_valid(c1) and GestorNivel.has_method("obtener_puesto"):
			# Hace el sorteo de casillas si todavia no se hizo.
			GestorNivel.obtener_puesto(c1)
		puestos = GestorNivel._puesto_de.duplicate()
	return {
		"version": VERSION,
		"id": _id_carrera,
		"numero": numero,
		"humanos": _humanos.duplicate(),
		"con_ia": _con_ia,
		"distancia_metros": ConfiguracionCarrera.distancia_metros,
		"modo_recta": ConfiguracionCarrera.modo_recta,
		"modo_vuelta_completa": ConfiguracionCarrera.modo_vuelta_completa,
		"pista_arena": ConfiguracionCarrera.pista_arena,
		"arreo_limite": ConfiguracionCarrera.arreo_limite,
		"estamina_base": ConfiguracionCarrera.estamina_base,
		"distancia_elegida": ConfiguracionCarrera.distancia_elegida,
		"nivel": GestorNivel.nivel_actual if GestorNivel else 1,
		"puestos": puestos,
	}


func _enviar_config_a(peer):
	if _rol != ANFITRION or not _escena_lista or not _numero_de_peer.has(peer):
		return
	rpc_id(peer, "_r_config", _config_para(_numero_de_peer[peer]))


func _enviar_config_a_todos():
	for peer in _numero_de_peer.keys():
		_enviar_config_a(peer)


remote func _r_config(cfg):
	if _rol != INVITADO or get_tree().get_rpc_sender_id() != 1:
		return
	if int(cfg.get("version", 0)) != VERSION:
		_salir("EL OTRO JUGADOR TIENE OTRA VERSIÓN DEL JUEGO")
		return
	_cfg = cfg
	_id_carrera = int(cfg.get("id", 0))
	_mi_numero = int(cfg.get("numero", 2))
	_humanos = cfg.get("humanos", [1, _mi_numero])
	_con_ia = cfg.get("con_ia", true)
	ConfiguracionCarrera.distancia_metros = cfg.get("distancia_metros", ConfiguracionCarrera.distancia_metros)
	ConfiguracionCarrera.modo_recta = cfg.get("modo_recta", false)
	ConfiguracionCarrera.modo_vuelta_completa = cfg.get("modo_vuelta_completa", false)
	ConfiguracionCarrera.pista_arena = cfg.get("pista_arena", false)
	ConfiguracionCarrera.arreo_limite = cfg.get("arreo_limite", ConfiguracionCarrera.arreo_limite)
	ConfiguracionCarrera.estamina_base = cfg.get("estamina_base", ConfiguracionCarrera.estamina_base)
	ConfiguracionCarrera.distancia_elegida = cfg.get("distancia_elegida", true)
	if GestorNivel:
		GestorNivel.nivel_de_prueba = int(cfg.get("nivel", 1))
		GestorNivel.derrotas_seguidas = 0
	_puestos_invitado = _cambiar_puestos(cfg.get("puestos", {}))
	_escena_lista = false
	_espera_escena = 0
	_remotos.clear()
	get_tree().call_deferred("reload_current_scene")


# En mi pista, mi caballo es el 1. Se cambian mis casillas con las del
# caballo 1 del anfitrion para que cada uno quede donde le toco.
func _cambiar_puestos(p):
	var r = {}
	for nombre in p.keys():
		r[nombre] = p[nombre]
	var mio = "Enrutador_Caballo%d" % _mi_numero
	if p.has("Enrutador_Caballo1") and p.has(mio):
		r["Enrutador_Caballo1"] = p[mio]
		r[mio] = p["Enrutador_Caballo1"]
	return r


# Caballo en la pista del anfitrion <-> caballo en mi pista (se cambian
# el 1 y el mio; los demas quedan igual). Sirve para los dos lados.
func _local(n):
	if _rol != INVITADO or _mi_numero == 1:
		return n
	if n == _mi_numero:
		return 1
	if n == 1:
		return _mi_numero
	return n


remote func _r_listo(id):
	if _rol != ANFITRION:
		return
	var peer = get_tree().get_rpc_sender_id()
	if _numero_de_peer.has(peer):
		_listos[peer] = int(id)


func _todos_listos():
	if _numero_de_peer.empty():
		return false
	for peer in _numero_de_peer.keys():
		if _listos.get(peer, -1) != _id_carrera:
			return false
	return true


func _cuantos_listos():
	var n = 0
	for peer in _numero_de_peer.keys():
		if _listos.get(peer, -1) == _id_carrera:
			n += 1
	return n


# Avisa a todos quienes son jugadores y si se corre CON IA o SIN IA.
func _enviar_humanos():
	if _rol == ANFITRION and not _numero_de_peer.empty():
		rpc("_r_humanos", _humanos, _con_ia)


remote func _r_humanos(humanos, con_ia):
	if _rol != INVITADO or get_tree().get_rpc_sender_id() != 1:
		return
	_humanos = humanos
	_con_ia = con_ia
	if _escena_lista and not _cfg.empty():
		_aplicar_fantasmas()


# ============================================================
# CORRER: arrancan todos juntos
# ============================================================
func _al_pulsar_correr():
	if _rol == ANFITRION and not _numero_de_peer.empty():
		rpc("_r_arrancar", _id_carrera)


remote func _r_arrancar(id):
	if _rol != INVITADO or get_tree().get_rpc_sender_id() != 1 or int(id) != _id_carrera:
		return
	var pantalla = _pantalla_inicio()
	if pantalla and pantalla.has_method("_iniciar_cuenta"):
		pantalla._iniciar_cuenta()


# ============================================================
# POSICIONES DURANTE LA CARRERA
# ============================================================
func _enviar_estado():
	var ahora = OS.get_ticks_msec() / 1000.0
	if _rol == ANFITRION:
		var datos = PoolRealArray()
		for n in range(1, _nodos.size() + 1):
			var e = _nodos.get(n)
			if e and is_instance_valid(e):
				datos.append(e.offset)
				datos.append(e.h_offset)
			else:
				datos.append(-1.0)
				datos.append(0.0)
		rpc_unreliable("_r_estado_anfitrion", _id_carrera, ahora, datos)
	elif _rol == INVITADO:
		var c1 = _nodos.get(1)
		if c1 and is_instance_valid(c1):
			rpc_unreliable_id(1, "_r_estado_invitado", _id_carrera, ahora, c1.offset, c1.h_offset)


remote func _r_estado_anfitrion(id, t, datos):
	if _rol != INVITADO or get_tree().get_rpc_sender_id() != 1:
		return
	if _cfg.empty() or int(id) != _id_carrera or not _escena_lista:
		return
	for i in range(datos.size() / 2):
		var n_anfitrion = i + 1
		if n_anfitrion == _mi_numero or datos[i * 2] < 0.0:
			continue
		_guardar_estado(_local(n_anfitrion), t, datos[i * 2], datos[i * 2 + 1])


remote func _r_estado_invitado(id, t, off, h):
	if _rol != ANFITRION or int(id) != _id_carrera or not _escena_lista:
		return
	var peer = get_tree().get_rpc_sender_id()
	if _numero_de_peer.has(peer):
		_guardar_estado(_numero_de_peer[peer], t, off, h)


func _guardar_estado(n, t, off, h):
	var ahora = OS.get_ticks_msec() / 1000.0
	var s = _remotos.get(n)
	if s == null:
		_remotos[n] = {"off": off, "h": h, "t": t, "vel": 0.0, "llegada": ahora,
			"ver_off": off, "ver_h": h, "listo": false}
		return
	if t <= s["t"]:
		return
	var largo = _largo()
	var dt = t - s["t"]
	if dt > 0.001:
		var d = off - s["off"]
		if largo > 0.0:
			d = _envolver(d, largo)
		s["vel"] = clamp(d / dt, -20.0, 90.0)
	s["off"] = off
	s["h"] = h
	s["t"] = t
	s["llegada"] = ahora


# Pone cada caballo que llega por la red en su sitio, suave y sin saltos.
func _aplicar_remotos(delta):
	if _remotos.empty():
		return
	var largo = _largo()
	var ahora = OS.get_ticks_msec() / 1000.0
	var amortiguar = exp(-suavizado_posicion * delta)
	var paso_carril = clamp(suavizado_carril * delta, 0.0, 1.0)
	for n in _remotos.keys():
		var c = _nodos.get(n)
		if c == null or not is_instance_valid(c):
			continue
		var s = _remotos[n]
		var edad = clamp(ahora - s["llegada"], 0.0, adelanto_maximo)
		var meta = s["off"] + s["vel"] * edad
		if not s["listo"]:
			s["ver_off"] = meta
			s["ver_h"] = s["h"]
			s["listo"] = true
		else:
			var diferencia = s["ver_off"] + s["vel"] * delta - meta
			if largo > 0.0:
				diferencia = _envolver(diferencia, largo)
			if abs(diferencia) > salto_maximo:
				diferencia = 0.0
			s["ver_off"] = meta + diferencia * amortiguar
			s["ver_h"] = lerp(s["ver_h"], s["h"], paso_carril)
		var o = s["ver_off"]
		if largo > 0.0:
			o = fposmod(o, largo)
		c.offset = o
		c.h_offset = s["ver_h"]
		# El mismo arreglo de rumbo que usa cada rival en la costura del ovalo.
		if c.has_method("_corregir_rumbo"):
			c._corregir_rumbo()


func _envolver(d, largo):
	return fposmod(d + largo * 0.5, largo) - largo * 0.5


# ============================================================
# SIN IA: los caballos de la maquina corren escondidos
# ============================================================
func _aplicar_fantasmas():
	for n in _nodos.keys():
		var nodo = _nodos[n]
		if nodo == null or not is_instance_valid(nodo):
			continue
		var es_jugador = _humanos.has(_local(n))
		if not _con_ia and not es_jugador:
			_hacer_fantasma(nodo)
		else:
			_quitar_fantasma(nodo)
	# La camara de partida sigue a todo el lote: sin IA, que siga solo a los jugadores.
	var raiz = get_tree().current_scene
	var camara = raiz.get_node_or_null("Camara_de_Partida") if raiz else null
	if camara and ("seguir_a_todo_el_lote" in camara):
		if _seguir_lote_original == null:
			_seguir_lote_original = camara.seguir_a_todo_el_lote
		camara.seguir_a_todo_el_lote = _seguir_lote_original and _fantasmas.empty()


func _hacer_fantasma(nodo):
	if _fantasmas.has(nodo):
		return
	_fantasmas.append(nodo)
	nodo.visible = false
	_apagar_dibujo(nodo)
	# Fuera del juez: no choca, no cuenta en la llegada ni en el puesto.
	if GestorNivel and GestorNivel._corredores.has(nodo):
		GestorNivel._corredores.erase(nodo)
	_recorrido_previo[nodo] = nodo.offset


func _quitar_fantasma(nodo):
	if not _fantasmas.has(nodo):
		return
	_fantasmas.erase(nodo)
	nodo.visible = true
	_prender_dibujo(nodo)
	if "separacion_lateral" in nodo:
		nodo.h_offset = nodo.separacion_lateral
	if GestorNivel and not GestorNivel._corredores.has(nodo):
		GestorNivel.registrar_corredor(nodo)
	_recorrido_previo.erase(nodo)


# Cada cuadro: fuera de la pista, y con su recorrido al dia (lo usa la
# formacion de los rivales y el ritmo del lote).
func _mantener_fantasmas():
	if _fantasmas.empty():
		return
	var largo = _largo()
	for nodo in _fantasmas:
		if not is_instance_valid(nodo):
			continue
		nodo.h_offset = carril_fantasma
		var previo = _recorrido_previo.get(nodo, nodo.offset)
		var d = nodo.offset - previo
		if largo > 0.0:
			d = _envolver(d, largo)
		if GestorNivel and abs(d) <= 200.0:
			GestorNivel._recorrido[nodo] = GestorNivel._recorrido.get(nodo, 0.0) + d
		_recorrido_previo[nodo] = nodo.offset


# Apaga el dibujo de un caballo escondido (caballo, jinete, animaciones)
# para que no cargue la laptop. Recuerda que apago para prenderlo igual.
func _apagar_dibujo(raiz):
	var lista = []
	var pendientes = raiz.get_children()
	while pendientes.size() > 0:
		var n = pendientes.pop_back()
		for h in n.get_children():
			pendientes.append(h)
		if n.is_processing() or n.is_physics_processing():
			lista.append([n, n.is_processing(), n.is_physics_processing()])
			n.set_process(false)
			n.set_physics_process(false)
		if n is AnimationPlayer and n.playback_active:
			lista.append([n])
			n.playback_active = false
	_apagados[raiz] = lista


func _prender_dibujo(raiz):
	for item in _apagados.get(raiz, []):
		var n = item[0]
		if not is_instance_valid(n):
			continue
		if item.size() == 1:
			n.playback_active = true
		else:
			n.set_process(item[1])
			n.set_physics_process(item[2])
	_apagados.erase(raiz)


func _quitar_todos_los_fantasmas():
	for nodo in _fantasmas.duplicate():
		if is_instance_valid(nodo):
			_quitar_fantasma(nodo)
	_fantasmas.clear()
	var raiz = get_tree().current_scene
	var camara = raiz.get_node_or_null("Camara_de_Partida") if raiz else null
	if camara and _seguir_lote_original != null and ("seguir_a_todo_el_lote" in camara):
		camara.seguir_a_todo_el_lote = _seguir_lote_original


# ============================================================
# UNIFORMES: cada jugador se ve con el suyo
# ============================================================
# Mi uniforme, mi raza y mi pelaje, para que los demas me vean igual.
func _sedas_propias():
	var j = _jinete_de(_nodos.get(1))
	var d = {}
	if j:
		for clave in SEDAS:
			if clave in j:
				d[clave] = j.get(clave)
	var rep = _repartidor()
	if rep and rep.has_method("_raza_del_jugador"):
		d["raza"] = rep._raza_del_jugador()
	var pel = _pelajes()
	if pel and ("pelaje_jugador" in pel):
		d["pelaje"] = int(pel.pelaje_jugador)
	return d


# Si cambio mi uniforme en la pantalla de inicio (panel UNIFORME), se lo
# vuelvo a mandar a los demas.
func _revisar_mis_sedas(delta):
	if _pantalla_inicio() == null:
		return
	_t_revisar_sedas -= delta
	if _t_revisar_sedas > 0.0:
		return
	_t_revisar_sedas = 1.0
	var d = _sedas_propias()
	if d.hash() == _ultimas_sedas.hash():
		return
	_ultimas_sedas = d
	if _rol == ANFITRION:
		_sedas[1] = d
		_enviar_sedas_a_todos()
	elif _rol == INVITADO and _conectado and not _cfg.empty():
		rpc_id(1, "_r_mis_sedas", d)


func _enviar_sedas_a_todos():
	if _rol == ANFITRION and not _numero_de_peer.empty():
		rpc("_r_sedas", _sedas)
	_sedas_puestas.clear()


remote func _r_mis_sedas(d):
	if _rol != ANFITRION:
		return
	var peer = get_tree().get_rpc_sender_id()
	if not _numero_de_peer.has(peer):
		return
	_sedas[_numero_de_peer[peer]] = d
	_enviar_sedas_a_todos()


remote func _r_sedas(tabla):
	if _rol != INVITADO or get_tree().get_rpc_sender_id() != 1:
		return
	_sedas = tabla
	_sedas_puestas.clear()


# A cada jugador: 1) su raza, 2) su uniforme (apenas el jinete esta
# vestido) y 3) su pelaje (despues de que Pelajes pinta a todos).
func _poner_sedas_pendientes():
	for n_anfitrion in _sedas.keys():
		var n = _local(int(n_anfitrion))
		var nodo = _nodos.get(n)
		if n == 1 or nodo == null or not is_instance_valid(nodo):
			continue
		var d = _sedas[n_anfitrion]
		var estado = _sedas_puestas.get(n, {})
		if estado.get("listo", false):
			continue
		if not estado.get("raza", false):
			estado["raza"] = _poner_raza(nodo, d.get("raza", "americano"))
		if estado.get("raza", false) and not estado.get("seda", false):
			var j = _jinete_de(nodo)
			if j == null:
				estado["seda"] = true
			elif ("_vestido" in j) and j._vestido:
				for clave in SEDAS:
					if d.has(clave) and (clave in j):
						j.set(clave, d[clave])
				if j.has_method("_pintar"):
					j._pintar()
				estado["seda"] = true
		if estado.get("raza", false) and not estado.get("pelaje", false):
			var pel = _pelajes()
			if pel == null or not d.has("pelaje"):
				estado["pelaje"] = true
			elif pel.get("_shader") != null:
				_pintar_pelaje(pel, nodo, _color_pelaje(pel, int(d["pelaje"])))
				estado["pelaje"] = true
		estado["listo"] = estado.get("raza", false) and estado.get("seda", false) and estado.get("pelaje", false)
		_sedas_puestas[n] = estado


# Le pone al caballo del jugador su raza. Copia la posicion y el tamano de
# un rival de esa misma raza (asi queda igual que los demas de su raza) y
# esconde el caballo que tenia.
func _poner_raza(nodo, raza):
	var rep = _repartidor()
	if rep == null or not rep.has_method("escena_de_raza"):
		return true
	var escena = rep.escena_de_raza(raza)
	if escena == null:
		return true
	var actual = _modelo_visible(nodo)
	if actual and actual.filename == escena.resource_path:
		return true
	var molde = null
	for n2 in _nodos.keys():
		var otro = _nodos[n2]
		if n2 == 1 or otro == nodo or otro == null or not is_instance_valid(otro):
			continue
		var m = _modelo_visible(otro)
		if m and m.filename == escena.resource_path:
			molde = m
			break
	if molde == null:
		# No hay ningun rival de esa raza para copiar: va como americano.
		if raza != "americano":
			return _poner_raza(nodo, "americano")
		return true
	var nuevo = escena.instance()
	nuevo.transform = molde.transform
	nodo.add_child(nuevo)
	if actual:
		actual.visible = false
		if rep.has_method("_apagar"):
			rep._apagar(actual)
	return true


# Pinta el pelaje del jugador en su caballo. Pelajes solo pinta caballos
# sin pintar; si ya lo pinto con otro color, aqui se le cambia el color.
func _pintar_pelaje(pel, nodo, color):
	if not pel.has_method("_esqueleto") or not pel.has_method("_mallas_cuerpo"):
		return
	for modelo in nodo.get_children():
		if not (modelo is Spatial) or not modelo.visible or not modelo.name.begins_with("Caballo"):
			continue
		var esq = pel._esqueleto(modelo)
		if esq == null:
			continue
		for mi in pel._mallas_cuerpo(esq):
			# Lo que todavia no esta pintado, lo pinta Pelajes con este color.
			if pel.has_method("_vestir_malla"):
				pel._vestir_malla(mi, color)
			# Lo que ya estaba pintado (con otro color), se le cambia el color.
			if mi.material_override is ShaderMaterial:
				mi.material_override.set_shader_param("color_pelaje", color)
			if mi.mesh:
				for i in mi.mesh.get_surface_count():
					var m = mi.get_active_material(i)
					if m is ShaderMaterial:
						m.set_shader_param("color_pelaje", color)


func _modelo_visible(nodo):
	for c in nodo.get_children():
		if c is Spatial and c.visible and c.name.begins_with("Caballo"):
			return c
	return null


func _color_pelaje(pel, cual):
	var colores = []
	if pel.get_script():
		colores = pel.get_script().get_script_constant_map().get("COLORES", [])
	if cual >= 0 and cual < colores.size():
		return Color(colores[cual])
	return Color("ffffff")


# El jinete del caballo que se ve (no el del caballo escondido).
func _jinete_de(nodo):
	if nodo == null or not is_instance_valid(nodo):
		return null
	var modelo = _modelo_visible(nodo)
	if modelo == null:
		return null
	var pendientes = [modelo]
	while pendientes.size() > 0:
		var c = pendientes.pop_front()
		if "diseno_cuerpo" in c:
			return c
		for h in c.get_children():
			pendientes.append(h)
	return null


func _repartidor():
	var raiz = get_tree().current_scene
	return raiz.get_node_or_null("RepartidorCaballos") if raiz else null


func _pelajes():
	var raiz = get_tree().current_scene
	return raiz.get_node_or_null("Pelajes") if raiz else null


# ============================================================
# CREAR / UNIRSE / SALIR
# ============================================================
func _crear_carrera():
	_panel.visible = false
	if _hace_falta_firewall():
		# Primero se avisa en pantalla y despues se pide el permiso.
		_avisar("WINDOWS VA A PEDIR PERMISO PARA QUE ENTREN LOS DEMÁS: PULSA SÍ")
		yield(get_tree().create_timer(0.3), "timeout")
		_abrir_firewall()
	var peer = NetworkedMultiplayerENet.new()
	if peer.create_server(puerto_juego, int(max(maximo_jugadores - 1, 1))) != OK:
		_label_estado.text = "NO SE PUDO CREAR (PUERTO %d OCUPADO)" % puerto_juego
		return
	get_tree().network_peer = peer
	_rol = ANFITRION
	_mi_numero = 1
	_humanos = [1]
	_numero_de_peer = {}
	_listos = {}
	_sedas = {1: _sedas_propias()}
	_rechazando = false
	_entrar_modo_grupo()
	if GestorNivel:
		# El nivel de la carrera en grupo es el que tenias escogido al crearla.
		GestorNivel.nivel_de_prueba = GestorNivel.nivel_actual
	_ips_texto = _mis_ips()
	_abrir_anuncio()
	_panel.visible = false
	_aplicar_fantasmas()


func _mostrar_unirse():
	_caja_unirse.visible = true
	_label_estado.text = "BUSCANDO CARRERAS EN TU WIFI..."
	_abrir_escucha()


func _conectar_escrito():
	_conectar(_campo_ip.text)


func _conectar(ip):
	ip = str(ip).strip_edges()
	if not ip.is_valid_ip_address():
		_label_estado.text = "ESCRIBE LA DIRECCIÓN DEL QUE CREÓ LA CARRERA"
		return
	var peer = NetworkedMultiplayerENet.new()
	if peer.create_client(ip, puerto_juego) != OK:
		_label_estado.text = "NO SE PUDO CONECTAR"
		return
	get_tree().network_peer = peer
	_rol = INVITADO
	_conectado = false
	_cfg = {}
	_sedas = {}
	_entrar_modo_grupo()
	_cerrar_escucha()
	_panel.visible = false


func _entrar_modo_grupo():
	if GestorNivel:
		_nivel_previo = GestorNivel.nivel_de_prueba
		GestorNivel.derrotas_seguidas = 0


func _salir(mensaje):
	var peer = get_tree().network_peer
	if peer is NetworkedMultiplayerENet:
		peer.close_connection()
	get_tree().network_peer = null
	if GestorNivel and _rol != NADA:
		GestorNivel.nivel_de_prueba = _nivel_previo
	_quitar_todos_los_fantasmas()
	_rol = NADA
	_conectado = false
	_mi_numero = 1
	_humanos = [1]
	_con_ia = true
	_numero_de_peer = {}
	_listos = {}
	_cfg = {}
	_puestos_invitado = {}
	_sedas = {}
	_remotos.clear()
	_rechazando = false
	_cerrar_anuncio()
	_cerrar_escucha()
	# Devuelve la pantalla de inicio y PAUSAR a como eran.
	var pantalla = _pantalla_inicio()
	if pantalla:
		var boton = pantalla.get("boton_partida")
		if boton and is_instance_valid(boton):
			boton.visible = true
			boton.disabled = false
	var raiz = get_tree().current_scene
	var selector = raiz.get_node_or_null("SelectorDistancias") if raiz else null
	if selector and get_tree().paused:
		selector.visible = true
	var pausa = _boton_pausa()
	if pausa:
		pausa.visible = true
	if mensaje != "":
		_avisar(mensaje)


# ============================================================
# WINDOWS: permiso del firewall para recibir jugadores
# ============================================================
const ARCHIVO_RED = "user://red_bdg.cfg"


func _hace_falta_firewall():
	if not abrir_firewall_en_windows or OS.get_name() != "Windows":
		return false
	var cfg = ConfigFile.new()
	cfg.load(ARCHIVO_RED)
	return not cfg.get_value("firewall", OS.get_executable_path().md5_text(), false)


# Arma un archivito .bat con las ordenes de Windows y lo corre con permiso
# de administrador (sale la ventanita de Windows: hay que pulsar Si).
# Quita los bloqueos que Windows le haya puesto a este programa y lo deja
# recibir jugadores en todas las redes.
func _abrir_firewall():
	var exe = OS.get_executable_path().replace("/", "\\")
	var bat = ProjectSettings.globalize_path("user://bdg_firewall.bat").replace("/", "\\")
	var texto = "@echo off\r\n"
	texto += "netsh advfirewall firewall delete rule name=all dir=in program=\"" + exe + "\"\r\n"
	texto += "netsh advfirewall firewall add rule name=\"Brisas de Gloria\" dir=in action=allow program=\"" + exe + "\" enable=yes profile=any\r\n"
	var f = File.new()
	if f.open(bat, File.WRITE) != OK:
		return
	f.store_string(texto)
	f.close()
	var salida = []
	var codigo = OS.execute("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
		"Start-Process -FilePath '" + bat + "' -Verb RunAs -Wait -WindowStyle Hidden"], true, salida)
	if codigo == 0:
		var cfg = ConfigFile.new()
		cfg.load(ARCHIVO_RED)
		cfg.set_value("firewall", OS.get_executable_path().md5_text(), true)
		cfg.save(ARCHIVO_RED)
		_avisar("LISTO: WINDOWS YA DEJA ENTRAR A LOS DEMÁS")
	else:
		_avisar("WINDOWS NO DIO PERMISO: LOS DEMÁS NO PODRÁN ENTRAR")


# Llega un jugador nuevo: se le da el primer caballo libre (del 2 al 12).
func _al_conectar_peer(id):
	if _rol != ANFITRION:
		return
	var numero = 0
	var usados = _numero_de_peer.values()
	for n in range(2, int(min(maximo_jugadores, max(_nodos.size(), 2))) + 1):
		if not usados.has(n):
			numero = n
			break
	if numero == 0:
		var peer = get_tree().network_peer
		if peer is NetworkedMultiplayerENet:
			peer.disconnect_peer(id)
		return
	_numero_de_peer[id] = numero
	_actualizar_humanos()
	_avisar("SE UNIÓ UN JUGADOR (%d EN TOTAL)" % _humanos.size())
	_aplicar_fantasmas()
	_enviar_humanos()
	_enviar_config_a(id)
	rpc_id(id, "_r_sedas", _sedas)


func _al_desconectar_peer(id):
	if _rol != ANFITRION or not _numero_de_peer.has(id):
		return
	var numero = _numero_de_peer[id]
	_numero_de_peer.erase(id)
	_listos.erase(id)
	_remotos.erase(numero)
	_sedas.erase(numero)
	_actualizar_humanos()
	_avisar("SE FUE UN JUGADOR (QUEDAN %d)" % _humanos.size())
	# CON IA, su caballo lo vuelve a mover la maquina. SIN IA, se esconde.
	_aplicar_fantasmas()
	_enviar_humanos()
	if _numero_de_peer.empty():
		_abrir_anuncio()


func _actualizar_humanos():
	_humanos = [1]
	for peer in _numero_de_peer.keys():
		_humanos.append(_numero_de_peer[peer])
	_humanos.sort()


func _al_conectar_servidor():
	if _rol != INVITADO:
		return
	_conectado = true
	_avisar("CONECTADO")


# (Se sale en el cuadro siguiente: cerrar la conexion dentro de su
# propio aviso puede trancar el juego.)
func _al_fallar_conexion():
	if _rol == INVITADO:
		call_deferred("_salir", "NO SE PUDO CONECTAR CON ESA DIRECCIÓN")


func _al_perder_servidor():
	if _rol == INVITADO:
		call_deferred("_salir", "EL QUE CREÓ LA CARRERA SE DESCONECTÓ")


func _cambiar_ia():
	if _rol != ANFITRION or _pantalla_inicio() == null:
		return
	_con_ia = not _con_ia
	_aplicar_fantasmas()
	_enviar_humanos()


# ============================================================
# BUSCAR LA CARRERA EN LA WIFI (sin escribir la direccion)
# ============================================================
func _abrir_anuncio():
	_cerrar_anuncio()
	_udp_anuncio = PacketPeerUDP.new()
	_udp_anuncio.set_broadcast_enabled(true)
	_udp_anuncio.set_dest_address("255.255.255.255", puerto_busqueda)
	_t_anuncio = 0.0


func _anunciar(delta):
	if _udp_anuncio == null or _rol != ANFITRION:
		return
	# Solo en la pantalla de inicio y si queda lugar.
	if _pantalla_inicio() == null or _humanos.size() >= maximo_jugadores:
		return
	_t_anuncio -= delta
	if _t_anuncio > 0.0:
		return
	_t_anuncio = 1.0
	_udp_anuncio.put_packet(("BDG1VS1|%d" % VERSION).to_utf8())


func _cerrar_anuncio():
	if _udp_anuncio:
		_udp_anuncio.close()
	_udp_anuncio = null


func _abrir_escucha():
	_cerrar_escucha()
	_encontrados.clear()
	for hijo in _lista_encontrados.get_children():
		hijo.queue_free()
	_udp_escucha = PacketPeerUDP.new()
	_udp_escucha.set_broadcast_enabled(true)
	if _udp_escucha.listen(puerto_busqueda) != OK:
		_udp_escucha = null
		_label_estado.text = "ESCRIBE LA DIRECCIÓN DEL QUE CREÓ LA CARRERA"


func _buscar_anfitriones():
	if _udp_escucha == null:
		return
	while _udp_escucha.get_available_packet_count() > 0:
		var paquete = _udp_escucha.get_packet()
		var ip = _udp_escucha.get_packet_ip()
		var texto = paquete.get_string_from_utf8()
		if texto != "BDG1VS1|%d" % VERSION or ip == "" or ip in _encontrados:
			continue
		_encontrados.append(ip)
		var b = _boton("UNIRSE A " + ip, Vector2(0, 56), tamano_texto_panel)
		b.connect("pressed", self, "_conectar", [ip])
		_lista_encontrados.add_child(b)
		_label_estado.text = "TOCA LA CARRERA PARA UNIRTE"


func _cerrar_escucha():
	if _udp_escucha:
		_udp_escucha.close()
	_udp_escucha = null


func _mis_ips():
	var lista = []
	for ip in IP.get_local_addresses():
		if ip.find(":") >= 0:
			continue
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			lista.append(ip)
	if lista.empty():
		return "(SIN WIFI)"
	return PoolStringArray(lista).join("  /  ")


# ============================================================
# PANTALLA DE INICIO
# ============================================================
func _boton_pausa():
	var camino = _camino()
	var jockey = camino.get_node_or_null("Enrutador_Caballo1/Jockey") if camino else null
	if jockey and ("_boton_pausa" in jockey) and jockey._boton_pausa and is_instance_valid(jockey._boton_pausa):
		return jockey._boton_pausa
	return null


func _actualizar_pantalla_inicio():
	if _rol == NADA:
		return
	# PAUSAR se esconde en la carrera en grupo.
	var pausa = _boton_pausa()
	if pausa:
		pausa.visible = false
	var pantalla = _pantalla_inicio()
	if _rol == ANFITRION:
		# Nadie entra con la carrera ya corriendo.
		var rechazar = pantalla == null
		if rechazar != _rechazando and get_tree().network_peer:
			_rechazando = rechazar
			get_tree().refuse_new_network_connections = rechazar
	if pantalla == null:
		return
	var boton = pantalla.get("boton_partida")
	if boton == null or not is_instance_valid(boton):
		return
	if not boton.is_connected("pressed", self, "_al_pulsar_correr"):
		boton.connect("pressed", self, "_al_pulsar_correr")
	if _rol == INVITADO:
		# El invitado no escoge distancia ni pulsa CORRER: espera al anfitrion.
		boton.visible = false
		var raiz = get_tree().current_scene
		var selector = raiz.get_node_or_null("SelectorDistancias") if raiz else null
		if selector:
			selector.visible = false
	else:
		boton.visible = true
		boton.disabled = not _todos_listos()


func _texto_estado():
	if _rol == ANFITRION:
		var ip = "   TU DIRECCIÓN: " + _ips_texto
		var modo = "   (" + (texto_con_ia if _con_ia else texto_sin_ia) + ")"
		if _numero_de_peer.empty():
			return "ESPERANDO JUGADORES..." + ip
		if not _todos_listos():
			return "JUGADORES: %d   CARGANDO: %d..." % [_humanos.size(), _numero_de_peer.size() - _cuantos_listos()] + modo + ip
		return "JUGADORES: %d   TODOS LISTOS. PULSA CORRER" % _humanos.size() + modo + ip
	if _rol == INVITADO:
		if not _conectado:
			return "CONECTANDO..."
		if _cfg.empty():
			return "CONECTADO. ESPERANDO LA CARRERA..."
		var modo_invitado = texto_con_ia if _con_ia else texto_sin_ia
		return "JUGADORES: %d (%s). ESPERANDO QUE EL QUE CREÓ LA CARRERA PULSE CORRER" % [_humanos.size(), modo_invitado]
	return ""


func _pantalla_inicio():
	var raiz = get_tree().current_scene
	if raiz == null:
		return null
	var p = raiz.get_node_or_null("PantallaInicio")
	if p == null or p.is_queued_for_deletion():
		return null
	return p


func _camino():
	var raiz = get_tree().current_scene
	if raiz == null:
		return null
	return raiz.get_node_or_null("TrackPath")


func _largo():
	var camino = _camino()
	if camino and ("curve" in camino) and camino.curve:
		return camino.curve.get_baked_length()
	return 0.0


func _contar_caballos(camino):
	var n = 0
	while camino.get_node_or_null("Enrutador_Caballo%d" % (n + 1)):
		n += 1
	return n


# ============================================================
# INTERFAZ
# ============================================================
func _crear_interfaz():
	_capa = CanvasLayer.new()
	_capa.layer = 120
	add_child(_capa)

	_boton_1vs1 = _boton(texto_boton, tamano_boton, tamano_texto_boton)
	_boton_1vs1.anchor_left = posicion_boton.x
	_boton_1vs1.anchor_right = posicion_boton.x
	_boton_1vs1.anchor_top = posicion_boton.y
	_boton_1vs1.anchor_bottom = posicion_boton.y
	_boton_1vs1.margin_left = -tamano_boton.x * 0.5
	_boton_1vs1.margin_right = tamano_boton.x * 0.5
	_boton_1vs1.margin_top = -tamano_boton.y * 0.5
	_boton_1vs1.margin_bottom = tamano_boton.y * 0.5
	_boton_1vs1.connect("pressed", self, "_al_pulsar_1vs1")
	_capa.add_child(_boton_1vs1)

	# CON IA / SIN IA: solo lo ve el que creo la carrera, a la derecha del 1 VS 1.
	_boton_ia = _boton(texto_con_ia, tamano_boton, tamano_texto_boton)
	_boton_ia.connect("pressed", self, "_cambiar_ia")
	_boton_ia.visible = false
	_capa.add_child(_boton_ia)

	_panel = PanelContainer.new()
	_panel.add_stylebox_override("panel", _estilo(color_borde, 22))
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.visible = false
	_capa.add_child(_panel)

	var caja = VBoxContainer.new()
	caja.add_constant_override("separation", 12)
	_panel.add_child(caja)
	caja.add_child(_etiqueta(texto_boton, tamano_texto_boton))
	_label_estado = _etiqueta("", tamano_texto_panel)
	caja.add_child(_label_estado)

	var fila = HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGN_CENTER
	fila.add_constant_override("separation", 14)
	caja.add_child(fila)
	var crear = _boton("CREAR CARRERA", Vector2(260, 60), tamano_texto_panel)
	crear.connect("pressed", self, "_crear_carrera")
	fila.add_child(crear)
	var unirse = _boton("UNIRSE", Vector2(200, 60), tamano_texto_panel)
	unirse.connect("pressed", self, "_mostrar_unirse")
	fila.add_child(unirse)

	_caja_unirse = VBoxContainer.new()
	_caja_unirse.add_constant_override("separation", 8)
	_caja_unirse.visible = false
	caja.add_child(_caja_unirse)
	_lista_encontrados = VBoxContainer.new()
	_lista_encontrados.add_constant_override("separation", 6)
	_caja_unirse.add_child(_lista_encontrados)
	var fila_ip = HBoxContainer.new()
	fila_ip.add_constant_override("separation", 10)
	_caja_unirse.add_child(fila_ip)
	_campo_ip = LineEdit.new()
	_campo_ip.placeholder_text = "ESCRIBE AQUÍ LA DIRECCIÓN"
	_campo_ip.rect_min_size = Vector2(300, 56)
	_campo_ip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f = _fuente(tamano_texto_panel)
	if f:
		_campo_ip.add_font_override("font", f)
	fila_ip.add_child(_campo_ip)
	var conectar = _boton("CONECTAR", Vector2(180, 56), tamano_texto_panel)
	conectar.connect("pressed", self, "_conectar_escrito")
	fila_ip.add_child(conectar)

	var cerrar = _boton("CERRAR", Vector2(160, 50), tamano_texto_panel)
	cerrar.connect("pressed", self, "_cerrar_panel")
	caja.add_child(cerrar)

	_aviso = Label.new()
	_aviso.align = Label.ALIGN_CENTER
	_aviso.valign = Label.VALIGN_CENTER
	_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aviso.add_color_override("font_color", color_aviso)
	_aviso.anchor_left = 0.0
	_aviso.anchor_right = 1.0
	_aviso.anchor_top = posicion_aviso.y
	_aviso.anchor_bottom = posicion_aviso.y
	_aviso.margin_left = 20
	_aviso.margin_right = -20
	_aviso.margin_top = -tamano_texto_aviso
	_aviso.margin_bottom = tamano_texto_aviso
	_aviso.autowrap = true
	var fa = _fuente(tamano_texto_aviso)
	if fa:
		_aviso.add_font_override("font", fa)
	_capa.add_child(_aviso)


func _actualizar_interfaz(delta):
	if _capa == null:
		return
	var en_inicio = _pantalla_inicio() != null
	_boton_1vs1.visible = en_inicio
	_boton_1vs1.text = texto_boton if _rol == NADA else "SALIR"
	_boton_ia.visible = en_inicio and _rol == ANFITRION
	_boton_ia.text = texto_con_ia if _con_ia else texto_sin_ia
	if en_inicio:
		_ubicar_boton()
	if not en_inicio:
		_panel.visible = false
	if _t_temporal > 0.0:
		_t_temporal -= delta
	var texto = ""
	if _t_temporal > 0.0:
		texto = _mensaje_temporal
	elif en_inicio:
		texto = _texto_estado()
	_aviso.text = texto
	_aviso.visible = texto != ""


# Pone el boton justo debajo de la lista de distancias de SelectorDistancias,
# y el de CON IA / SIN IA a su derecha.
func _ubicar_boton():
	if not boton_debajo_de_distancias:
		return
	var raiz = get_tree().current_scene
	var selector = raiz.get_node_or_null("SelectorDistancias") if raiz else null
	if selector == null:
		return
	var lista = null
	for hijo in selector.get_children():
		if hijo is VBoxContainer:
			lista = hijo
			break
	if lista == null:
		return
	var tam = Vector2(lista.rect_size.x, tamano_boton.y)
	var pos = Vector2(lista.rect_position.x, lista.rect_position.y + lista.rect_size.y + separacion_debajo)
	for b in [_boton_1vs1, _boton_ia]:
		b.anchor_left = 0
		b.anchor_right = 0
		b.anchor_top = 0
		b.anchor_bottom = 0
		b.rect_min_size = tam
		b.rect_size = tam
	_boton_1vs1.rect_position = pos
	_boton_ia.rect_position = pos + Vector2(tam.x + separacion_boton_ia, 0)


func _al_pulsar_1vs1():
	if _rol != NADA:
		_salir("SALISTE DE LA CARRERA EN GRUPO")
		return
	_panel.visible = not _panel.visible
	_caja_unirse.visible = false
	_label_estado.text = "¿CREAS LA CARRERA O TE UNES A UNA?"
	if not _panel.visible:
		_cerrar_escucha()


func _cerrar_panel():
	_panel.visible = false
	_cerrar_escucha()


func _avisar(texto):
	_mensaje_temporal = texto
	_t_temporal = segundos_aviso_temporal


func _boton(texto, tamano, tamano_texto):
	var b = Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.rect_min_size = tamano
	b.add_stylebox_override("normal", _estilo(color_borde, 12))
	b.add_stylebox_override("hover", _estilo(color_borde, 12))
	var apretado = _estilo(color_borde, 12)
	apretado.bg_color = color_borde.darkened(0.6)
	b.add_stylebox_override("pressed", apretado)
	var apagado = _estilo(Color(color_borde.r, color_borde.g, color_borde.b, 0.3), 12)
	b.add_stylebox_override("disabled", apagado)
	b.add_color_override("font_color", color_texto)
	b.add_color_override("font_color_hover", color_texto)
	b.add_color_override("font_color_pressed", color_texto)
	var f = _fuente(tamano_texto)
	if f:
		b.add_font_override("font", f)
	return b


func _etiqueta(texto, tamano):
	var l = Label.new()
	l.text = texto
	l.align = Label.ALIGN_CENTER
	l.add_color_override("font_color", color_texto)
	var f = _fuente(tamano)
	if f:
		l.add_font_override("font", f)
	return l


func _estilo(borde, relleno):
	var e = StyleBoxFlat.new()
	e.bg_color = color_fondo
	e.border_color = borde
	e.set_border_width_all(3)
	e.set_corner_radius_all(10)
	e.content_margin_left = relleno
	e.content_margin_right = relleno
	e.content_margin_top = relleno * 0.5
	e.content_margin_bottom = relleno * 0.5
	return e


# Copia la fuente del juego (Oswald) con otro tamano.
func _fuente(tamano):
	if _fuente_base == null and archivo_fuente != "" and ResourceLoader.exists(archivo_fuente):
		_fuente_base = load(archivo_fuente)
	if not (_fuente_base is DynamicFont):
		return null
	var copia = _fuente_base.duplicate()
	copia.size = tamano
	return copia
