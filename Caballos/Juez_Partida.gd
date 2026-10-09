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

# --- NUEVO - Uniforme del juez en las carreras de ARENA ---
# Imagen del traje (saco) para la arena. Si queda vacio, usa el de siempre.
export var traje_arena = "res://Caballos/Juez_Traje_Arena.png"
# Color de los faldones del saco en la arena (codigo hex).
export var color_faldon_arena = Color("5b2a86")
# Color de la cinta del sombrero en la arena (codigo hex).
export var color_cinta_arena = Color("ffd84a")

var _ya_toco = false


func _ready():
	print("[Juez] listo")
	for m in _mallas(self):
		for i in m.get_surface_material_count():
			var mat = m.get_surface_material(i)
			if mat == null and m.mesh:
				mat = m.mesh.surface_get_material(i)
			if mat:
				mat = mat.duplicate()
				mat.flags_unshaded = sin_sombreado
				if _es_arena():
					_uniforme_arena(mat)
				m.set_surface_material(i, mat)


# NUEVO - true cuando la carrera es en la pista de arena.
func _es_arena() -> bool:
	var config = get_node_or_null("/root/ConfiguracionCarrera")
	return config != null and config.get("pista_arena") == true


# NUEVO - Cambia el traje, los faldones y la cinta del sombrero.
func _uniforme_arena(mat):
	if not (mat is SpatialMaterial):
		return
	if mat.resource_name == "Juez_Traje" and traje_arena != "" and ResourceLoader.exists(traje_arena):
		mat.albedo_texture = load(traje_arena)
	elif mat.resource_name == "Juez_Faldon":
		mat.albedo_color = color_faldon_arena
	elif mat.resource_name == "Juez_Cinta":
		mat.albedo_color = color_cinta_arena


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
