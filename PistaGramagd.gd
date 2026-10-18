tool
extends Spatial

export var offset_interior = 0.0 setget set_offset_interior
export var offset_exterior = 120.0 setget set_offset_exterior
export var segmentos = 200
export var altura = 0.05
export var texturas_por_vuelta = 170.0 setget set_texturas_por_vuelta
export var repeticiones_ancho = 6.0 setget set_repeticiones_ancho
export(Texture) var textura setget set_textura

# --- Franjas de corte (bandas claras y oscuras de la grama recien cortada) ---
# Si Textura Franjas queda vacia, la grama sale sin franjas.
export(Texture) var textura_franjas setget set_textura_franjas
export var metros_por_franja = 7.0 setget set_metros_por_franja       # ancho de cada franja, en metros
export var intensidad_franjas = 1.0 setget set_intensidad_franjas     # 0 = sin franjas, 1 = normal, 2 = muy marcadas
export var brillo_grama = 1.35 setget set_brillo_grama                 # 1 = igual que la textura
export var franjas_a_lo_largo = true setget set_franjas_a_lo_largo     # marcado = a lo largo de la pista; sin marcar = atravesadas

const FRANJAS_POR_TEXTURA = 8.0   # la textura de franjas trae 8 franjas

const CODIGO_SHADER = """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D textura : hint_albedo;
uniform sampler2D textura_franjas : hint_albedo;
uniform float intensidad_franjas = 1.0;
uniform float brillo_grama = 1.0;
void fragment() {
	vec3 color = texture(textura, UV).rgb;
	float franja = texture(textura_franjas, UV2).r;
	ALBEDO = color * mix(1.0, franja, intensidad_franjas) * brillo_grama;
}
"""

func _ready():
	_reconstruir()

func set_offset_interior(valor):
	offset_interior = valor
	_reconstruir()

func set_offset_exterior(valor):
	offset_exterior = valor
	_reconstruir()

func set_texturas_por_vuelta(valor):
	texturas_por_vuelta = valor
	_reconstruir()

func set_repeticiones_ancho(valor):
	repeticiones_ancho = valor
	_reconstruir()

func set_textura(valor):
	textura = valor
	_reconstruir()

func set_textura_franjas(valor):
	textura_franjas = valor
	_reconstruir()

func set_metros_por_franja(valor):
	metros_por_franja = max(valor, 0.5)
	_reconstruir()

func set_intensidad_franjas(valor):
	intensidad_franjas = valor
	_reconstruir()

func set_brillo_grama(valor):
	brillo_grama = valor
	_reconstruir()

func set_franjas_a_lo_largo(valor):
	franjas_a_lo_largo = valor
	_reconstruir()

func _buscar_trackpath():
	var padre = get_parent()
	if padre == null:
		return null
	return padre.get_node_or_null("TrackPath")

func _limpiar_anterior():
	for hijo in get_children():
		if hijo.name.begins_with("Superficie"):
			remove_child(hijo)
			hijo.free()

func _reconstruir():
	var trackpath = _buscar_trackpath()
	if trackpath == null or trackpath.curve == null:
		return
	var curve = trackpath.curva_grama if trackpath.get("curva_grama") else trackpath.curve
	var largo_total = curve.get_baked_length()
	if largo_total <= 0:
		return

	_limpiar_anterior()

	# Muestreamos un par de puntos de mas al principio y al final
	# (mas alla de una vuelta completa), para que la malla se
	# superponga un poco justo donde cierra el ovalo. Asi se tapa
	# cualquier hueco que pudiera quedar en esa costura.
	var relleno = 2
	var puntos = []
	for i in range(-relleno, segmentos + relleno + 1):
		var idx = ((i % segmentos) + segmentos) % segmentos
		var dist = largo_total * float(idx) / float(segmentos)
		var punto_local = curve.interpolate_baked(dist)
		puntos.append(punto_local)
	for i in range(puntos.size()):
		puntos[i] = trackpath.to_global(puntos[i])

	var centro_oval = Vector3.ZERO
	for i in range(segmentos):
		centro_oval += trackpath.to_global(curve.interpolate_baked(largo_total * float(i) / float(segmentos)))
	centro_oval /= segmentos

	# Medidas de la textura de franjas, en metros.
	var metros_textura_franjas = metros_por_franja * FRANJAS_POR_TEXTURA
	var ancho_grama = offset_exterior - offset_interior
	# Las franjas cierran justo en la vuelta completa, sin costura en la meta.
	var franjas_por_vuelta = max(1.0, round(largo_total / metros_textura_franjas))

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	for i in range(puntos.size() - 1):
		var punto = puntos[i]
		var punto_sig = puntos[i + 1]

		var tangente = (punto_sig - punto).normalized()
		var lateral = Vector3(tangente.z, 0, -tangente.x)

		var hacia_afuera = punto - centro_oval
		hacia_afuera.y = 0
		if lateral.dot(hacia_afuera) < 0:
			lateral = -lateral

		var punto_interior = to_local(punto + lateral * offset_interior)
		var punto_exterior = to_local(punto + lateral * offset_exterior)
		punto_interior.y += altura
		punto_exterior.y += altura

		var indice_real = i - relleno
		var v_uv = float(indice_real) * texturas_por_vuelta / float(segmentos)
		var v_franjas = float(indice_real) * franjas_por_vuelta / float(segmentos)
		var a_lo_ancho = ancho_grama / metros_textura_franjas
		# La textura trae las franjas de arriba a abajo. A lo largo de la pista
		# se acuesta la textura; atravesadas se deja derecha.
		var uv2_interior = Vector2(v_franjas, 0) if franjas_a_lo_largo else Vector2(0, v_franjas)
		var uv2_exterior = Vector2(v_franjas, a_lo_ancho) if franjas_a_lo_largo else Vector2(a_lo_ancho, v_franjas)

		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(0, v_uv))
		st.add_uv2(uv2_interior)
		st.add_vertex(punto_interior)

		st.add_normal(Vector3(0, 1, 0))
		st.add_uv(Vector2(repeticiones_ancho, v_uv))
		st.add_uv2(uv2_exterior)
		st.add_vertex(punto_exterior)

	var mesh = st.commit()

	var superficie = MeshInstance.new()
	superficie.name = "Superficie"
	superficie.mesh = mesh

	if textura != null:
		var shader = Shader.new()
		shader.code = CODIGO_SHADER
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_param("textura", textura)
		if textura_franjas != null:
			mat.set_shader_param("textura_franjas", textura_franjas)
			mat.set_shader_param("intensidad_franjas", intensidad_franjas)
		else:
			mat.set_shader_param("intensidad_franjas", 0.0)
		mat.set_shader_param("brillo_grama", brillo_grama)
		superficie.material_override = mat

	add_child(superficie)
	if Engine.editor_hint and get_tree() and get_tree().edited_scene_root:
		superficie.owner = get_tree().edited_scene_root
