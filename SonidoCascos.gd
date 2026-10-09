extends AudioStreamPlayer
# Sonido de cascos del caballo del jugador.
# Va como hijo de Enrutador_Caballo1 (hermano del nodo Jockey).
# Ritmo parejo toda la carrera. En el tramo final sube el ritmo y el volumen
# hasta la meta. Despues de la meta el galope se va frenando y bajando poco
# a poco hasta quedar casi en reposo. Si el caballo esta quieto, se callan.

export(AudioStream) var sonido                 # si queda vacio usa res://Sonidos/cascos.ogg
export var volumen_db = 4.0                    # volumen en carrera (0 normal, -10 mas bajo, +5 mas alto)
export var volumen_extra_final = 6.0           # cuanto mas fuerte llega a la meta (se suma al de carrera)
export var volumen_final_db = -20.0            # volumen al quedar en reposo despues de la meta
export var ritmo_normal = 1.0                  # ritmo durante la carrera
export var ritmo_final = 1.4                   # ritmo maximo al llegar
export var ritmo_reposo = 0.6                  # ritmo al quedar en reposo despues de la meta (1 = normal)
export var segundos_hasta_reposo = 6.0         # cuanto tarda en frenarse despues de la meta
export var metros_empieza_aceleracion = 400.0  # desde aqui empiezan a subir el ritmo y el volumen
export var metros_ritmo_maximo = 100.0         # aqui ya llego al ritmo maximo (el volumen sigue hasta la meta)
export var suavizado = 3.0                     # que tan suave cambian ritmo y volumen durante la carrera
export var velocidad_para_silencio = 1.0       # por debajo de esto se callan (solo antes de la meta)

var _pos_anterior = Vector3.ZERO
var _velocidad = 0.0
var _jockey = null
var _t_despues_meta = -1.0
var _ritmo_en_meta = 1.0
var _volumen_en_meta = 0.0

func _ready():
	if sonido == null:
		sonido = load("res://Sonidos/cascos.ogg")
	if sonido is AudioStreamMP3 or sonido is AudioStreamOGGVorbis:
		sonido.loop = true
	stream = sonido
	volume_db = -80.0
	pitch_scale = ritmo_normal
	_pos_anterior = get_parent().global_transform.origin
	_jockey = get_parent().get_node_or_null("Jockey")

func _process(delta):
	if delta <= 0.0:
		return
	var caballo = get_parent()
	var pos = caballo.global_transform.origin
	var vel = pos.distance_to(_pos_anterior) / delta
	_pos_anterior = pos
	if vel > 200.0:
		vel = _velocidad
	var paso = min(1.0, suavizado * delta)
	_velocidad = lerp(_velocidad, vel, paso)

	var terminada = _jockey != null and _jockey.carrera_terminada

	# ---- Despues de la meta: se va frenando y bajando poco a poco ----
	if terminada:
		if _t_despues_meta < 0.0:
			_t_despues_meta = 0.0
			_ritmo_en_meta = pitch_scale
			_volumen_en_meta = volume_db
			if not playing:
				play()
		_t_despues_meta += delta
		var f = clamp(_t_despues_meta / max(0.1, segundos_hasta_reposo), 0.0, 1.0)
		var s = f * f * (3.0 - 2.0 * f)   # arranca suave y termina suave, sin saltos
		pitch_scale = max(0.1, lerp(_ritmo_en_meta, ritmo_reposo, s))
		volume_db = lerp(_volumen_en_meta, volumen_final_db, s)
		return

	# ---- Caballo quieto (antes de la largada): se callan ----
	if _velocidad < velocidad_para_silencio:
		volume_db = lerp(volume_db, -80.0, paso)
		if playing and volume_db < -60.0:
			stop()
		return

	if not playing:
		play()

	# ---- En carrera ----
	var ritmo_deseado = ritmo_normal
	var volumen_deseado = volumen_db
	var distancia = GestorNivel.obtener_distancia_lider_hasta_meta()
	if distancia >= 0.0 and distancia <= metros_empieza_aceleracion:
		var tramo = max(1.0, metros_empieza_aceleracion - metros_ritmo_maximo)
		var avance = clamp((metros_empieza_aceleracion - distancia) / tramo, 0.0, 1.0)
		ritmo_deseado = lerp(ritmo_normal, ritmo_final, avance)
		# El volumen sigue subiendo hasta la misma raya.
		var avance_volumen = clamp((metros_empieza_aceleracion - distancia) / max(1.0, metros_empieza_aceleracion), 0.0, 1.0)
		volumen_deseado = volumen_db + volumen_extra_final * avance_volumen

	pitch_scale = max(0.1, lerp(pitch_scale, ritmo_deseado, paso))
	volume_db = lerp(volume_db, volumen_deseado, paso)
