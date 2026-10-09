extends AudioStreamPlayer
# Sonido de la largada. Va como hijo del nodo Gate (Aparato_Partida).
# Orden: tres campanadas -> pausa -> gatera (1 s antes de la partida) -> partida.
# La musica de carrera NO suena antes: este script la enciende despues de la partida.
# (MusicaCarrera debe tener Autoplay APAGADO.)

export(AudioStream) var sonido_campanada       # si queda vacio usa res://Sonidos/campanada.ogg
export(AudioStream) var sonido_gatera          # si queda vacio usa res://Sonidos/gatera.ogg
export var volumen_campanada_db = 0.0          # volumen de cada campanada
export var volumen_gatera_db = 0.0             # volumen de la gatera
export var numero_campanadas = 3               # cuantas campanadas suenan
export var intervalo_campanadas = 0.6          # segundos entre una campanada y la otra
export var pausa_entre = 0.3                   # silencio entre la ultima campanada y la gatera
export var segundos_gatera_antes = 1.0         # la gatera se abre esto antes de la partida
export var segundos_musica_despues = 0.5       # la musica arranca esto despues de la partida
# --- NUEVO - Variedad en la largada ---
# En cada carrera sale UNO al azar de las dos listas, sin repetir el de la
# carrera anterior. Las campanadas suenan durante la cuenta (Numero
# Campanadas golpes). Los timbres suenan una vez, cuando se abre la gatera.
# Si las dos listas quedan vacias, suena Sonido Campanada como antes.
export(Array, String, FILE, "*.ogg, *.mp3") var lista_campanadas = [ "res://Sonidos/campanada.ogg", "res://Sonidos/Campanada_Grave.ogg" ]
export(Array, String, FILE, "*.ogg, *.mp3") var lista_timbres = [ "res://Sonidos/Timbre_Hipodromo.ogg", "res://Sonidos/Timbre_Clasico.ogg" ]
export var volumen_timbre_db = 0.0             # volumen de los timbres
# --- Musica variada ---
# Pon aqui las canciones de carrera (clic en cada casilla y elige el .ogg).
# En cada carrera sale una al azar, sin repetir la de la carrera anterior.
# PESO: solo se carga la que toca, las demas no ocupan memoria.
# Si la lista queda vacia, suena la que ya tiene el nodo MusicaCarrera.
export(Array, String, FILE, "*.ogg, *.mp3") var lista_musicas = []
export var musica_en_bucle = true              # si la cancion se acaba antes que la carrera, vuelve a empezar

var _campanas = []
var _gatera = null
var _musica = null
var _vi_conteo = false
var _siguiente = 0
var _gatera_sonada = false
var _musica_lista = false
var _t_despues = 0.0
var _timbre = null
var _timbre_sonado = false

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	if sonido_campanada == null:
		sonido_campanada = load("res://Sonidos/campanada.ogg")
	if sonido_gatera == null:
		sonido_gatera = load("res://Sonidos/gatera.ogg")
	# NUEVO - Elige el sonido de esta largada (campanadas o timbre).
	var elegido = _elegir_largada()
	if elegido != null:
		if elegido[1] == "timbre":
			_timbre = AudioStreamPlayer.new()
			_timbre.stream = elegido[0]
			add_child(_timbre)
		else:
			sonido_campanada = elegido[0]
	for s in [sonido_campanada, sonido_gatera]:
		if s is AudioStreamOGGVorbis or s is AudioStreamMP3:
			s.loop = false
	if _timbre:
		if _timbre.stream is AudioStreamOGGVorbis or _timbre.stream is AudioStreamMP3:
			_timbre.stream.loop = false
	for i in range(0 if _timbre else max(numero_campanadas, 1)):
		var p = AudioStreamPlayer.new()
		p.stream = sonido_campanada
		add_child(p)
		_campanas.append(p)
	_gatera = AudioStreamPlayer.new()
	_gatera.stream = sonido_gatera
	add_child(_gatera)
	if owner:
		_musica = owner.find_node("MusicaCarrera", true, false)

func _process(delta):
	var gate = get_parent()
	var conteo = gate.get("_conteo_restante")
	var largaron = gate.get("_largaron") == true

	# Musica: callada hasta despues de la partida, y ahi arranca desde el principio.
	if _musica and not _musica_lista:
		if not largaron:
			if _musica.playing:
				_musica.stop()
		else:
			_t_despues += delta
			if _t_despues >= segundos_musica_despues:
				_elegir_musica()
				_musica.play()
				_musica_lista = true

	if get_tree().paused:
		return
	if conteo == null:
		return
	if conteo > segundos_gatera_antes:
		_vi_conteo = true
	if not _vi_conteo or largaron:
		return

	# Campanadas, una detras de otra.
	while _siguiente < _campanas.size():
		var faltan = _campanas.size() - 1 - _siguiente
		var momento = segundos_gatera_antes + pausa_entre + intervalo_campanadas * faltan
		if conteo <= momento:
			var p = _campanas[_siguiente]
			p.volume_db = volumen_campanada_db
			p.play()
			_siguiente += 1
		else:
			break

	# Gatera.
	if not _gatera_sonada and conteo <= segundos_gatera_antes:
		_gatera.volume_db = volumen_gatera_db
		_gatera.play()
		_gatera_sonada = true
		# NUEVO - el timbre suena junto con la gatera, como en el hipodromo.
		if _timbre and not _timbre_sonado:
			_timbre.volume_db = volumen_timbre_db
			_timbre.play()
			_timbre_sonado = true


# NUEVO - Elige el sonido de la largada al azar, distinto al de la carrera
# anterior. Devuelve [sonido, "campanada" o "timbre"], o null si no hay.
func _elegir_largada():
	var opciones = []
	for ruta in lista_campanadas:
		if typeof(ruta) == TYPE_STRING and ruta != "" and ResourceLoader.exists(ruta):
			opciones.append([ruta, "campanada"])
	for ruta in lista_timbres:
		if typeof(ruta) == TYPE_STRING and ruta != "" and ResourceLoader.exists(ruta):
			opciones.append([ruta, "timbre"])
	if opciones.empty():
		return null
	var anterior = ""
	if Engine.has_meta("bdg_ultima_largada"):
		anterior = Engine.get_meta("bdg_ultima_largada")
	if opciones.size() > 1:
		for o in opciones:
			if o[0] == anterior:
				opciones.erase(o)
				break
	randomize()
	var elegida = opciones[randi() % opciones.size()]
	Engine.set_meta("bdg_ultima_largada", elegida[0])
	print("[Largada] suena: ", elegida[0].get_file())
	return [load(elegida[0]), elegida[1]]


# Elige una cancion al azar de la lista, distinta a la de la carrera anterior.
func _elegir_musica():
	var validas = []
	for ruta in lista_musicas:
		if typeof(ruta) == TYPE_STRING and ruta != "" and ResourceLoader.exists(ruta):
			validas.append(ruta)
	if validas.empty():
		return
	var anterior = ""
	if Engine.has_meta("bdg_ultima_musica"):
		anterior = Engine.get_meta("bdg_ultima_musica")
	var opciones = validas.duplicate()
	if opciones.size() > 1 and opciones.has(anterior):
		opciones.erase(anterior)
	randomize()
	var elegida = opciones[randi() % opciones.size()]
	Engine.set_meta("bdg_ultima_musica", elegida)
	var cancion = load(elegida)
	if cancion is AudioStreamOGGVorbis or cancion is AudioStreamMP3:
		cancion.loop = musica_en_bucle
	if cancion:
		_musica.stream = cancion
