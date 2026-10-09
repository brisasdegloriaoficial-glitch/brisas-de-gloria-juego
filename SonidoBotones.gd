extends Node
# Clic para TODOS los botones del juego, menos los controles de carrera.
# Va como AutoLoad con el nombre SonidoBotones (Configuracion del Proyecto).

# ---- Valores para ajustar (este script no sale en el Inspector) ----
const RUTA_SONIDO = "res://Sonidos/clic.ogg"
const VOLUMEN_CLIC_DB = 0.0                    # 0 normal, -6 mas bajo, +4 mas alto
const EXCLUIR_SCRIPTS = ["ControlesAndroid.gd"] # botones que NO hacen clic
# NUEVO - Botones con sonido propio: los botones que cuelgan de ese script
# suenan con ese archivo en vez del clic (PARTIDA suena con la moneda).
const SONIDOS_ESPECIALES = {"PantallaInicio.gd": "res://Sonidos/Clic_Moneda.ogg"}
const VOLUMEN_ESPECIAL_DB = 0.0                # volumen de los sonidos especiales

var _clic = null
var _especial = null
var _especiales = {}
var _conectados = 0

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	var sonido = load(RUTA_SONIDO)
	print("[BDG-Clic] arranco. Sonido cargado: ", sonido != null)
	if sonido is AudioStreamOGGVorbis or sonido is AudioStreamMP3:
		sonido.loop = false
	_clic = AudioStreamPlayer.new()
	_clic.stream = sonido
	_clic.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(_clic)
	# NUEVO - reproductor para los sonidos especiales (moneda de PARTIDA)
	_especial = AudioStreamPlayer.new()
	_especial.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(_especial)
	for script_nombre in SONIDOS_ESPECIALES.keys():
		var s = load(SONIDOS_ESPECIALES[script_nombre]) if ResourceLoader.exists(SONIDOS_ESPECIALES[script_nombre]) else null
		if s is AudioStreamOGGVorbis or s is AudioStreamMP3:
			s.loop = false
		if s:
			_especiales[script_nombre] = s
	get_tree().connect("node_added", self, "_al_agregar_nodo")
	call_deferred("_revisar", get_tree().root)

func _revisar(nodo):
	_al_agregar_nodo(nodo)
	for hijo in nodo.get_children():
		_revisar(hijo)

func _al_agregar_nodo(nodo):
	if not (nodo is BaseButton):
		return
	if _es_control_de_carrera(nodo):
		return
	var especial = _sonido_especial(nodo)
	if especial != null:
		if not nodo.is_connected("button_down", self, "_sonar_especial"):
			nodo.connect("button_down", self, "_sonar_especial", [especial])
			_conectados += 1
		return
	if not nodo.is_connected("button_down", self, "_sonar"):
		nodo.connect("button_down", self, "_sonar")
		_conectados += 1
		print("[BDG-Clic] boton conectado: ", nodo.name, " (total ", _conectados, ")")

func _es_control_de_carrera(nodo) -> bool:
	var p = nodo
	while p:
		var s = p.get_script()
		if s:
			for nombre in EXCLUIR_SCRIPTS:
				if s.resource_path.ends_with(nombre):
					return true
		p = p.get_parent()
	return false

# NUEVO - Devuelve el sonido especial del boton, o null si usa el clic normal.
func _sonido_especial(nodo):
	var p = nodo
	while p:
		var s = p.get_script()
		if s:
			for nombre in _especiales.keys():
				if s.resource_path.ends_with(nombre):
					return _especiales[nombre]
		p = p.get_parent()
	return null

func _sonar_especial(sonido):
	_especial.stream = sonido
	_especial.volume_db = VOLUMEN_ESPECIAL_DB
	_especial.play()

func _sonar():
	print("[BDG-Clic] boton tocado")
	if _clic.stream == null:
		return
	_clic.volume_db = VOLUMEN_CLIC_DB
	_clic.play()
