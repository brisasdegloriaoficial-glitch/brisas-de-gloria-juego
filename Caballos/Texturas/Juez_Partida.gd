extends Spatial

# Juez_Partida.gd — El juez estira la mano (toca el timbre)
# justo cuando la cuenta regresiva llega al final y abre la gatera.

# Cuantos segundos antes de la largada empieza a estirar la mano
# (la mano llega al frente unos 0.7 segundos despues de empezar).
export var segundos_antes_de_largar = 0.7
# 1 = velocidad normal. Ponlo en 0.3 para verlo en camara lenta.
export var velocidad_animacion = 1.0
# Encendido = colores exactos, sin el tinte celeste del cielo.
export var sin_sombreado = true
# NUEVO - Textura del traje del juez, liviana y comprimida para el telefono.
# La que venia guardada dentro del modelo salia negra en Android.
# Si la dejas vacia, el juez usa la de adentro como antes.
export(String, FILE, "*.jpg, *.png") var textura_juez = "res://Caballos/Texturas/Juez_color.jpg"

var _ya_toco = false


func _ready():
	print("[Juez] listo")
	var nueva = null
	if textura_juez != "" and ResourceLoader.exists(textura_juez):
		nueva = load(textura_juez)
	elif textura_juez != "":
		print("[Juez] AVISO: no encontre la textura ", textura_juez)
	for m in _mallas(self):
		for i in m.get_surface_material_count():
			var mat = m.get_surface_material(i)
			if mat == null and m.mesh:
				mat = m.mesh.surface_get_material(i)
			if mat:
				mat = mat.duplicate()
				mat.flags_unshaded = sin_sombreado
				# NUEVO - cambia la textura de adentro por la liviana.
				if nueva != null and mat is SpatialMaterial and mat.albedo_texture is ImageTexture:
					mat.albedo_texture = nueva
				m.set_surface_material(i, mat)


func _process(_delta):
	var gate = get_node_or_null("../../Gate")
	if gate == null:
		return
	# El juez y su podio se esconden junto con el aparato de partida
	# (Distancia Para Ocultar del nodo Gate).
	get_parent().visible = gate.visible
	if gate._largaron:
		return
	if gate._conteo_restante > segundos_antes_de_largar:
		_ya_toco = false
		return
	if not _ya_toco and gate._conteo_restante > 0.0:
		var anim = get_node_or_null("AnimationPlayer")
		if anim:
			anim.playback_speed = velocidad_animacion
			anim.play("TocarTimbre")
			print("[Juez] toca el timbre")
		_ya_toco = true


func _mallas(n):
	var r = []
	for c in n.get_children():
		if c is MeshInstance:
			r.append(c)
		r += _mallas(c)
	return r
