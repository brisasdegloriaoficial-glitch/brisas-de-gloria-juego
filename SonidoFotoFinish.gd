extends AudioStreamPlayer
# Disparo de camara con flash del photo finish.
# Va como hijo del nodo FotoFinish. Suena una sola vez,
# en el instante en que se toma la foto (el primero toca la raya).

export(AudioStream) var sonido                 # si queda vacio usa res://Sonidos/foto_flash.ogg
export var volumen_flash_db = 0.0              # volumen (0 normal, -6 mas bajo, +4 mas alto)

var _sonado = false

func _ready():
	if sonido == null:
		sonido = load("res://Sonidos/foto_flash.ogg")
	if sonido is AudioStreamOGGVorbis or sonido is AudioStreamMP3:
		sonido.loop = false
	stream = sonido

func _process(_delta):
	if _sonado:
		return
	if get_parent().get("_congelada") == true:
		volume_db = volumen_flash_db
		play()
		_sonado = true
