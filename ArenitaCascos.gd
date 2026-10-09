extends Spatial
# ArenitaCascos: granitos de arena que levantan los cascos en las
# carreras de ARENA. Va como hijo directo de PistaDeCarrera.
# Liviano: pocos granitos, y solo se encienden en los caballos que
# estan cerca de la camara que se esta viendo. En la grama no hace nada.
# Altura Suelo tiene que ser igual a la Translation Y de MeshInstance.

export var cantidad = 18                 # particulas por caballo (menos = mas liviano)
export var duracion = 0.45                # segundos que dura cada granito en el aire
export var tamano = 0.25                  # tamano de cada granito de arena
export var color_arena = Color("9c5f22") # color de la arenita (codigo hex)
export var fuerza = 5.0                  # que tan alto/lejos salta
export var distancia_camara = 120.0      # solo caballos a menos de esta distancia de la camara
export var atras_del_caballo = 1.5       # cuanto detras del caballo nace la arenita
export var altura_suelo = 1.1            # altura del piso de arena (Translation Y de MeshInstance)
export var velocidad_minima = 3.0        # si el caballo va mas lento que esto, no levanta arena

var _emisores = {}
var _pos_previa = {}

func _ready():
	var config = get_node_or_null("/root/ConfiguracionCarrera")
	if config == null or config.get("pista_arena") != true:
		set_process(false)
		return
	var camino = get_parent().get_node_or_null("TrackPath")
	if camino == null:
		set_process(false)
		return
	for e in camino.get_children():
		if e is PathFollow and e.name.begins_with("Enrutador_Caballo"):
			_emisores[e] = _crear_emisor()
			_pos_previa[e] = e.global_transform.origin

func _crear_emisor():
	var p = CPUParticles.new()
	p.local_coords = false
	p.emitting = false
	p.amount = cantidad
	p.lifetime = duracion
	p.explosiveness = 0.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 25.0
	p.gravity = Vector3(0, -30, 0)
	p.initial_velocity = fuerza
	p.initial_velocity_random = 0.5
	p.scale_amount = tamano
	p.scale_amount_random = 0.5
	p.emission_shape = CPUParticles.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.2, 0.05, 0.8)
	var malla = QuadMesh.new()
	malla.size = Vector2(1, 1)
	var mat = SpatialMaterial.new()
	mat.albedo_texture = _textura_redonda()
	mat.flags_unshaded = true
	mat.flags_transparent = true
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.params_billboard_mode = SpatialMaterial.BILLBOARD_PARTICLES
	malla.material = mat
	p.mesh = malla
	var crecer = Curve.new()
	crecer.add_point(Vector2(0, 1.0))
	crecer.add_point(Vector2(1, 0.6))
	p.scale_amount_curve = crecer
	var degradado = Gradient.new()
	degradado.set_color(0, Color(color_arena.r, color_arena.g, color_arena.b, 1.0))
	degradado.set_color(1, Color(color_arena.r, color_arena.g, color_arena.b, 0.0))
	p.color_ramp = degradado
	add_child(p)
	return p

# Un circulito difuminado (asi la arena no se ve cuadrada). Se arma una
# sola vez y lo comparten todos los caballos.
var _textura = null
func _textura_redonda():
	if _textura:
		return _textura
	var lado = 32
	var img = Image.new()
	img.create(lado, lado, false, Image.FORMAT_RGBA8)
	img.lock()
	for y in range(lado):
		for x in range(lado):
			var d = Vector2(x - lado / 2.0 + 0.5, y - lado / 2.0 + 0.5).length() / (lado / 2.0)
			var a = clamp((1.0 - d) * 3.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	img.unlock()
	_textura = ImageTexture.new()
	_textura.create_from_image(img)
	return _textura

func _process(delta):
	if delta <= 0.0:
		return
	var cam = get_viewport().get_camera()
	for e in _emisores.keys():
		if not is_instance_valid(e):
			continue
		var p = _emisores[e]
		var pos = e.global_transform.origin
		var mov = pos - _pos_previa[e]
		_pos_previa[e] = pos
		mov.y = 0
		var vel = mov.length() / delta
		var cerca = cam != null and cam.global_transform.origin.distance_to(pos) < distancia_camara
		var encender = cerca and vel > velocidad_minima and vel < 400.0
		if encender:
			var atras = -mov.normalized() * atras_del_caballo
			var centro = _centro_caballo(e)
			p.global_transform.origin = Vector3(centro.x + atras.x, altura_suelo + 0.1, centro.z + atras.z)
		p.emitting = encender

func _centro_caballo(e):
	for h in e.get_children():
		if h is Spatial and h.name.begins_with("Caballo") and h.visible:
			return h.global_transform.origin
	return e.global_transform.origin
