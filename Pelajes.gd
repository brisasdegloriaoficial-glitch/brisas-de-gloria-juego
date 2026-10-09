extends Spatial
# Pelajes.gd  —  Godot 3.5.3  —  Brisas de Gloria
# Va en un nodo Spatial llamado Pelajes, hijo del nodo raiz de PistaDeCarrera.
# Al empezar cada carrera reparte los pelajes de los rivales AL AZAR, pero
# con tope de claros (blancos y grises, contando al jugador) y todo el resto
# oscuros (castanos, zainos, alazanes, negros), que resaltan mas en el
# hipodromo. Cada uno con su propio tono. El caballo del jugador lleva el pelaje que
# escojas aqui.
# El pelo sale de la textura de TextureCan (Caballos/Pelaje), puesta encima de
# la textura original del caballo, asi no se pierden ojos, cascos ni musculos.

export var activo := true
export(int, "Castaño", "Zaino", "Alazán", "Alazán tostado", "Negro", "Tordo", "Tordo oscuro", "Blanco", "Negro azabache", "Castaño oscuro", "Zaino colorado") var pelaje_jugador := 7
export var ruta_pelo := "res://Caballos/Pelaje/fabrics_0037_ao_1k.jpg"
export var ruta_normal := "res://Caballos/Pelaje/fabrics_0037_normal_opengl_1k.png"
export var escala_pelo := 3.0        # mas alto = pelo mas fino
# Pelo hecho por el juego (sin rayitas): reemplaza la foto de tela por un
# grano parejo generado aqui mismo. Apagalo para volver a la foto.
export var pelo_generado := false
export var grano_pelo := 2.0         # tamano del grano del pelo (mas alto = mas grueso)
export var detalle_pelo := 3         # capas de detalle del grano (1 a 6)
export var relieve_pelo := 6.0       # fuerza del relieve generado
export var fuerza_pelo := 0.6        # cuanto se nota el pelo (0 = nada)
export var fuerza_relieve := 0.5     # relieve del pelo con la luz
export var fuerza_original := 1.0    # cuanto se nota la textura original (musculos, ojos)
export var brillo := 1.0             # aclara u oscurece todos los pelajes
export var variar_tono := 0.12       # cuanto cambia el tono de un caballo a otro
export var aspereza := 0.7
export var nombre_jugador := "Enrutador_Caballo1"
export var mostrar_diagnostico := true
# Tope de caballos claros (blancos y grises) en toda la carrera, contando
# al tuyo si es claro. Cada carrera sale al azar un numero entre 0 y este
# tope. Todos los demas salen oscuros.
export var maximo_claros := 4
# Tope de rivales blancos (el resto de los claros salen grises).
export var maximo_blancos := 1
# Cuantos Cuarto de Milla salen con su alazan original (sin pintar) en cada carrera.
export var cuartomilla_originales := 2

const NOMBRES = ["castaño", "zaino", "alazán", "alazán tostado", "negro", "tordo", "tordo oscuro", "blanco", "negro azabache", "castaño oscuro", "zaino colorado"]
const COLORES = ["8a4b2a", "4a2a18", "b5652d", "7a3a1a", "2e2a26", "b4b4b4", "8a8a8a", "ffffff", "141414", "5c3320", "6b2f1c"]
# Pelajes de los rivales (por numero de la lista de arriba).
# Los crema (palomino y bayo) se eliminaron del todo.
const OSCUROS = [0, 1, 2, 3, 4, 8, 9, 10]
const GRISES = [6, 5]
const BLANCOS = [7]
const SHADER = """
shader_type spatial;
uniform sampler2D textura_original : hint_albedo;
uniform sampler2D pelo : hint_white;
uniform sampler2D pelo_normal : hint_normal;
uniform vec4 color_pelaje : hint_color;
uniform float media_original = 0.55;
uniform float fuerza_original = 1.0;
uniform float media_pelo = 0.75;
uniform float fuerza_pelo = 0.6;
uniform float escala_pelo = 3.0;
uniform float fuerza_relieve = 0.5;
uniform float brillo = 1.0;
uniform float aspereza = 0.7;
varying vec3 p_obj;
varying vec3 n_obj;

void vertex() {
	p_obj = VERTEX;
	n_obj = NORMAL;
}

vec3 tres_lados(sampler2D t, vec3 p, vec3 w) {
	return texture(t, p.zy).rgb * w.x + texture(t, p.xz).rgb * w.y + texture(t, p.xy).rgb * w.z;
}

void fragment() {
	vec3 w = pow(abs(normalize(n_obj)), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec3 p = p_obj * escala_pelo;
	float lp = dot(tres_lados(pelo, p, w), vec3(0.3333)) / media_pelo;
	vec3 base = texture(textura_original, UV).rgb;
	float lb = dot(base, vec3(0.299, 0.587, 0.114)) / media_original;
	vec3 c = color_pelaje.rgb * brillo * mix(1.0, lb, fuerza_original) * mix(1.0, lp, fuerza_pelo);
	ALBEDO = clamp(c, 0.0, 1.0);
	NORMALMAP = tres_lados(pelo_normal, p, w);
	NORMALMAP_DEPTH = fuerza_relieve;
	ROUGHNESS = aspereza;
}
"""

var _shader = null
var _pelo = null
var _normal = null
var _media_pelo := 0.75
var _medias := {}


func _ready():
	if not activo:
		return
	randomize()
	# Espera a que el RepartidorCaballos ponga los caballos nuevos.
	get_tree().create_timer(0.3).connect("timeout", self, "_pintar_todos")


func _pintar_todos():
	var raiz = get_tree().current_scene
	if raiz == null:
		return
	_shader = Shader.new()
	_shader.code = SHADER
	if pelo_generado:
		_crear_pelo_generado()
	elif ResourceLoader.exists(ruta_pelo):
		_pelo = load(ruta_pelo)
		var m = _media(_pelo, false)
		if m > 0.0:
			_media_pelo = m
	elif mostrar_diagnostico:
		print("[BDG-Pelajes] AVISO: no encontre ", ruta_pelo)
	if not pelo_generado and ResourceLoader.exists(ruta_normal):
		_normal = load(ruta_normal)
	var lista = _enrutadores(raiz)
	var mazo = _armar_mazo(lista.size() - 1)
	var originales = 0
	for e in lista:
		if e.name != nombre_jugador and originales < cuartomilla_originales and _es_cuartomilla(e):
			originales += 1
			if mostrar_diagnostico:
				print("[BDG-Pelajes] ", e.name, ": Cuarto de Milla con su pelaje original")
			continue
		var cual = pelaje_jugador
		if e.name != nombre_jugador:
			cual = mazo.pop_back() if mazo.size() > 0 else OSCUROS[randi() % OSCUROS.size()]
		var color = Color(COLORES[cual])
		if e.name != nombre_jugador:
			color = _variar(color, cual)
		var n = _pintar(e, color)
		if mostrar_diagnostico:
			print("[BDG-Pelajes] ", e.name, ": ", NOMBRES[cual], " #", color.to_html(false), " (", n, " piezas)")


# Grano de pelo parejo, sin direccion, que se repite sin costuras.
func _crear_pelo_generado():
	var ruido = OpenSimplexNoise.new()
	ruido.seed = 7
	ruido.period = max(grano_pelo, 0.5)
	ruido.octaves = int(clamp(detalle_pelo, 1, 6))
	ruido.persistence = 0.55
	var t = NoiseTexture.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = ruido
	_pelo = t
	_media_pelo = 0.5
	var tn = NoiseTexture.new()
	tn.width = 256
	tn.height = 256
	tn.seamless = true
	tn.as_normalmap = true
	tn.bump_strength = relieve_pelo
	tn.noise = ruido
	_normal = tn


func _enrutadores(n) -> Array:
	var r = []
	for c in n.get_children():
		if c is PathFollow and c.name.begins_with("Enrutador_Caballo"):
			r.append(c)
		else:
			r += _enrutadores(c)
	return r


# Arma los pelajes de los rivales al azar: sortea cuantos claros salen
# (sin pasar el tope), y si cada claro es blanco o gris; el resto salen
# oscuros sin repetir hasta agotar la lista. Al final se baraja.
func _armar_mazo(cuantos) -> Array:
	var mazo = []
	var cupo = maximo_claros
	if pelaje_jugador in BLANCOS or pelaje_jugador in GRISES:
		cupo -= 1
	cupo = int(clamp(cupo, 0, cuantos))
	var claros = randi() % (cupo + 1)
	var blancos = 0
	for i in range(claros):
		if blancos < maximo_blancos and randf() < 0.35:
			mazo.append(BLANCOS[randi() % BLANCOS.size()])
			blancos += 1
		else:
			mazo.append(GRISES[randi() % GRISES.size()])
	var oscuros = OSCUROS.duplicate()
	oscuros.shuffle()
	var k = 0
	while mazo.size() < cuantos:
		mazo.append(oscuros[k % oscuros.size()])
		k += 1
		if k % oscuros.size() == 0:
			oscuros.shuffle()
	while mazo.size() > cuantos:
		mazo.pop_front()
	mazo.shuffle()
	return mazo


# Cada caballo con su propio tono
func _variar(c : Color, cual) -> Color:
	var v = clamp(c.v * rand_range(1.0 - variar_tono, 1.0 + variar_tono), 0.0, 1.0)
	var s = c.s
	var h = c.h
	if s > 0.05:
		s = clamp(s * rand_range(1.0 - variar_tono, 1.0 + variar_tono), 0.0, 1.0)
		h = fposmod(h + rand_range(-0.02, 0.02), 1.0)
	return Color.from_hsv(h, s, v)


func _pintar(enrutador, color) -> int:
	var cuantas = 0
	for modelo in enrutador.get_children():
		if not (modelo is Spatial) or not modelo.visible or not modelo.name.begins_with("Caballo"):
			continue
		var esq = _esqueleto(modelo)
		if esq == null:
			continue
		for mi in _mallas_cuerpo(esq):
			cuantas += _vestir_malla(mi, color)
	return cuantas


func _es_cuartomilla(enrutador) -> bool:
	for modelo in enrutador.get_children():
		if modelo is Spatial and modelo.visible and modelo.name.begins_with("Caballo_CuartoMilla"):
			return true
	return false


# Mallas del cuerpo: debajo del esqueleto del caballo, sin entrar a los
# BoneAttachment (ahi van silla, jinete, brida y guardrapa).
func _mallas_cuerpo(n) -> Array:
	var r = []
	for c in n.get_children():
		if c is BoneAttachment:
			continue
		if c is MeshInstance and c.mesh != null:
			r.append(c)
		r += _mallas_cuerpo(c)
	return r


func _vestir_malla(mi, color) -> int:
	var cuantas = 0
	if mi.material_override is SpatialMaterial:
		mi.material_override = _material(mi.material_override.albedo_texture, color)
		return 1
	for i in mi.mesh.get_surface_count():
		var base = mi.get_active_material(i)
		if base is SpatialMaterial:
			mi.set_surface_material(i, _material(base.albedo_texture, color))
			cuantas += 1
	return cuantas


func _material(textura, color):
	var m = ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_param("textura_original", textura)
	m.set_shader_param("pelo", _pelo)
	m.set_shader_param("pelo_normal", _normal)
	m.set_shader_param("color_pelaje", color)
	m.set_shader_param("media_pelo", _media_pelo)
	m.set_shader_param("media_original", _media_textura(textura))
	m.set_shader_param("fuerza_original", fuerza_original if textura != null else 0.0)
	m.set_shader_param("fuerza_pelo", fuerza_pelo if _pelo != null else 0.0)
	m.set_shader_param("escala_pelo", escala_pelo)
	m.set_shader_param("fuerza_relieve", fuerza_relieve if _normal != null else 0.0)
	m.set_shader_param("brillo", brillo)
	m.set_shader_param("aspereza", aspereza)
	return m


# Brillo promedio de la textura original de cada raza, para que el pelaje
# salga del mismo tono en arabes y americanos.
func _media_textura(t) -> float:
	if t == null:
		return 0.55
	if _medias.has(t):
		return _medias[t]
	var m = _media(t, true)
	if m <= 0.0:
		m = 0.55
	_medias[t] = m
	return m


func _media(t, lineal) -> float:
	var img = t.get_data()
	if img == null:
		return -1.0
	if img.is_compressed() and img.decompress() != OK:
		return -1.0
	img.resize(16, 16)
	img.lock()
	var suma = 0.0
	for y in 16:
		for x in 16:
			var c = img.get_pixel(x, y)
			suma += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	img.unlock()
	var m = suma / 256.0
	if lineal:
		m = pow(m, 2.2)
	return m


func _esqueleto(n):
	var cola = [n]
	while cola.size() > 0:
		var x = cola.pop_front()
		if x is Skeleton:
			return x
		for h in x.get_children():
			cola.append(h)
	return null
