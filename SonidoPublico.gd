extends AudioStreamPlayer
# Sonido del publico. Va como hijo de Enrutador_Caballo1 (hermano del nodo Jockey).
# Murmullo que sube suave en el tramo final; la bulla arranca antes de la meta
# y explota en el instante de la foto (la musica casi desaparece).
# Despues: el publico baja suave y la musica sube al mismo tiempo (relevo).

export(AudioStream) var murmullo               # si queda vacio usa res://Sonidos/publico_murmullo.ogg
export(AudioStream) var grito_llegada          # si queda vacio usa res://Sonidos/publico_llegada.ogg
export var volumen_murmullo_db = -4.0          # murmullo durante la carrera
export var subida_final_db = 10.0              # cuanto sube el murmullo hasta la foto
export var metros_empieza_subida = 400.0       # desde aqui el murmullo empieza a subir suave
export var metros_empieza_bulla = 250.0        # desde aqui arranca la bulla del publico
export var segundos_hasta_pico = 9.5           # donde esta el pico dentro del archivo del grito
export var volumen_grito_inicio_db = -8.0      # la bulla entra asi...
export var volumen_grito_pico_db = 4.0         # ...y en la foto esta al maximo
export var volumen_grito_final_db = -30.0      # hasta donde baja la bulla al final
export var volumen_despues_db = -10.0          # murmullo despues del momento cumbre
export var musica_bajada_final_db = -10.0      # cuanto baja la musica mientras se acerca la meta
export var musica_bajada_climax_db = -30.0     # cuanto baja la musica en la foto
export var duracion_climax = 1.5               # segundos que la bulla se queda al maximo
export var segundos_relevo = 4.0               # segundos en que baja el publico y sube la musica
export var suavizado = 2.0                     # que tan suave cambian los volumenes antes de la meta

var _grito = null
var _jockey = null
var _foto = null
var _musica = null
var _musica_volumen = 0.0
var _grito_sonado = false
var _en_climax = false
var _t_climax = 0.0
var _pos_anterior = Vector3.ZERO
var _velocidad = 0.0

func _ready():
	if murmullo == null:
		murmullo = load("res://Sonidos/publico_murmullo.ogg")
	if grito_llegada == null:
		grito_llegada = load("res://Sonidos/publico_llegada.ogg")
	if murmullo is AudioStreamOGGVorbis or murmullo is AudioStreamMP3:
		murmullo.loop = true
	if grito_llegada is AudioStreamOGGVorbis or grito_llegada is AudioStreamMP3:
		grito_llegada.loop = false
	stream = murmullo
	volume_db = volumen_murmullo_db
	play()
	_grito = AudioStreamPlayer.new()
	_grito.stream = grito_llegada
	add_child(_grito)
	_jockey = get_parent().get_node_or_null("Jockey")
	if owner:
		_musica = owner.find_node("MusicaCarrera", true, false)
		_foto = owner.find_node("FotoFinish", true, false)
	if _musica:
		_musica_volumen = _musica.volume_db
	_pos_anterior = get_parent().global_transform.origin

func _process(delta):
	if delta <= 0.0:
		return
	var caballo = get_parent()
	var pos = caballo.global_transform.origin
	var vel = pos.distance_to(_pos_anterior) / delta
	_pos_anterior = pos
	if vel < 200.0:
		_velocidad = lerp(_velocidad, vel, min(1.0, 3.0 * delta))

	# El momento cumbre es la foto (o tu llegada, lo que pase primero).
	if not _en_climax:
		var foto_tomada = _foto != null and _foto.get("_congelada") == true
		var terminada = _jockey != null and _jockey.carrera_terminada
		if foto_tomada or terminada:
			_en_climax = true

	var paso = min(1.0, suavizado * delta)

	if not _en_climax:
		var murmullo_deseado = volumen_murmullo_db
		var musica_deseada = _musica_volumen
		var grito_deseado = volumen_grito_inicio_db
		var distancia = GestorNivel.obtener_distancia_lider_hasta_meta()
		if distancia >= 0.0:
			if distancia <= metros_empieza_subida:
				var avance = clamp((metros_empieza_subida - distancia) / max(1.0, metros_empieza_subida), 0.0, 1.0)
				murmullo_deseado = volumen_murmullo_db + subida_final_db * avance
				musica_deseada = _musica_volumen + musica_bajada_final_db * avance
			if distancia <= metros_empieza_bulla:
				var segundos_faltan = segundos_hasta_pico
				if _velocidad > 1.0:
					segundos_faltan = distancia / _velocidad
				_lanzar_grito(volumen_grito_inicio_db, max(0.0, segundos_hasta_pico - segundos_faltan))
				var k = clamp((metros_empieza_bulla - distancia) / max(1.0, metros_empieza_bulla), 0.0, 1.0)
				grito_deseado = lerp(volumen_grito_inicio_db, volumen_grito_pico_db, k)
		volume_db = lerp(volume_db, murmullo_deseado, paso)
		if _grito_sonado:
			_grito.volume_db = lerp(_grito.volume_db, grito_deseado, min(1.0, paso * 2.0))
		if _musica:
			_musica.volume_db = lerp(_musica.volume_db, musica_deseada, paso)
		return

	# ---- Momento cumbre y relevo ----
	_lanzar_grito(volumen_grito_pico_db, segundos_hasta_pico)
	_t_climax += delta
	var musica_climax = _musica_volumen + musica_bajada_climax_db
	var murmullo_climax = volumen_murmullo_db + subida_final_db

	if _t_climax < duracion_climax:
		# Bulla al maximo, musica casi apagada.
		var rapido = min(1.0, 8.0 * delta)
		volume_db = lerp(volume_db, murmullo_climax, rapido)
		_grito.volume_db = lerp(_grito.volume_db, volumen_grito_pico_db, rapido)
		if _musica:
			_musica.volume_db = lerp(_musica.volume_db, musica_climax, rapido)
	else:
		# Relevo: el publico baja y la musica sube, al mismo ritmo y sin saltos.
		var f = clamp((_t_climax - duracion_climax) / max(0.1, segundos_relevo), 0.0, 1.0)
		var s = f * f * (3.0 - 2.0 * f)
		volume_db = lerp(murmullo_climax, volumen_despues_db, s)
		_grito.volume_db = lerp(volumen_grito_pico_db, volumen_grito_final_db, s)
		if _musica:
			_musica.volume_db = lerp(musica_climax, _musica_volumen, s)

func _lanzar_grito(volumen_inicial, desde):
	if _grito_sonado:
		return
	_grito.volume_db = volumen_inicial
	_grito.play(desde)
	_grito_sonado = true
