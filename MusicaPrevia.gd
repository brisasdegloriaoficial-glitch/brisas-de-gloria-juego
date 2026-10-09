extends AudioStreamPlayer
# Musica de todo lo que NO es carrera (Beneath the Bit):
#  - Pantalla de inicio: suena en bucle mientras se elige distancia y uniforme.
#    Al pulsar PARTIDA se apaga suave (se oyen campanadas y gatera).
#  - Pausa en plena carrera (PAUSAR o ajustes): entra; al seguir, se va.
#  - Despues de la meta: la bulla del publico tapa todo y, en el relevo,
#    en vez de volver la musica de carrera, entra esta.
# Al elegir otra distancia la pista se recarga: la cancion sigue donde iba.

export(String, FILE, "*.ogg, *.mp3") var archivo_musica = "res://Sonidos/Beneath_the_Bit.ogg"
export var volumen_musica = 6.0             # volumen de esta musica (igual que MusicaCarrera)
export var segundos_para_apagarse = 2.5     # cuanto tarda en apagarse al pulsar PARTIDA
export var segundos_para_entrar = 1.5       # cuanto tarda en subir al abrir el juego
export var sonar_en_pausa = true            # tambien suena cuando se pausa la carrera
export var segundos_en_pausa = 0.8          # cuanto tarda en entrar/salir en la pausa
export var sonar_despues_de_meta = true     # tambien suena despues de la meta

const SILENCIO = -60.0

var _estado = "antes"    # antes, saliendo, carrera, pausa, final
var _t = 0.0
var _desde = SILENCIO
var _pantalla = null
var _habia_pantalla = false
var _publico = null
var _jockey = null
var _musica_carrera = null

func _ready():
	# Tiene que sonar aunque el juego este en pausa.
	pause_mode = Node.PAUSE_MODE_PROCESS
	bus = "Musica"
	var cancion = load(archivo_musica) if ResourceLoader.exists(archivo_musica) else null
	if cancion == null:
		print("[MusicaPrevia] ERROR: no encuentro la cancion en ", archivo_musica)
		set_process(false)
		return
	if cancion is AudioStreamOGGVorbis or cancion is AudioStreamMP3:
		cancion.loop = true
	stream = cancion
	var escena = get_tree().current_scene if get_tree().current_scene else get_parent()
	_pantalla = escena.find_node("PantallaInicio", true, false)
	_habia_pantalla = _pantalla != null
	_publico = escena.find_node("SonidoPublico", true, false)
	_jockey = escena.find_node("Jockey", true, false)
	_musica_carrera = escena.find_node("MusicaCarrera", true, false)
	# Si la pista se recargo (se eligio otra distancia), sigue donde iba.
	var desde_seg = 0.0
	if Engine.has_meta("bdg_musica_previa_pos"):
		desde_seg = Engine.get_meta("bdg_musica_previa_pos")
		Engine.remove_meta("bdg_musica_previa_pos")
		_desde = volumen_musica
		_t = segundos_para_entrar
	volume_db = _desde
	play(desde_seg)
	print("[MusicaPrevia] sonando: ", archivo_musica, " | pantalla de inicio: ", _habia_pantalla)

func _exit_tree():
	# Guarda por donde iba, para seguir igual si la pista se recarga.
	if _estado == "antes" and playing and not stream_paused:
		Engine.set_meta("bdg_musica_previa_pos", get_playback_position())

func _process(delta):
	_t += delta
	match _estado:
		"antes":
			_subir(segundos_para_entrar)
			if _t > 0.2 and _se_pulso_partida():
				_pasar_a("saliendo")
				print("[MusicaPrevia] se pulso PARTIDA, se apaga")
		"saliendo":
			if _bajar(segundos_para_apagarse):
				_pasar_a("carrera")
		"carrera":
			if _llego_a_la_meta():
				_pasar_a("final")
				_apagar_musica_carrera()
			elif sonar_en_pausa and get_tree().paused:
				_pasar_a("pausa")
			else:
				_bajar(segundos_en_pausa)
		"pausa":
			_subir(segundos_en_pausa)
			if not get_tree().paused:
				_pasar_a("carrera")
		"final":
			# Espera que pase el momento cumbre (la bulla) y entra en el relevo.
			var espera = 1.5
			var relevo = 4.0
			if _publico:
				espera = _publico.get("duracion_climax")
				relevo = _publico.get("segundos_relevo")
			if _t >= espera:
				var f = clamp((_t - espera) / max(relevo, 0.1), 0.0, 1.0)
				f = f * f * (3.0 - 2.0 * f)
				_reanudar()
				volume_db = lerp(SILENCIO, volumen_musica, f)
				if f >= 1.0 and _musica_carrera and _musica_carrera.playing:
					_musica_carrera.stop()


func _pasar_a(nuevo):
	_estado = nuevo
	_t = 0.0
	_desde = volume_db


# Sigue sonando desde donde iba (si estaba en pausa).
func _reanudar():
	if stream_paused:
		stream_paused = false
	if not playing:
		play()


# Sube desde donde estaba hasta el volumen de la musica.
func _subir(segundos):
	_reanudar()
	var f = clamp(_t / max(segundos, 0.01), 0.0, 1.0)
	volume_db = lerp(_desde, volumen_musica, f)


# Baja hasta el silencio y se queda en pausa (sin perder por donde iba).
# true = ya bajo.
func _bajar(segundos):
	if stream_paused:
		return true
	var f = clamp(_t / max(segundos, 0.01), 0.0, 1.0)
	volume_db = lerp(_desde, SILENCIO, f)
	if f >= 1.0:
		stream_paused = true
		return true
	return false


# true cuando se pulso PARTIDA: la pantalla de inicio se cerro (o empezo
# su cuenta). Si no habia pantalla de inicio, cuando abre la gatera.
func _se_pulso_partida() -> bool:
	if _habia_pantalla:
		return not is_instance_valid(_pantalla) or _pantalla.get("contando") == true
	var gate = get_tree().current_scene.find_node("Gate", true, false) if get_tree().current_scene else null
	return gate != null and gate.get("_largaron") == true


func _llego_a_la_meta() -> bool:
	if not sonar_despues_de_meta:
		return false
	if _publico and _publico.get("_en_climax") == true:
		return true
	return _jockey != null and _jockey.get("carrera_terminada") == true


# En el relevo despues de la meta ya no vuelve la musica de carrera:
# se le pide al publico que la deje apagada.
func _apagar_musica_carrera():
	if _publico and "_musica_volumen" in _publico:
		_publico._musica_volumen = SILENCIO
